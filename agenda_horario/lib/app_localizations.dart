import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'pt': {
      'appTitle': 'Agenda Massoterapia',
      'loginTitle': 'Agenda Massoterapia',
      'emailLabel': 'Email',
      'passwordLabel': 'Senha',
      'enterButton': 'ENTRAR',
      'createAccountButton': 'Criar conta',
      'fillFieldsError': 'Por favor, preencha email e senha',
      'loginSuccess': 'Login realizado com sucesso (Simulação)',
    },
    'en': {
      'appTitle': 'Massage Therapy Agenda',
      'loginTitle': 'Massage Therapy Agenda',
      'emailLabel': 'Email',
      'passwordLabel': 'Password',
      'enterButton': 'ENTER',
      'createAccountButton': 'Create account',
      'fillFieldsError': 'Please fill in email and password',
      'loginSuccess': 'Login successful (Simulation)',
    },
    'es': {
      'appTitle': 'Agenda de Masoterapia',
      'loginTitle': 'Agenda de Masoterapia',
      'emailLabel': 'Correo electrónico',
      'passwordLabel': 'Contraseña',
      'enterButton': 'ENTRAR',
      'createAccountButton': 'Crear cuenta',
      'fillFieldsError': 'Por favor complete correo y contraseña',
      'loginSuccess': 'Inicio de sesión exitoso (Simulación)',
    },
  };

  String get appTitle => _localizedValues[locale.languageCode]!['appTitle']!;
  String get loginTitle => _localizedValues[locale.languageCode]!['loginTitle']!;
  String get emailLabel => _localizedValues[locale.languageCode]!['emailLabel']!;
  String get passwordLabel => _localizedValues[locale.languageCode]!['passwordLabel']!;
  String get enterButton => _localizedValues[locale.languageCode]!['enterButton']!;
  String get createAccountButton => _localizedValues[locale.languageCode]!['createAccountButton']!;
  String get fillFieldsError => _localizedValues[locale.languageCode]!['fillFieldsError']!;
  String get loginSuccess => _localizedValues[locale.languageCode]!['loginSuccess']!;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['pt', 'en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}