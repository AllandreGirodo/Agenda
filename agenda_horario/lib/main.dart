import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:agenda/controller/firestore_service.dart';
import 'package:agenda/utils/custom_theme_data.dart';
import 'package:agenda/widgets/animated_background.dart';
import 'package:agenda/widgets/background_sound_manager.dart';
import 'package:agenda/view/login_view.dart';
import 'package:agenda/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:agenda/firebase_options.dart'; // Será gerado pelo flutterfire configure

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Manipular mensagens em segundo plano
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // Inicialização do Firebase (descomente após configurar o projeto no console)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await FirebaseAppCheck.instance.activate(
    // Web: Usa o reCAPTCHA v3 com a chave do site
    webProvider: ReCaptchaV3Provider(dotenv.env['RECAPTCHA_SITE_KEY'] ?? ''),
    // Android: Usa o provedor de Debug para emuladores (em produção usaria PlayIntegrity)
    androidProvider: AndroidProvider.debug,
  );

  // registra o handler de mensagens em segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Carregar preferências salvas
  final prefs = await SharedPreferences.getInstance();
  final String? languageCode = prefs.getString('language_code');
  final String? countryCode = prefs.getString('country_code');
  final String? themeMode = prefs.getString('theme_mode');
  final String? customTheme = prefs.getString('custom_theme_type');

  runApp(MyApp(
    initialLocale: languageCode != null ? Locale(languageCode, countryCode) : null,
    initialThemeMode: themeMode,
    initialCustomTheme: customTheme,
  ));
}

class MyApp extends StatefulWidget {
  final Locale? initialLocale;
  final String? initialThemeMode;
  final String? initialCustomTheme;

  const MyApp({super.key, this.initialLocale, this.initialThemeMode, this.initialCustomTheme});

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
      if (type == AppThemeType.claro) _themeMode = ThemeMode.light;
      else if (type == AppThemeType.escuro) _themeMode = ThemeMode.dark;
      else if (type == AppThemeType.sistema) _themeMode = ThemeMode.system;
      else _themeMode = ThemeMode.light; // Temas coloridos usam base clara por padrão
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
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)?.appTitle ?? 'Agenda Massoterapia',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic ?? ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
            useMaterial3: true,
          ),
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
          home: const LoginView(),
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
  }
}
