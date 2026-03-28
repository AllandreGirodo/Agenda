import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
      'phoneNumberLabel': 'Telefone/Celular',
    'isWhatsappNumber': 'Este número é WhatsApp',
    'isNotWhatsappNumber': 'Este número não é WhatsApp',
      'signupInvalidEmailTyping': 'E-mail ainda não é válido.',
      'signupPhoneOnlyDigitsMessage': 'Preencha apenas com números de 0 a 9.',
      'signupPhoneMinDigitsMessage': 'Mínimo de 10 dígitos necessários.',
      'signupPhoneDigitsLimitReached': 'Limite de dígitos do celular atingido.',
      'signupPasswordCriteriaTitle': 'Senha sugerida:',
      'signupPasswordRuleLength': 'Entre 6 e 20 caracteres',
      'signupPasswordRuleUppercase': 'Pelo menos 1 letra maiúscula',
      'signupPasswordRuleLowercase': 'Pelo menos 1 letra minúscula',
      'signupPasswordRuleNumber': 'Pelo menos 1 número',
      'signupPasswordRuleSpecial': 'Pelo menos 1 caractere especial',
      'signupPasswordWeakMessage':
          'A senha ainda não atende ao padrão sugerido.',
      'signupPasswordReadyMessage': 'Senha válida. Você já pode se cadastrar.',
      'signupNameRequiredMessage': 'Informe seu nome completo.',
      'signupPhoneMinDigitsSubmitMessage': '{label} com no mínimo 10 dígitos.',
      'signupLgpdConsentLabel':
          'Li e aceito os Termos de Uso e Política de Privacidade.',
      'signupLgpdConsentPendingMessage':
          'Aceite os Termos de Uso e Política de Privacidade para continuar.',
      'signupLgpdConsentAcceptedMessage':
          'Termos aceitos. Você já pode concluir o cadastro.',
      'signupLgpdConsentError':
          'É obrigatório ler e aceitar os Termos de Uso e Política de Privacidade para continuar.',
      'signupTermsReadButton': 'Ler Termos de Uso e Política de Privacidade',
      'signupGooglePrefilledEmailHint':
          'Complete os campos obrigatórios para concluir o vínculo deste e-mail.',
      'signupLinkedClientId': 'vinculo_id_cliente: {id}',
      'signupExistingClientLinkedMessage':
          'Já existe um cadastro completo para este e-mail. vinculo_id_cliente: {id}',
      'signupGoogleCompleteButton': 'CONCLUIR CADASTRO',
      'signupPendingRequiredFields':
          'Campos obrigatórios pendentes: {fields}',
      'registerButton': 'CADASTRAR',
      'registrationError': 'Erro ao cadastrar',
      // Agendamento
      'appointmentsTitle': 'Agendamentos',
      'newAppointmentTitle': 'Novo Agendamento',
      'dateLabel': 'Data',
      'selectTimeHint': 'Selecione um horário',
      'massageTypeRelaxante': 'Massagem Relaxante',
      'massageTypeDrenagemLinfatica': 'Drenagem Linfática',
      'massageTypeTerapeutica': 'Massagem Terapêutica',
      'massageTypeDesportiva': 'Massagem Desportiva',
      'massageTypePedrasQuentes': 'Massagem com Pedras Quentes',
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
      'analysisMessage':
          'Seu cadastro realizado em\n{date}\nestá aguardando aprovação da administradora.',
      'contactAdminButton': 'Falar com a Administradora',
      'contactAdminButtonWithName': 'Falar com {adminName}',
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
      'phoneNumberLabel': 'Phone Number',
    'isWhatsappNumber': 'WhatsApp number',
    'isNotWhatsappNumber': 'Not WhatsApp',
      'signupInvalidEmailTyping': 'Email is not valid yet.',
      'signupPhoneOnlyDigitsMessage': 'Use only numbers from 0 to 9.',
      'signupPhoneMinDigitsMessage': 'Minimum of 10 digits required.',
      'signupPhoneDigitsLimitReached': 'Phone digit limit reached.',
      'signupPasswordCriteriaTitle': 'Suggested password:',
      'signupPasswordRuleLength': 'Between 6 and 20 characters',
      'signupPasswordRuleUppercase': 'At least 1 uppercase letter',
      'signupPasswordRuleLowercase': 'At least 1 lowercase letter',
      'signupPasswordRuleNumber': 'At least 1 number',
      'signupPasswordRuleSpecial': 'At least 1 special character',
      'signupPasswordWeakMessage':
          'Password does not meet the suggested pattern yet.',
      'signupPasswordReadyMessage':
          'Password looks good. You can register now.',
      'signupNameRequiredMessage': 'Please enter your full name.',
      'signupPhoneMinDigitsSubmitMessage': '{label} with at least 10 digits.',
      'signupLgpdConsentLabel':
          'I have read and agree to the Terms of Use and Privacy Policy.',
      'signupLgpdConsentPendingMessage':
          'Please accept the Terms of Use and Privacy Policy to continue.',
      'signupLgpdConsentAcceptedMessage':
          'Terms accepted. You can complete your registration.',
      'signupLgpdConsentError':
          'You must read and accept the Terms of Use and Privacy Policy to continue.',
      'signupTermsReadButton': 'Read Terms of Use and Privacy Policy',
      'registerButton': 'REGISTER',
      'registrationError': 'Error registering',
      // Appointment
      'appointmentsTitle': 'Appointments',
      'newAppointmentTitle': 'New Appointment',
      'dateLabel': 'Date',
      'selectTimeHint': 'Select a time',
      'massageTypeRelaxante': 'Relaxing Massage',
      'massageTypeDrenagemLinfatica': 'Lymphatic Drainage',
      'massageTypeTerapeutica': 'Therapeutic Massage',
      'massageTypeDesportiva': 'Sports Massage',
      'massageTypePedrasQuentes': 'Hot Stone Massage',
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
      'analysisMessage':
          'Your registration made on\n{date}\nis awaiting administrator approval.',
      'contactAdminButton': 'Contact Administrator',
      'contactAdminButtonWithName': 'Contact {adminName}',
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
      'phoneNumberLabel': 'Número de teléfono',
    'isWhatsappNumber': 'Es WhatsApp',
    'isNotWhatsappNumber': 'No es WhatsApp',
      'signupInvalidEmailTyping': 'El correo aún no es válido.',
      'signupPhoneOnlyDigitsMessage': 'Complete solo con números del 0 al 9.',
      'signupPhoneMinDigitsMessage': 'Se requieren mínimo 10 dígitos.',
      'signupPhoneDigitsLimitReached':
          'Se alcanzó el límite de dígitos del celular.',
      'signupPasswordCriteriaTitle': 'Contraseña sugerida:',
      'signupPasswordRuleLength': 'Entre 6 y 20 caracteres',
      'signupPasswordRuleUppercase': 'Al menos 1 letra mayúscula',
      'signupPasswordRuleLowercase': 'Al menos 1 letra minúscula',
      'signupPasswordRuleNumber': 'Al menos 1 número',
      'signupPasswordRuleSpecial': 'Al menos 1 carácter especial',
      'signupPasswordWeakMessage':
          'La contraseña aún no cumple el patrón sugerido.',
      'signupPasswordReadyMessage': 'Contraseña válida. Ya puede registrarse.',
      'signupNameRequiredMessage': 'Informe su nombre completo.',
      'signupPhoneMinDigitsSubmitMessage': '{label} con al menos 10 dígitos.',
      'signupLgpdConsentLabel':
          'He leído y acepto los Términos de Uso y la Política de Privacidad.',
      'signupLgpdConsentPendingMessage':
          'Acepte los Términos de Uso y la Política de Privacidad para continuar.',
      'signupLgpdConsentAcceptedMessage':
          'Términos aceptados. Ya puede completar su registro.',
      'signupLgpdConsentError':
          'Debe leer y aceptar los Términos de Uso y la Política de Privacidad para continuar.',
      'signupTermsReadButton': 'Leer Términos de Uso y Política de Privacidad',
      'registerButton': 'REGISTRAR',
      'registrationError': 'Error al registrar',
      // Appointment
      'appointmentsTitle': 'Citas',
      'newAppointmentTitle': 'Nueva Cita',
      'dateLabel': 'Fecha',
      'selectTimeHint': 'Seleccione una hora',
      'massageTypeRelaxante': 'Masaje Relajante',
      'massageTypeDrenagemLinfatica': 'Drenaje Linfático',
      'massageTypeTerapeutica': 'Masaje Terapéutico',
      'massageTypeDesportiva': 'Masaje Deportivo',
      'massageTypePedrasQuentes': 'Masaje con Piedras Calientes',
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
      'analysisMessage':
          'Su registro realizado el\n{date}\nestá esperando aprobación del administrador.',
      'contactAdminButton': 'Contactar Administrador',
      'contactAdminButtonWithName': 'Contactar a {adminName}',
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
      'phoneNumberLabel': '電話番号',
    'isWhatsappNumber': 'WhatsApp番号',
    'isNotWhatsappNumber': 'WhatsApp以外',
      'signupInvalidEmailTyping': 'メールアドレスの形式がまだ無効です。',
      'signupPhoneOnlyDigitsMessage': '0から9の数字のみ入力してください。',
      'signupPhoneMinDigitsMessage': '最低10桁が必要です。',
      'signupPhoneDigitsLimitReached': '電話番号の桁数上限に達しました。',
      'signupPasswordCriteriaTitle': '推奨パスワード:',
      'signupPasswordRuleLength': '6〜20文字',
      'signupPasswordRuleUppercase': '英大文字を1文字以上',
      'signupPasswordRuleLowercase': '英小文字を1文字以上',
      'signupPasswordRuleNumber': '数字を1文字以上',
      'signupPasswordRuleSpecial': '記号を1文字以上',
      'signupPasswordWeakMessage': 'パスワードが推奨パターンをまだ満たしていません。',
      'signupPasswordReadyMessage': 'パスワードは有効です。登録できます。',
      'signupNameRequiredMessage': '氏名を入力してください。',
      'signupPhoneMinDigitsSubmitMessage': '{label}は10桁以上で入力してください。',
      'signupLgpdConsentLabel': '利用規約とプライバシーポリシーを読み、同意します。',
      'signupLgpdConsentPendingMessage': '続行するには利用規約とプライバシーポリシーに同意してください。',
      'signupLgpdConsentAcceptedMessage': '利用規約への同意が完了しました。登録を完了できます。',
      'signupLgpdConsentError': '続行するには利用規約とプライバシーポリシーの確認と同意が必要です。',
      'signupTermsReadButton': '利用規約とプライバシーポリシーを読む',
      'registerButton': '登録',
      'registrationError': '登録エラー',
      // Appointment
      'appointmentsTitle': '予約',
      'newAppointmentTitle': '新規予約',
      'dateLabel': '日付',
      'selectTimeHint': '時間を選択',
      'massageTypeRelaxante': 'リラクゼーションマッサージ',
      'massageTypeDrenagemLinfatica': 'リンパドレナージュ',
      'massageTypeTerapeutica': 'セラピーマッサージ',
      'massageTypeDesportiva': 'スポーツマッサージ',
      'massageTypePedrasQuentes': 'ホットストーンマッサージ',
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
    'contactAdminButtonWithName': '{adminName} に連絡',
      'backToLoginButton': 'ログインに戻る',
    },
    'fr': {
      'appTitle': 'Agenda de massothérapie',
      'loginTitle': 'Agenda de massothérapie',
      'emailLabel': 'Email',
      'passwordLabel': 'Mot de passe',
      'enterButton': 'ENTRER',
      'createAccountButton': 'Créer un compte',
      'fillFieldsError': 'Veuillez remplir l\'email et le mot de passe',
      'loginSuccess': 'Connexion réussie (Simulation)',
      'forgotPasswordButton': 'Mot de passe oublié?',
      // Signup
      'signupTitle': 'Créer un compte',
      'fullNameLabel': 'Nom complet',
      'whatsappLabel': 'WhatsApp',
      'phoneNumberLabel': 'Téléphone',
    'isWhatsappNumber': 'Numéro WhatsApp',
    'isNotWhatsappNumber': 'Pas WhatsApp',
      'signupInvalidEmailTyping': 'L\'email n\'est pas encore valide.',
      'signupPhoneOnlyDigitsMessage':
          'Complétez uniquement avec les chiffres de 0 à 9.',
      'signupPhoneMinDigitsMessage': 'Minimum de 10 chiffres requis.',
      'signupPhoneDigitsLimitReached':
          'Limite de chiffres du téléphone atteinte.',
      'signupPasswordCriteriaTitle': 'Mot de passe suggéré:',
      'signupPasswordRuleLength': 'Entre 6 et 20 caractères',
      'signupPasswordRuleUppercase': 'Au moins 1 lettre majuscule',
      'signupPasswordRuleLowercase': 'Au moins 1 lettre minuscule',
      'signupPasswordRuleNumber': 'Au moins 1 chiffre',
      'signupPasswordRuleSpecial': 'Au moins 1 caractère spécial',
      'signupPasswordWeakMessage':
          'Le mot de passe n\'a pas encore respecté le modèle suggéré.',
      'signupPasswordReadyMessage':
          'Mot de passe valide. Vous pouvez maintenant vous enregistrer.',
      'signupNameRequiredMessage': 'Veuillez saisir votre nom complet.',
      'signupPhoneMinDigitsSubmitMessage': '{label} avec au moins 10 chiffres.',
      'signupLgpdConsentLabel':
          'J\'ai lu et j\'accepte les conditions d\'utilisation et la politique de confidentialité.',
      'signupLgpdConsentPendingMessage':
          'Veuillez accepter les conditions d\'utilisation et la politique de confidentialité pour continuer.',
      'signupLgpdConsentAcceptedMessage':
          'Conditions acceptées. Vous pouvez finaliser votre inscription.',
      'signupLgpdConsentError':
          'Vous devez lire et accepter les conditions d\'utilisation et la politique de confidentialité pour continuer.',
      'signupTermsReadButton':
          'Lire les conditions d\'utilisation et la politique de confidentialité',
      'registerButton': 'ENREGISTRER',
      'registrationError': 'Erreur d\'enregistrement',
      // Appointment
      'appointmentsTitle': 'Rendez-vous',
      'newAppointmentTitle': 'Nouveau rendez-vous',
      'dateLabel': 'Date',
      'selectTimeHint': 'Sélectionnez une heure',
      'massageTypeRelaxante': 'Massage relaxant',
      'massageTypeDrenagemLinfatica': 'Drainage lymphatique',
      'massageTypeTerapeutica': 'Massage thérapeutique',
      'massageTypeDesportiva': 'Massage sportif',
      'massageTypePedrasQuentes': 'Massage aux pierres chaudes',
      'cancelButton': 'Annuler',
      'scheduleButton': 'Planifier',
      'appointmentSuccess': 'Rendez-vous programmé avec succès!',
      'noAppointmentsFound': 'Aucun rendez-vous trouvé.',
      'viewingAll': 'Affichage di tout',
      'viewingMine': 'Affichage des miens',
      'myProfileTooltip': 'Mon Profil',
      'logoutTooltip': 'Déconnexion',
      // Profile
      'profileTitle': 'Mon Profil',
      'dataTab': 'Données',
      'historyTab': 'Historique',
      'personalDataTitle': 'Données personnelles',
      'cpfLabel': 'CPF/Identifiant',
      'cepLabel': 'Code Postal',
      'addressLabel': 'Adresse',
      'birthDateLabel': 'Date de naissance',
      'anamnesisTitle': 'Formulaire d\'anamnèse',
      'medicalHistoryLabel': 'Historique médical',
      'allergiesLabel': 'Allergies',
      'medicationsLabel': 'Médicaments utilisés',
      'surgeriesLabel': 'Chirurgies récentes',
      'deleteAccountButton': 'Supprimer mon compte et mes données',
      'saveButton': 'Enregistrer',
      'requiredField': 'Ce champ est obligatoire',
      // Waiting Approval
      'waitingApprovalTitle': 'En attente d\'approbation',
      'analysisTitle': 'Enregistrement en révision',
      'analysisMessage':
          'Votre enregistrement effectué le\n{date}\nattend l\'approbation de l\'administrateur.',
      'contactAdminButton': 'Contacter l\'administrateur',
      'contactAdminButtonWithName': 'Contacter {adminName}',
      'backToLoginButton': 'Retour à la connexion',
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
  String get phoneNumberLabel => _t('phoneNumberLabel');
  String get isWhatsappNumber => _t('isWhatsappNumber');
  String get isNotWhatsappNumber => _t('isNotWhatsappNumber');
  String get signupInvalidEmailTyping => _t('signupInvalidEmailTyping');
  String get signupPhoneOnlyDigitsMessage => _t('signupPhoneOnlyDigitsMessage');
  String get signupPhoneMinDigitsMessage => _t('signupPhoneMinDigitsMessage');
  String get signupPhoneDigitsLimitReached =>
      _t('signupPhoneDigitsLimitReached');
  String get signupPasswordCriteriaTitle => _t('signupPasswordCriteriaTitle');
  String get signupPasswordRuleLength => _t('signupPasswordRuleLength');
  String get signupPasswordRuleUppercase => _t('signupPasswordRuleUppercase');
  String get signupPasswordRuleLowercase => _t('signupPasswordRuleLowercase');
  String get signupPasswordRuleNumber => _t('signupPasswordRuleNumber');
  String get signupPasswordRuleSpecial => _t('signupPasswordRuleSpecial');
  String get signupPasswordWeakMessage => _t('signupPasswordWeakMessage');
  String get signupPasswordReadyMessage => _t('signupPasswordReadyMessage');
  String get signupNameRequiredMessage => _t('signupNameRequiredMessage');
  String signupPhoneMinDigitsSubmitMessage(String label) =>
      _t('signupPhoneMinDigitsSubmitMessage').replaceAll('{label}', label);
  String get signupLgpdConsentLabel => _t('signupLgpdConsentLabel');
  String get signupLgpdConsentPendingMessage =>
      _t('signupLgpdConsentPendingMessage');
  String get signupLgpdConsentAcceptedMessage =>
      _t('signupLgpdConsentAcceptedMessage');
  String get signupLgpdConsentError => _t('signupLgpdConsentError');
  String get signupTermsReadButton => _t('signupTermsReadButton');
  String get signupGooglePrefilledEmailHint =>
      _t('signupGooglePrefilledEmailHint');
  String signupLinkedClientId(String id) =>
      _t('signupLinkedClientId').replaceAll('{id}', id);
  String signupExistingClientLinkedMessage(String id) =>
      _t('signupExistingClientLinkedMessage').replaceAll('{id}', id);
  String get signupGoogleCompleteButton => _t('signupGoogleCompleteButton');
  String signupPendingRequiredFields(String fields) =>
      _t('signupPendingRequiredFields').replaceAll('{fields}', fields);
  String get registerButton => _t('registerButton');
  String get registrationError => _t('registrationError');
  // Appointment
  String get appointmentsTitle => _t('appointmentsTitle');
  String get newAppointmentTitle => _t('newAppointmentTitle');
  String get dateLabel => _t('dateLabel');
  String get selectTimeHint => _t('selectTimeHint');
  String get massageTypeRelaxante => _t('massageTypeRelaxante');
  String get massageTypeDrenagemLinfatica => _t('massageTypeDrenagemLinfatica');
  String get massageTypeTerapeutica => _t('massageTypeTerapeutica');
  String get massageTypeDesportiva => _t('massageTypeDesportiva');
  String get massageTypePedrasQuentes => _t('massageTypePedrasQuentes');
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
    String contactAdminButtonWithName(String adminName) =>
            _t('contactAdminButtonWithName').replaceAll('{adminName}', adminName);
  String get backToLoginButton => _t('backToLoginButton');
  String analysisMessage(String date) =>
      _t('analysisMessage').replaceAll('{date}', date);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['pt', 'en', 'es', 'ja', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
