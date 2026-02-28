import 'package:flutter/material.dart';

class AppStrings {
  static Locale _currentLocale = const Locale('pt', 'BR');

  static void setLocale(Locale locale) {
    _currentLocale = locale;
  }

  static bool get _isPt => _currentLocale.languageCode == 'pt';
  
  // Validators
  static String get dataNascimentoObrigatoria => _isPt ? 'Data de nascimento obrigatória.' : 'Birth date is required.';
  static String erroIdadeMinima(int idade) => _isPt ? 'É necessário ter pelo menos $idade anos para se cadastrar.' : 'You must be at least $idade years old to register.';

  // Termos de Uso
  static String get termosUsoTitulo => _isPt ? 'Termos de Uso' : 'Terms of Use';
  static String get termosUsoTexto => _isPt ? """
1. Aceitação dos Termos
Ao utilizar este aplicativo para agendamento de serviços de massoterapia, você concorda com os termos descritos abaixo.

2. Agendamentos e Cancelamentos
Os cancelamentos devem ser feitos respeitando a antecedência mínima configurada no sistema. Cancelamentos tardios ou não comparecimento podem estar sujeitos a restrições em agendamentos futuros.

3. Saúde e Anamnese
É responsabilidade do cliente informar condições de saúde, alergias, cirurgias recentes e uso de medicamentos na ficha de anamnese. A omissão de dados pode acarretar riscos à saúde durante o procedimento.

4. Privacidade e Dados (LGPD)
Seus dados pessoais são coletados para fins de cadastro e histórico de atendimento. Você tem o direito de solicitar a anonimização da sua conta a qualquer momento através das configurações do perfil.

5. Pagamentos
Os valores dos serviços e pacotes estão sujeitos a alteração. O pagamento deve ser realizado conforme combinado com a profissional.
""" : """
1. Acceptance of Terms
By using this application for scheduling massage therapy services, you agree to the terms described below.

2. Scheduling and Cancellations
Cancellations must be made respecting the minimum notice period configured in the system. Late cancellations or no-shows may be subject to restrictions on future appointments.

3. Health and Anamnesis
It is the client's responsibility to inform health conditions, allergies, recent surgeries, and medication use in the anamnesis form. Omission of data may entail health risks during the procedure.

4. Privacy and Data (GDPR)
Your personal data is collected for registration and service history purposes. You have the right to request the anonymization of your account at any time through profile settings.

5. Payments
Service and package prices are subject to change. Payment must be made as agreed with the professional.
""";
  static String get termosUsoAceite => _isPt ? 'Li e concordo com os Termos de Uso e Política de Privacidade.' : 'I have read and agree to the Terms of Use and Privacy Policy.';
  static String get termosUsoBotao => _isPt ? 'Confirmar e Continuar' : 'Confirm and Continue';

  // Admin Config
  static String get configTitulo => _isPt ? 'Configuração de Campos' : 'Field Configuration';
  static String get configSalvaSucesso => _isPt ? 'Configurações salvas com sucesso!' : 'Settings saved successfully!';
  static String get configFinanceiro => _isPt ? 'Financeiro' : 'Financial';
  static String get configPrecoSessao => _isPt ? 'Preço da Sessão (R\$)' : 'Session Price (R\$)';
  static String get configRegrasCancelamento => _isPt ? 'Regras de Cancelamento' : 'Cancellation Rules';
  static String get configAntecedencia => _isPt ? 'Antecedência mínima (horas)' : 'Minimum notice (hours)';
  static String get configHorarioSono => _isPt ? 'Horário de Sono da Administradora' : 'Administrator Sleep Schedule';
  static String get configHorarioSonoDesc => _isPt ? 'Este intervalo não conta para o cálculo de antecedência.' : 'This interval does not count towards the notice calculation.';
  static String get configDormeAs => _isPt ? 'Dorme às' : 'Sleeps at';
  static String get configAcordaAs => _isPt ? 'Acorda às' : 'Wakes up at';
  static String get configCupons => _isPt ? 'Configuração de Cupons' : 'Coupon Configuration';
  static String get configCupomAtivo => _isPt ? 'Ativo (Campo visível)' : 'Active (Field visible)';
  static String get configCupomOculto => _isPt ? 'Oculto (Campo não aparece)' : 'Hidden (Field not shown)';
  static String get configCupomOpaco => _isPt ? 'Opacidade (Visível mas inativo)' : 'Opacity (Visible but inactive)';
  static String get configCupomOpacoDesc => _isPt ? 'Aparece com transparência e não clicável' : 'Appears transparent and not clickable';
  static String get configCamposObrigatorios => _isPt ? 'Marque os campos que devem ser OBRIGATÓRIOS para o cliente:' : 'Check the fields that must be MANDATORY for the client:';
  static String get configCampoCritico => _isPt ? 'Campo crítico (Sempre obrigatório)' : 'Critical field (Always mandatory)';
  static String get configBiometria => _isPt ? 'Biometria' : 'Biometrics';
  static String get configBiometriaDesc => _isPt ? 'Habilitar login com impressão digital/FaceID' : 'Enable fingerprint/FaceID login';
  static String get configChat => _isPt ? 'Chat' : 'Chat';
  static String get configChatAtivo => _isPt ? 'Chat Ativo' : 'Chat Active';
  static String get configChatDesc => _isPt ? 'Permitir troca de mensagens no agendamento' : 'Allow messaging in appointment';
  static String get configReciboLeitura => _isPt ? 'Recibo de Leitura' : 'Read Receipts';
  static String get backupTitulo => _isPt ? 'Backup e Restauração' : 'Backup and Restore';
  static String get backupExportar => _isPt ? 'Exportar Dados' : 'Export Data';
  static String get backupImportar => _isPt ? 'Importar Dados' : 'Import Data';

  static Map<String, String> get labelsConfig => _isPt ? {
    'whatsapp': 'WhatsApp',
    'endereco': 'Endereço Completo',
    'data_nascimento': 'Data de Nascimento',
    'historico_medico': 'Histórico Médico',
    'alergias': 'Alergias',
    'medicamentos': 'Uso de Medicamentos',
    'cirurgias': 'Cirurgias Recentes',
    'termos_uso': 'Termos de Uso (Aceite Obrigatório)',
  } : {
    'whatsapp': 'WhatsApp',
    'endereco': 'Full Address',
    'data_nascimento': 'Date of Birth',
    'historico_medico': 'Medical History',
    'alergias': 'Allergies',
    'medicamentos': 'Medication Use',
    'cirurgias': 'Recent Surgeries',
    'termos_uso': 'Terms of Use (Mandatory Acceptance)',
  };

  // Login
  static String get loginTitulo => _isPt ? 'Bem-vindo(a)' : 'Welcome';
  static String get loginSubtitulo => _isPt ? 'Faça login para agendar sua sessão' : 'Sign in to schedule your session';
  static String get emailLabel => _isPt ? 'E-mail' : 'Email';
  static String get senhaLabel => _isPt ? 'Senha' : 'Password';
  static String get entrarBtn => _isPt ? 'Entrar' : 'Sign In';
  static String get cadastrarBtn => _isPt ? 'Criar Conta' : 'Create Account';
  static String get esqueceuSenha => _isPt ? 'Esqueceu a senha?' : 'Forgot password?';
  static String get erroEmailObrigatorio => _isPt ? 'Por favor, digite seu e-mail para recuperar a senha.' : 'Please enter your email to reset password.';
  static String get emailRecuperacaoEnviado => _isPt ? 'E-mail de recuperação enviado! Verifique sua caixa de entrada.' : 'Recovery email sent! Check your inbox.';
  static String get biometriaBtn => _isPt ? 'Entrar com Biometria' : 'Login with Biometrics';
  static String get biometriaErro => _isPt ? 'Erro na autenticação biométrica' : 'Biometric authentication error';

  // Onboarding
  static String get onboardingTitulo1 => _isPt ? 'Bem-vindo(a)' : 'Welcome';
  static String get onboardingTexto1 => _isPt ? 'Gerencie seus agendamentos de massoterapia de forma fácil e rápida.' : 'Manage your massage therapy appointments easily and quickly.';
  static String get onboardingTitulo2 => _isPt ? 'Notificações' : 'Notifications';
  static String get onboardingTexto2 => _isPt ? 'Receba lembretes automáticos e atualizações sobre suas sessões.' : 'Receive automatic reminders and updates about your sessions.';
  static String get onboardingTitulo3 => _isPt ? 'Histórico Completo' : 'Full History';
  static String get onboardingTexto3 => _isPt ? 'Acompanhe seu histórico de atendimentos e controle seus pacotes.' : 'Track your service history and control your packages.';
  static String get pularBtn => _isPt ? 'Pular' : 'Skip';
  static String get comecarBtn => _isPt ? 'Começar' : 'Get Started';
  static String get googleLoginBtn => _isPt ? 'Entrar com Google' : 'Sign in with Google';

  // Notificações e Chat
  static String get notifAgendamentoAprovadoTitulo => _isPt ? 'Agendamento Aprovado!' : 'Appointment Approved!';
  static String get notifAgendamentoAprovadoCorpo => _isPt ? 'Seu horário foi confirmado. Te esperamos!' : 'Your slot is confirmed. See you there!';
  static String get notifNovaMensagemTitulo => _isPt ? 'Nova Mensagem' : 'New Message';
  static String notifNovaMensagemCorpo(String remetente, String tipo, String conteudo) {
    if (tipo == 'texto') return '$remetente: $conteudo';
    return '$remetente enviou um(a) $tipo';
  }
  static String get chatDesativadoMsg => _isPt ? 'O chat pelo aplicativo está desativado para este atendimento.' : 'In-app chat is disabled for this service.';
  static String get chatIrWhatsapp => _isPt ? 'Conversar no WhatsApp' : 'Chat on WhatsApp';
  static String get chatTitulo => _isPt ? 'Chat do Agendamento' : 'Appointment Chat';
  static String get chatPlaceholder => _isPt ? 'Digite sua mensagem...' : 'Type your message...';

  // Financeiro
  static String get financeiroAnualTitulo => _isPt ? 'Faturamento Anual' : 'Annual Revenue';

  // Perfil
  static String get profileTitle => _isPt ? 'Meu Perfil' : 'My Profile';
  static String get saveButton => _isPt ? 'Salvar' : 'Save';
  static String get dataTab => _isPt ? 'Dados' : 'Data';
  static String get historyTab => _isPt ? 'Histórico' : 'History';
  static String get personalDataTitle => _isPt ? 'Dados Pessoais' : 'Personal Data';
  static String get fullNameLabel => _isPt ? 'Nome Completo' : 'Full Name';
  static String get cpfLabel => _isPt ? 'CPF' : 'Tax ID (CPF)';
  static String get whatsappLabel => _isPt ? 'WhatsApp' : 'WhatsApp';
  static String get cepLabel => _isPt ? 'CEP' : 'Zip Code';
  static String get addressLabel => _isPt ? 'Endereço' : 'Address';
  static String get birthDateLabel => _isPt ? 'Data de Nascimento' : 'Date of Birth';
  static String get anamnesisTitle => _isPt ? 'Ficha de Anamnese' : 'Anamnesis Form';
  static String get medicalHistoryLabel => _isPt ? 'Histórico Médico' : 'Medical History';
  static String get allergiesLabel => _isPt ? 'Alergias' : 'Allergies';
  static String get medicationsLabel => _isPt ? 'Medicamentos' : 'Medications';
  static String get surgeriesLabel => _isPt ? 'Cirurgias' : 'Surgeries';
  static String get deleteAccountButton => _isPt ? 'Excluir Conta' : 'Delete Account';
  static String get deleteAccountDialogTitle => _isPt ? 'Excluir Conta?' : 'Delete Account?';
  static String get deleteAccountDialogContent => _isPt ? 'Tem certeza que deseja excluir sua conta e todos os seus dados? Esta ação não pode ser desfeita.' : 'Are you sure you want to delete your account and all your data? This action cannot be undone.';
  static String get cancelButton => _isPt ? 'Cancelar' : 'Cancel';
  static String get deleteEverythingButton => _isPt ? 'Excluir Tudo' : 'Delete Everything';
  static String get accountDeletedSuccess => _isPt ? 'Conta excluída com sucesso.' : 'Account deleted successfully.';
  static String get profileUpdatedSuccess => _isPt ? 'Perfil atualizado com sucesso!' : 'Profile updated successfully!';
  static String get noAppointmentsFound => _isPt ? 'Nenhum agendamento encontrado.' : 'No appointments found.';
  static String get cancellationReasonLabel => _isPt ? 'Motivo do Cancelamento' : 'Reason for Cancellation';
  static String get confirmCancellationButton => _isPt ? 'Confirmar Cancelamento' : 'Confirm Cancellation';
  static String get requiredField => _isPt ? 'Campo obrigatório' : 'Required field';
}