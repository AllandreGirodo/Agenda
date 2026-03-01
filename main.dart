import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para kReleaseMode
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:agenda/controller/firestore_service.dart';
import 'package:agenda/custom_theme_data.dart';
import 'package:agenda/widgets/animated_background.dart';
import 'package:agenda/widgets/background_sound_manager.dart';
import 'package:agenda/view/app_styles.dart';
import 'package:agenda/view/login_view.dart';
import 'package:agenda/view/onboarding_view.dart';
import 'package:agenda/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:agenda/firebase_options.dart'; // Será gerado pelo flutterfire configure
import 'package:agenda/view/config_error_view.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Manipular mensagens em segundo plano
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 1. Configuração de Ambiente (.env)
    // Uso: flutter run --dart-define=ENV=prod (Padrão: dev)
    const String env = String.fromEnvironment('ENV', defaultValue: 'dev');
    // Permite testar a tela de erro mesmo em debug via --dart-define=FORCE_CONFIG_CHECK=true
    const bool forceConfigCheck = bool.fromEnvironment('FORCE_CONFIG_CHECK', defaultValue: false);
    final String envFile = ".env.$env";

    try {
      await dotenv.load(fileName: envFile);

      // Verificação de chaves críticas
      final missingKeys = [
        'DB_ADMIN_PASSWORD',
        'ADMIN_EMAIL',
        'FCM_SERVER_KEY'
      ].where((key) => dotenv.env[key] == null || dotenv.env[key]!.isEmpty).toList();

      if (missingKeys.isNotEmpty) {
        debugPrint("\n⚠️  [ALERTA DE CONFIGURAÇÃO] As seguintes chaves críticas não foram encontradas no .env: ${missingKeys.join(', ')}");
        
        // Em Release, bloqueia o app se faltar configuração crítica
        if (kReleaseMode || forceConfigCheck) {
          runApp(ConfigErrorView(
            message: "O aplicativo não pode ser iniciado devido a configurações de segurança ausentes.",
            details: "Ambiente: $env\nChaves ausentes: ${missingKeys.join(', ')}",
          ));
          return;
        }
      }
    } catch (e) {
      if (kReleaseMode || forceConfigCheck) {
        runApp(ConfigErrorView(message: "Arquivo de configuração não encontrado.", details: "Arquivo esperado: $envFile\nErro: $e"));
        return;
      }
      debugPrint("Aviso: Arquivo .env não encontrado ou erro ao carregar: $e");
    }

    // 2. Inicialização do Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // 3. App Check (Só ativa se tiver a chave, evita crash)
    final recaptchaKey = dotenv.env['RECAPTCHA_SITE_KEY'];
    if (recaptchaKey != null && recaptchaKey.isNotEmpty) {
      await FirebaseAppCheck.instance.activate(
        providerWeb: ReCaptchaV3Provider(recaptchaKey),
      );
    } else {
      debugPrint("Aviso: RECAPTCHA_SITE_KEY não configurado. App Check ignorado.");
    }

    // 4. Configurações adicionais
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('language_code');
    final String? countryCode = prefs.getString('country_code');
    final String? themeMode = prefs.getString('theme_mode');
    final String? customTheme = prefs.getString('custom_theme_type');
    final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    runApp(MyApp(
      initialLocale: languageCode != null ? Locale(languageCode, countryCode) : null,
      initialThemeMode: themeMode,
      initialCustomTheme: customTheme,
      onboardingComplete: onboardingComplete,
    ));
  } catch (e) {
    // Se der erro fatal, mostra na tela em vez de ficar branco
    debugPrint("Erro fatal na inicialização: $e");
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text("Erro ao iniciar o app:\n\n$e\n\nVerifique o console (F12) para detalhes.", 
              style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatefulWidget {
  final Locale? initialLocale;
  final String? initialThemeMode;
  final String? initialCustomTheme;
  final bool onboardingComplete;

  const MyApp({super.key, this.initialLocale, this.initialThemeMode, this.initialCustomTheme, required this.onboardingComplete});

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
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    if (widget.initialThemeMode != null) {
      _themeMode = _getThemeModeFromString(widget.initialThemeMode!);
    }
    if (widget.initialCustomTheme != null) {
      _customThemeType = AppThemeType.values.firstWhere(
        (e) => e.toString() == widget.initialCustomTheme, 
        orElse: () => AppThemeType.sistema
      );
    }
    _setupNotifications();
  }

  ThemeMode _getThemeModeFromString(String mode) {
    switch (mode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  String _getStringFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark: return 'dark';
      default: return 'system';
    }
  }

  void setLocale(Locale locale) async {
    setState(() {
      _locale = locale;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    if (locale.countryCode != null) {
      await prefs.setString('country_code', locale.countryCode!);
    }
    _atualizarPreferenciasUsuario(locale: '${locale.languageCode}_${locale.countryCode ?? ""}');
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

  Future<void> _atualizarPreferenciasUsuario({String? theme, String? locale}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // O método atualizarPreferenciasUsuario não existe, mas o de tema sim.
      // Vamos chamar o que existe para não quebrar.
      if (theme != null) await FirestoreService().atualizarTemaUsuario(user.uid, theme);
    }
  }

  void _setupNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    // Listener para mensagens em Primeiro Plano (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Notificação em primeiro plano: ${message.notification?.title}');
      
      if (message.notification != null) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('${message.notification!.title}: ${message.notification!.body ?? ""}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.teal,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    // Obter e salvar token
    String? token = await messaging.getToken(
      // Substitua pela chave copiada do Console do Firebase
      vapidKey: dotenv.env['VAPID_KEY'], 
    );
    if (token != null) {
      _salvarTokenNoBanco(token);
    }

    // Ouvir atualização de token
    messaging.onTokenRefresh.listen(_salvarTokenNoBanco);
  }

  void _salvarTokenNoBanco(String token) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirestoreService().atualizarToken(user.uid, token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          scaffoldMessengerKey: _scaffoldMessengerKey, // Chave para exibir SnackBars globais
          onGenerateTitle: (context) => AppLocalizations.of(context)?.appTitle ?? 'Agenda Massoterapia',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: lightDynamic ?? AppColors.lightScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic ?? AppColors.darkScheme,
            useMaterial3: true,
          ),
          themeAnimationDuration: const Duration(milliseconds: 800), // Transição suave (Fade)
          themeAnimationCurve: Curves.easeInOut,
          themeMode: _themeMode,
          locale: _locale,
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
            Locale('ja', 'JP'),
          ],
          home: widget.onboardingComplete ? const LoginView() : const OnboardingView(),
          // Envolve todo o app no fundo animado
          builder: (context, child) {
            return BackgroundSoundManager(
              themeType: _customThemeType,
              child: AnimatedBackground(
                themeType: _customThemeType,
                // Garante que o fundo do Scaffold seja transparente para ver a animação
                child: Theme(
                  data: Theme.of(context).copyWith(scaffoldBackgroundColor: _customThemeType != AppThemeType.sistema && _customThemeType != AppThemeType.claro && _customThemeType != AppThemeType.escuro ? Colors.transparent : null),
                  child: child!,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
