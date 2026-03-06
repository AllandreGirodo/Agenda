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
      // Cadastro
      'signupTitle': 'Criar Conta',
      'fullNameLabel': 'Nome Completo',
      'whatsappLabel': 'WhatsApp',
      'registerButton': 'CADASTRAR',
      'registrationError': 'Erro ao cadastrar',
      // Agendamento
      'appointmentsTitle': 'Agendamentos',
      'newAppointmentTitle': 'Novo Agendamento',
      'dateLabel': 'Data',
      'selectTimeHint': 'Selecione um horário',
      'cancelButton': 'Cancelar',
      'scheduleButton': 'Agendar',
      'appointmentSuccess': 'Agendamento realizado com sucesso!',
      'noAppointmentsFound': 'Nenhum agendamento encontrado.',
      'viewingAll': 'Vendo Todos',
      'viewingMine': 'Vendo Meus',
      'myProfileTooltip': 'Meu Perfil',
      'logoutTooltip': 'Sair',
      // Perfil
      'profileTitle': 'Meu Perfil',
      'dataTab': 'Dados',
      'historyTab': 'Histórico',
      'personalDataTitle': 'Dados Pessoais',
      'cpfLabel': 'CPF',
      'cepLabel': 'CEP',
      'addressLabel': 'Endereço',
      'birthDateLabel': 'Data de Nascimento',
      'anamnesisTitle': 'Ficha de Anamnese',
      'medicalHistoryLabel': 'Histórico Médico',
      'allergiesLabel': 'Alergias',
      'medicationsLabel': 'Medicamentos em uso',
      'surgeriesLabel': 'Cirurgias Recentes',
      'deleteAccountButton': 'Excluir minha conta e dados (LGPD)',
      'saveButton': 'Salvar',
      'requiredField': 'Este campo é obrigatório',
      // Aguardando Aprovação
      'waitingApprovalTitle': 'Aguardando Aprovação',
      'analysisTitle': 'Cadastro em Análise',
      'analysisMessage': 'Seu cadastro realizado em\n{date}\nestá aguardando aprovação da administradora.',
      'contactAdminButton': 'Falar com a Administradora',
      'backToLoginButton': 'Voltar para Login',
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
      // Signup
      'signupTitle': 'Create Account',
      'fullNameLabel': 'Full Name',
      'whatsappLabel': 'WhatsApp',
      'registerButton': 'REGISTER',
      'registrationError': 'Error registering',
      // Appointment
      'appointmentsTitle': 'Appointments',
      'newAppointmentTitle': 'New Appointment',
      'dateLabel': 'Date',
      'selectTimeHint': 'Select a time',
      'cancelButton': 'Cancel',
      'scheduleButton': 'Schedule',
      'appointmentSuccess': 'Appointment scheduled successfully!',
      'noAppointmentsFound': 'No appointments found.',
      'viewingAll': 'Viewing All',
      'viewingMine': 'Viewing Mine',
      'myProfileTooltip': 'My Profile',
      'logoutTooltip': 'Logout',
      // Profile
      'profileTitle': 'My Profile',
      'dataTab': 'Data',
      'historyTab': 'History',
      'personalDataTitle': 'Personal Data',
      'cpfLabel': 'SSN/CPF',
      'cepLabel': 'Zip Code',
      'addressLabel': 'Address',
      'birthDateLabel': 'Birth Date',
      'anamnesisTitle': 'Anamnesis Form',
      'medicalHistoryLabel': 'Medical History',
      'allergiesLabel': 'Allergies',
      'medicationsLabel': 'Medications in use',
      'surgeriesLabel': 'Recent Surgeries',
      'deleteAccountButton': 'Delete my account and data (GDPR)',
      'saveButton': 'Save',
      'requiredField': 'This field is required',
      // Waiting Approval
      'waitingApprovalTitle': 'Waiting Approval',
      'analysisTitle': 'Registration Under Review',
      'analysisMessage': 'Your registration made on\n{date}\nis awaiting administrator approval.',
      'contactAdminButton': 'Contact Administrator',
      'backToLoginButton': 'Back to Login',
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
      // Signup
      'signupTitle': 'Crear Cuenta',
      'fullNameLabel': 'Nombre Completo',
      'whatsappLabel': 'WhatsApp',
      'registerButton': 'REGISTRAR',
      'registrationError': 'Error al registrar',
      // Appointment
      'appointmentsTitle': 'Citas',
      'newAppointmentTitle': 'Nueva Cita',
      'dateLabel': 'Fecha',
      'selectTimeHint': 'Seleccione una hora',
      'cancelButton': 'Cancelar',
      'scheduleButton': 'Agendar',
      'appointmentSuccess': '¡Cita programada con éxito!',
      'noAppointmentsFound': 'No se encontraron citas.',
      'viewingAll': 'Viendo Todos',
      'viewingMine': 'Viendo Míos',
      'myProfileTooltip': 'Mi Perfil',
      'logoutTooltip': 'Salir',
      // Profile
      'profileTitle': 'Mi Perfil',
      'dataTab': 'Datos',
      'historyTab': 'Historial',
      'personalDataTitle': 'Datos Personales',
      'cpfLabel': 'CPF/DNI',
      'cepLabel': 'Código Postal',
      'addressLabel': 'Dirección',
      'birthDateLabel': 'Fecha de Nacimiento',
      'anamnesisTitle': 'Ficha de Anamnesis',
      'medicalHistoryLabel': 'Historial Médico',
      'allergiesLabel': 'Alergias',
      'medicationsLabel': 'Medicamentos en uso',
      'surgeriesLabel': 'Cirugías Recientes',
      'deleteAccountButton': 'Eliminar mi cuenta y datos',
      'saveButton': 'Guardar',
      'requiredField': 'Este campo es obligatorio',
      // Waiting Approval
      'waitingApprovalTitle': 'Esperando Aprobación',
      'analysisTitle': 'Registro en Revisión',
      'analysisMessage': 'Su registro realizado el\n{date}\nestá esperando aprobación del administrador.',
      'contactAdminButton': 'Contactar Administrador',
      'backToLoginButton': 'Volver al Login',
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
      // Signup
      'signupTitle': 'アカウント作成',
      'fullNameLabel': '氏名',
      'whatsappLabel': 'WhatsApp',
      'registerButton': '登録',
      'registrationError': '登録エラー',
      // Appointment
      'appointmentsTitle': '予約',
      'newAppointmentTitle': '新規予約',
      'dateLabel': '日付',
      'selectTimeHint': '時間を選択',
      'cancelButton': 'キャンセル',
      'scheduleButton': '予約する',
      'appointmentSuccess': '予約が完了しました！',
      'noAppointmentsFound': '予約が見つかりません。',
      'viewingAll': 'すべて表示',
      'viewingMine': '自分の予約',
      'myProfileTooltip': 'プロフィール',
      'logoutTooltip': 'ログアウト',
      // Profile
      'profileTitle': 'プロフィール',
      'dataTab': 'データ',
      'historyTab': '履歴',
      'personalDataTitle': '個人情報',
      'cpfLabel': 'CPF',
      'cepLabel': '郵便番号',
      'addressLabel': '住所',
      'birthDateLabel': '生年月日',
      'anamnesisTitle': '問診票',
      'medicalHistoryLabel': '病歴',
      'allergiesLabel': 'アレルギー',
      'medicationsLabel': '服用中の薬',
      'surgeriesLabel': '最近の手術',
      'deleteAccountButton': 'アカウントとデータを削除',
      'saveButton': '保存',
      'requiredField': '必須項目です',
      // Waiting Approval
      'waitingApprovalTitle': '承認待ち',
      'analysisTitle': '審査中',
      'analysisMessage': '{date} に行われた登録は\n管理者の承認待ちです。',
      'contactAdminButton': '管理者に連絡',
      'backToLoginButton': 'ログインに戻る',
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
  
  // Signup
  String get signupTitle => _t('signupTitle');
  String get fullNameLabel => _t('fullNameLabel');
  String get whatsappLabel => _t('whatsappLabel');
  String get registerButton => _t('registerButton');
  String get registrationError => _t('registrationError');
  // Appointment
  String get appointmentsTitle => _t('appointmentsTitle');
  String get newAppointmentTitle => _t('newAppointmentTitle');
  String get dateLabel => _t('dateLabel');
  String get selectTimeHint => _t('selectTimeHint');
  String get cancelButton => _t('cancelButton');
  String get scheduleButton => _t('scheduleButton');
  String get appointmentSuccess => _t('appointmentSuccess');
  String get noAppointmentsFound => _t('noAppointmentsFound');
  String get viewingAll => _t('viewingAll');
  String get viewingMine => _t('viewingMine');
  String get myProfileTooltip => _t('myProfileTooltip');
  String get logoutTooltip => _t('logoutTooltip');
  // Profile
  String get profileTitle => _t('profileTitle');
  String get dataTab => _t('dataTab');
  String get historyTab => _t('historyTab');
  String get personalDataTitle => _t('personalDataTitle');
  String get cpfLabel => _t('cpfLabel');
  String get cepLabel => _t('cepLabel');
  String get addressLabel => _t('addressLabel');
  String get birthDateLabel => _t('birthDateLabel');
  String get anamnesisTitle => _t('anamnesisTitle');
  String get medicalHistoryLabel => _t('medicalHistoryLabel');
  String get allergiesLabel => _t('allergiesLabel');
  String get medicationsLabel => _t('medicationsLabel');
  String get surgeriesLabel => _t('surgeriesLabel');
  String get deleteAccountButton => _t('deleteAccountButton');
  String get saveButton => _t('saveButton');
  String get requiredField => _t('requiredField');
  // Waiting Approval
  String get waitingApprovalTitle => _t('waitingApprovalTitle');
  String get analysisTitle => _t('analysisTitle');
  String get contactAdminButton => _t('contactAdminButton');
  String get backToLoginButton => _t('backToLoginButton');
  String analysisMessage(String date) => _t('analysisMessage').replaceAll('{date}', date);
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