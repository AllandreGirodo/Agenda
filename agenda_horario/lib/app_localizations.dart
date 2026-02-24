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
      'forgotPasswordButton': 'Esqueci minha senha',
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
      'forgotPasswordButton': 'Forgot password?',
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
      'forgotPasswordButton': '¿Olvidó su contraseña?',
    },
    'ja': {
      'appTitle': 'マッサージ予約',
      'loginTitle': 'マッサージ予約',
      'emailLabel': 'メールアドレス',
      'passwordLabel': 'パスワード',
      'enterButton': 'ログイン',
      'createAccountButton': 'アカウント作成',
      'fillFieldsError': 'メールとパスワードを入力してください',
      'loginSuccess': 'ログイン成功（シミュレーション）',
      'forgotPasswordButton': 'パスワードを忘れた場合',
    },
  };

  // Método auxiliar para buscar a tradução com fallback para PT
  String _t(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? 
           _localizedValues['pt']![key] ?? 
           key;
  }

  String get appTitle => _t('appTitle');
  String get loginTitle => _t('loginTitle');
  String get emailLabel => _t('emailLabel');
  String get passwordLabel => _t('passwordLabel');
  String get enterButton => _t('enterButton');
  String get createAccountButton => _t('createAccountButton');
  String get fillFieldsError => _t('fillFieldsError');
  String get loginSuccess => _t('loginSuccess');
  String get forgotPasswordButton => _t('forgotPasswordButton');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['pt', 'en', 'es', 'ja'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}