import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para kReleaseMode e kDebugMode
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:agenda/core/services/firestore_service.dart';
import 'package:agenda/core/utils/custom_theme_data.dart';
import 'package:agenda/core/widgets/animated_background.dart';
import 'package:agenda/core/widgets/background_sound_manager.dart';
import 'package:agenda/core/utils/app_styles.dart';
import 'package:agenda/core/utils/app_strings.dart';
import 'package:agenda/core/utils/app_check_debug_token.dart';
import 'package:agenda/view/app_initialization_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:agenda/config/firebase_options.dart';
import 'package:agenda/view/config_error_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:agenda/view/manutencao_view.dart';
import 'package:agenda/app_localizations.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Manipular mensagens em segundo plano
  debugPrint(AppStrings.backgroundMessageHandling(message.messageId));
}

String _normalizeAppCheckDebugToken(String? raw) {
  final token = (raw ?? '').trim();
  if (token.isEmpty) return '';

  final lower = token.toLowerCase();
  final placeholderTokens = <String>{
    'seu_token',
    '<seu_token>',
    'your_token',
    '<your_token>',
    'seu_token_debug_app_check_aqui',
    'your_app_check_debug_token_here',
  };

  return placeholderTokens.contains(lower) ? '' : token;
}

List<String> _requiredFirebaseEnvKeysForCurrentPlatform() {
  final keys = <String>[
    'FIREBASE_PROJECT_ID',
    'FIREBASE_MESSAGING_SENDER_ID',
    'FIREBASE_STORAGE_BUCKET',
  ];

  if (kIsWeb) {
    return [...keys, 'FIREBASE_WEB_API_KEY', 'FIREBASE_WEB_APP_ID'];
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return [...keys, 'FIREBASE_ANDROID_API_KEY', 'FIREBASE_ANDROID_APP_ID'];
    case TargetPlatform.iOS:
      return [...keys, 'FIREBASE_IOS_API_KEY', 'FIREBASE_IOS_APP_ID'];
    default:
      return keys;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('language_code');
    final String? countryCode = prefs.getString('country_code');
    final String? themeMode = prefs.getString('theme_mode');
    final String? customTheme = prefs.getString('custom_theme_type');
    final bool onboardingComplete =
        prefs.getBool('onboarding_complete') ?? false;
    final Locale? initialLocale = languageCode != null
        ? Locale(languageCode, countryCode)
        : null;

    if (initialLocale != null) {
      AppStrings.setLocale(initialLocale);
    }

    // 1. Configuração de Ambiente (.env)
    // Uso: flutter run --dart-define=ENV=prod (Padrão: dev)
    const String env = String.fromEnvironment('ENV', defaultValue: 'dev');
    // Permite testar a tela de erro mesmo em debug via --dart-define=FORCE_CONFIG_CHECK=true
    const bool forceConfigCheck = bool.fromEnvironment(
      'FORCE_CONFIG_CHECK',
      defaultValue: false,
    );
    final String envFile = env == 'dev' ? '.env' : '.env.$env';

    try {
      // Carrega base e depois (opcionalmente) sobrepõe com ambiente específico.
      // Em ENV=dev, evita tentar carregar ".env.dev" quando ele não existe no Web.
      await dotenv.load(fileName: '.env', isOptional: true);

      if (envFile != '.env') {
        final baseEnv = Map<String, String>.from(dotenv.env);
        await dotenv.load(
          fileName: envFile,
          isOptional: true,
          mergeWith: baseEnv,
        );
      }

      // Verificacao das chaves obrigatorias do cliente atual.
      final requiredKeys = <String>[
        'DB_ADMIN_PASSWORD',
        'ADMIN_EMAIL',
        ..._requiredFirebaseEnvKeysForCurrentPlatform(),
      ];
      final missingKeys = requiredKeys
          .where((key) => dotenv.env[key] == null || dotenv.env[key]!.isEmpty)
          .toSet()
          .toList();

      if (missingKeys.isNotEmpty) {
        debugPrint(AppStrings.configAlertMissingKeys(missingKeys.join(', ')));

        // Em Release, bloqueia o app se faltar configuração crítica
        if (kReleaseMode || forceConfigCheck) {
          runApp(
            ConfigErrorView(
              message: AppStrings.appInitConfigSegurancaAusente,
              details: AppStrings.appInitDetalhesChavesAusentes(
                env,
                missingKeys.join(', '),
              ),
            ),
          );
          return;
        }
      }
    } catch (e) {
      if (kReleaseMode || forceConfigCheck) {
        runApp(
          ConfigErrorView(
            message: AppStrings.appInitArquivoConfigNaoEncontrado,
            details: AppStrings.appInitDetalhesArquivoEsperado(
              envFile,
              e.toString(),
            ),
          ),
        );
        return;
      }
      debugPrint(AppStrings.envFileLoadWarning(e.toString()));
    }

    String appCheckDebugToken = _normalizeAppCheckDebugToken(
      const String.fromEnvironment(
        'FIREBASE_APPCHECK_DEBUG_TOKEN',
        defaultValue: '',
      ),
    );

    if (appCheckDebugToken.isEmpty) {
      appCheckDebugToken = _normalizeAppCheckDebugToken(
        dotenv.env['FIREBASE_APPCHECK_DEBUG_TOKEN'],
      );
    }
    if (appCheckDebugToken.isEmpty) {
      appCheckDebugToken = _normalizeAppCheckDebugToken(
        dotenv.env['web_dev_app'],
      );
    }
    if (appCheckDebugToken.isEmpty) {
      appCheckDebugToken = _normalizeAppCheckDebugToken(
        dotenv.env['web_warranty_app'],
      );
    }

    await configureWebAppCheckDebugToken(
      appCheckDebugToken.isEmpty ? null : appCheckDebugToken,
    );

    // 2. Inicialização do Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // --- CONFIGURACAO DE AMBIENTE FIREBASE ---
    // Por padrao, usa Firebase online (projeto gratuito).
    // Para usar emuladores locais, rode com: --dart-define=USE_FIREBASE_EMULATORS=true
    const bool useFirebaseEmulators = bool.fromEnvironment(
      'USE_FIREBASE_EMULATORS',
      defaultValue: false,
    );
    if (kDebugMode && useFirebaseEmulators) {
      try {
        // '10.0.2.2' é o IP especial para o emulador Android acessar o host.
        // Para iOS ou Web, usa-se 'localhost'.
        final String host = defaultTargetPlatform == TargetPlatform.android
            ? '10.0.2.2'
            : 'localhost';

        // Conecta Auth (Porta 9099)
        await FirebaseAuth.instance.useAuthEmulator(host, 9099);
        // Conecta Firestore (Porta 8080)
        FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
        // Conecta Storage (Porta 9199)
        await FirebaseStorage.instance.useStorageEmulator(host, 9199);
        // Conecta Functions (Porta 5001)
        FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);

        debugPrint(AppStrings.firebaseEmulatorConnected(host));
      } catch (e) {
        debugPrint(AppStrings.firebaseEmulatorConnectionError(e.toString()));
      }
    } else {
      debugPrint(AppStrings.firebaseUsingOnline);
    }

    // 3. App Check para Web
    const bool enableAppCheckInDebug = bool.fromEnvironment(
      'ENABLE_APPCHECK_IN_DEBUG',
      defaultValue: false,
    );
    final recaptchaKey = dotenv.env['RECAPTCHA_SITE_KEY'];
    final bool hasDebugAppCheckToken = appCheckDebugToken.isNotEmpty;
    final bool shouldEnableWebAppCheck =
        kIsWeb &&
        (kReleaseMode ||
            enableAppCheckInDebug ||
            (kDebugMode && hasDebugAppCheckToken));
    if (shouldEnableWebAppCheck &&
        recaptchaKey != null &&
        recaptchaKey.isNotEmpty) {
      try {
        await FirebaseAppCheck.instance.activate(
          providerWeb: ReCaptchaV3Provider(recaptchaKey),
        );
      } catch (e) {
        debugPrint(AppStrings.appCheckActivationFailure(e.toString()));
      }
    } else if (kIsWeb && kDebugMode && !enableAppCheckInDebug) {
      debugPrint(AppStrings.appCheckDisabledInDebug);
    } else if (kIsWeb) {
      debugPrint(AppStrings.appCheckRecaptchaMissing);
    }

    // 4. Configurações adicionais
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    runApp(
      DevicePreview(
        enabled: !kReleaseMode, // Ativa o DevicePreview em modo debug
        builder: (context) => MyApp(
          initialLocale: initialLocale,
          initialThemeMode: themeMode,
          initialCustomTheme: customTheme,
          onboardingComplete: onboardingComplete,
        ),
      ),
    );
  } catch (e) {
    // Se der erro fatal, mostra na tela em vez de ficar branco
    debugPrint(AppStrings.appInitFatalLog(e.toString()));
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                AppStrings.appInitErroFatal(e.toString()),
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final Locale? initialLocale;
  final String? initialThemeMode;
  final String? initialCustomTheme;
  final bool onboardingComplete;

  const MyApp({
    super.key,
    this.initialLocale,
    this.initialThemeMode,
    this.initialCustomTheme,
    required this.onboardingComplete,
  });

  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  static void setCustomTheme(BuildContext context, AppThemeType type) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setCustomTheme(type);
  }
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;
  AppThemeType _customThemeType = AppThemeType.sistema;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    if (_locale != null) {
      AppStrings.setLocale(_locale!);
    }
    if (widget.initialThemeMode != null) {
      _themeMode = _getThemeModeFromString(widget.initialThemeMode!);
    }
    if (widget.initialCustomTheme != null) {
      _customThemeType = AppThemeType.values.firstWhere(
        (e) => e.toString() == widget.initialCustomTheme,
        orElse: () => AppThemeType.sistema,
      );
    }
    _setupNotifications();
  }

  ThemeMode _getThemeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _getStringFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  void setLocale(Locale locale) async {
    setState(() {
      _locale = locale;
    });
    AppStrings.setLocale(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    if (locale.countryCode != null) {
      await prefs.setString('country_code', locale.countryCode!);
    }
    _atualizarPreferenciasUsuario(
      locale: '${locale.languageCode}_${locale.countryCode ?? ""}',
    );
  }

  void setCustomTheme(AppThemeType type) async {
    setState(() {
      _customThemeType = type;
      // Mapeia o tipo customizado para o ThemeMode do Flutter
      if (type == AppThemeType.claro) {
        _themeMode = ThemeMode.light;
      } else if (type == AppThemeType.escuro) {
        _themeMode = ThemeMode.dark;
      } else if (type == AppThemeType.sistema) {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.light;
      } // Temas coloridos usam base clara por padrão
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_theme_type', type.toString());
    await prefs.setString('theme_mode', _getStringFromThemeMode(_themeMode));

    _atualizarPreferenciasUsuario(theme: type.toString());
  }

  Future<void> _atualizarPreferenciasUsuario({
    String? theme,
    String? locale,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // O método atualizarPreferenciasUsuario não existe, mas o de tema sim.
      // Vamos chamar o que existe para não quebrar.
      if (theme != null) {
        await FirestoreService().atualizarTemaUsuario(user.uid, theme);
      }
    }
  }

  void _setupNotifications() async {
    const bool enableWebPushInDebug = bool.fromEnvironment(
      'ENABLE_WEB_PUSH_IN_DEBUG',
      defaultValue: false,
    );

    if (kIsWeb && kDebugMode && !enableWebPushInDebug) {
      debugPrint(AppStrings.webPushDisabledInDebug);
      return;
    }

    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Listener para mensagens em Primeiro Plano (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          AppStrings.foregroundNotificationReceived(
            message.notification?.title,
          ),
        );

        if (message.notification != null) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.foregroundNotificationContent(
                  message.notification!.title ?? '',
                  message.notification!.body ?? '',
                ),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.teal,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });

      String? token;
      if (kIsWeb) {
        final vapidKey = dotenv.env['VAPID_KEY'];
        if (vapidKey == null || vapidKey.isEmpty) {
          debugPrint(AppStrings.vapidKeyMissing);
        } else {
          token = await messaging.getToken(vapidKey: vapidKey);
        }
      } else {
        token = await messaging.getToken();
      }

      if (token != null) {
        _salvarTokenNoBanco(token);
      }

      messaging.onTokenRefresh.listen(
        _salvarTokenNoBanco,
        onError: (Object e) =>
            debugPrint(AppStrings.fcmTokenRefreshError(e.toString())),
      );
    } catch (e) {
      debugPrint(AppStrings.pushNotificationsInitFailure(e.toString()));
    }
  }

  void _salvarTokenNoBanco(String token) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirestoreService().atualizarToken(user.uid, token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Locale? effectiveLocale = _locale ?? DevicePreview.locale(context);
    if (effectiveLocale != null) {
      AppStrings.setLocale(effectiveLocale);
    }

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          scaffoldMessengerKey:
              _scaffoldMessengerKey, // Chave para exibir SnackBars globais
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          debugShowCheckedModeBanner:
              false, // Havia sido retirado, mas é importante para o DevicePreview
          theme: ThemeData(
            colorScheme: lightDynamic ?? AppColors.lightScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic ?? AppColors.darkScheme,
            useMaterial3: true,
          ),
          themeAnimationDuration: const Duration(
            milliseconds: 800,
          ), // Transição suave (Fade)
          themeAnimationCurve: Curves.easeInOut,
          themeMode: _themeMode,
          locale: effectiveLocale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('en', 'US'),
            Locale('es', 'ES'),
            Locale('fr', 'FR'),
            Locale('ja', 'JP'),
          ],
          home: AppInitializationView(
            onboardingComplete: widget.onboardingComplete,
          ),
          // Builder global: Envolve todo o app no fundo animado e verifica manutenção
          builder: (context, child) {
            final childWithPreview = DevicePreview.appBuilder(context, child);
            // StreamBuilder para verificar manutenção em tempo real
            return StreamBuilder<bool>(
              stream: FirestoreService().getManutencaoStream(),
              builder: (context, snapshot) {
                final emManutencao = snapshot.data ?? false;

                if (emManutencao) {
                  return const MaterialApp(
                    home: ManutencaoView(),
                    debugShowCheckedModeBanner: false,
                  );
                }

                return BackgroundSoundManager(
                  themeType: _customThemeType,
                  child: AnimatedBackground(
                    themeType: _customThemeType,
                    // Garante que o fundo do Scaffold seja transparente para ver a animação
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        scaffoldBackgroundColor:
                            _customThemeType != AppThemeType.sistema &&
                                _customThemeType != AppThemeType.claro &&
                                _customThemeType != AppThemeType.escuro
                            ? Colors.transparent
                            : null,
                      ),
                      child: childWithPreview,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
