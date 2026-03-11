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
  static String get backupAgendaMassoterapia => _isPt ? 'Backup Agenda Massoterapia' : 'Massage Therapy Agenda Backup';
  static String get novaSenha => _isPt ? 'Nova Senha' : 'New Password';
  static String get confirmeSenha => _isPt ? 'Confirme a Senha' : 'Confirm Password';
  static String get senhaObrigatoria => _isPt ? 'Senha obrigatória' : 'Password is required';
  static String get minimoSeisCaracteres => _isPt ? 'Mínimo 6 caracteres' : 'Minimum 6 characters';
  static String get senhasNaoCoincidem => _isPt ? 'As senhas não coincidem' : 'Passwords do not match';
  static String get configEstadoCampoCupom => _isPt ? 'Estado do Campo Cupom' : 'Coupon Field State';
  static String get senhaAcessoDevTools => _isPt ? 'Senha de Acesso a DevTools' : 'DevTools Access Password';
  static String get senhaProtegeDevTools => _isPt ? 'Esta senha protege o acesso a ferramentas perigosas como DevTools.' : 'This password protects access to dangerous tools such as DevTools.';
  static String get naoConfigurada => _isPt ? 'Não configurada' : 'Not configured';
  static String get configurar => _isPt ? 'Configurar' : 'Configure';

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
  static String get digiteEmailCadastrado => _isPt ? 'Digite seu e-mail cadastrado' : 'Enter your registered email';
  static String get avisoRecuperacaoSenha => _isPt
    ? 'Se este for seu e-mail e tiver cadastro, enviaremos um link para recuperação.'
    : 'If this is your email and it is registered, we will send a recovery link.';
  static String get confirmarRecuperacaoSenha => _isPt ? 'Confirmar recuperação' : 'Confirm recovery';
  static String tentativasExcedidas(String acao, int segundos) => _isPt
    ? 'Muitas tentativas de $acao. Aguarde $segundos segundos para tentar novamente.'
    : 'Too many $acao attempts. Wait $segundos seconds before trying again.';
  static String get acaoLogin => _isPt ? 'login' : 'login';
  static String get acaoRecuperacaoSenha => _isPt ? 'recuperação de senha' : 'password recovery';
  static String get erroEmailObrigatorio => _isPt ? 'Por favor, digite seu e-mail para recuperar a senha.' : 'Please enter your email to reset password.';
  static String get emailRecuperacaoEnviado => _isPt ? 'E-mail de recuperação enviado! Verifique sua caixa de entrada.' : 'Recovery email sent! Check your inbox.';
  static String emailRedefinicaoEnviadoPara(String email) => _isPt ? 'Email de redefinição enviado para $email' : 'Password reset email sent to $email';
  static String get cadastroUsuarioNaoEncontrado => _isPt ? 'Cadastro de usuário não encontrado.' : 'User record not found.';
  static String erroLoginComDetalhe(String? erro) => _isPt ? 'Erro de login: ${erro ?? 'desconhecido'}' : 'Login error: ${erro ?? 'unknown'}';
  static String erroCadastroComDetalhe(String erro) => _isPt ? 'Erro ao cadastrar: $erro' : 'Registration error: $erro';
  static String get erroCadastroAppCheck => _isPt
    ? 'Erro de segurança do Firebase no cadastro. Em ambiente local web, registre o token de debug do App Check e tente novamente.'
    : 'Firebase security error during registration. In local web development, register the App Check debug token and try again.';
  static String get biometriaBtn => _isPt ? 'Entrar com Biometria' : 'Login with Biometrics';
  static String get biometriaErro => _isPt ? 'Erro na autenticação biométrica' : 'Biometric authentication error';

  // Onboarding
  static String get onboardingTitulo1 => _isPt ? 'Bem-vindo(a)' : 'Welcome';
  static String get onboardingTexto1 => _isPt ? 'Gerencie seus agendamentos de massoterapia de forma fácil e rápida.' : 'Manage your massage therapy appointments easily and quickly.';
  static String get onboardingTitulo2 => _isPt ? 'Notificações' : 'Notifications';
  static String get onboardingTexto2 => _isPt ? 'Receba lembretes automáticos e atualizações sobre suas sessões.' : 'Receive automatic reminders and updates about your sessions.';
  static String get onboardingTitulo3 => _isPt ? 'Histórico Completo' : 'Full History';
  static String get onboardingTexto3 => _isPt ? 'Acompanhe seu histórico de atendimentos e controle seus pacotes.' : 'Track your service history and control your packages.';
  static String get onboardingArrasteAvancar => _isPt ? 'Arraste para a esquerda para avançar' : 'Swipe left to continue';
  static String get onboardingArrasteVoltar => _isPt ? 'Arraste para a direita para voltar' : 'Swipe right to go back';
  static String get onboardingArrasteAmbos => _isPt ? 'Arraste para os lados para navegar' : 'Swipe both ways to navigate';
  static String onboardingDicaArraste(int paginaAtual, int totalPaginas) {
    if (totalPaginas <= 1) return '';
    if (paginaAtual <= 0) return onboardingArrasteAvancar;
    if (paginaAtual >= totalPaginas - 1) return onboardingArrasteVoltar;
    return onboardingArrasteAmbos;
  }
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
  static String get birthDateNotInformed => _isPt ? 'Não informada' : 'Not informed';
  static String get birthDateRequired => _isPt ? 'Por favor, informe a Data de Nascimento.' : 'Please inform the Date of Birth.';
  static String get saveProfile => _isPt ? 'SALVAR PERFIL' : 'SAVE PROFILE';
  static String get deleteMyAccount => _isPt ? 'EXCLUIR MINHA CONTA' : 'DELETE MY ACCOUNT';
  static String get loginAgainToDelete => _isPt ? 'Por segurança, faça login novamente para excluir a conta.' : 'For security, please log in again to delete your account.';
  static String get invalidCep => _isPt ? 'Por favor, digite um CEP válido com 8 números.' : 'Please enter a valid ZIP code with 8 digits.';
  static String get cepNotFound => _isPt ? 'CEP não encontrado. Por favor, digite o endereço manualmente.' : 'ZIP code not found. Please enter the address manually.';
  static String get cepError => _isPt ? 'Erro ao buscar CEP. Verifique sua conexão ou digite manualmente.' : 'Error fetching ZIP code. Check your connection or enter manually.';

  // Agendamento - Estoque
  static String get estoqueControle => _isPt ? 'Controle de Estoque' : 'Inventory Control';
  static String get estoqueVazio => _isPt ? 'Nenhum item no estoque.' : 'No items in stock.';
  static String get estoqueBaixaAuto => _isPt ? 'Baixa automática por sessão' : 'Auto-deduction per session';
  static String get estoqueControleManual => _isPt ? 'Controle manual' : 'Manual control';
  static String get estoqueNovoItem => _isPt ? 'Novo Item' : 'New Item';
  static String get estoqueEditarItem => _isPt ? 'Editar Item' : 'Edit Item';
  static String get estoqueNomeProduto => _isPt ? 'Nome do Produto' : 'Product Name';
  static String get estoqueQuantidade => _isPt ? 'Quantidade (Doses/Unidades)' : 'Quantity (Doses/Units)';
  static String get estoqueBaixaAutomatica => _isPt ? 'Baixa Automática' : 'Auto Deduction';
  static String get estoqueDescontarAprovacao => _isPt ? 'Descontar ao aprovar agendamento?' : 'Deduct on appointment approval?';

  // Agendamento - Geral
  static List<String> get dicasMassagem => _isPt
    ? [
        'Beba bastante água após a massagem para ajudar a eliminar toxinas.',
        'Evite refeições pesadas pelo menos 1 hora antes da sua sessão.',
        'Chegue 5 minutos antes para relaxar e aproveitar melhor seu tempo.',
        'Alongamentos leves diários ajudam a prolongar os efeitos da massagem.',
        'Informe sempre se houver alguma dor nova ou desconforto recente.'
      ]
    : [
        'Drink plenty of water after massage to help flush toxins.',
        'Avoid heavy meals at least 1 hour before your session.',
        'Arrive 5 minutes early to relax and enjoy your time better.',
        'Light daily stretching helps prolong massage benefits.',
        'Always report any new pain or recent discomfort.'
      ];
  static String get favoritos => _isPt ? 'Favoritos:' : 'Favorites:';
  static String get selecioneTipo => _isPt ? 'Selecione o Tipo' : 'Select Type';
  static String get adicionarFavoritos => _isPt ? 'Adicionar aos favoritos' : 'Add to favorites';
  static String get removerFavoritos => _isPt ? 'Remover dos favoritos' : 'Remove from favorites';
  static String descontoResumo(String valor) => _isPt ? 'Desconto: $valor' : 'Discount: $valor';
  static String dataResumo(String data) => _isPt ? 'Data: $data' : 'Date: $data';
  static String horarioResumo(String horario) => _isPt ? 'Horário: $horario' : 'Time: $horario';
  static String valorResumo(String valor) => _isPt ? 'Valor: $valor' : 'Amount: $valor';
  static String cupomResumo(String cupom) => _isPt ? 'Cupom: $cupom' : 'Coupon: $cupom';
  static String filaEsperaResumo(int quantidade) => _isPt ? '$quantidade pessoas na fila de espera' : '$quantidade people in waitlist';
  static String tipoStatusResumo(String tipo, String status, String motivoTexto) => _isPt
    ? 'Tipo: $tipo\nStatus: $status$motivoTexto'
    : 'Type: $tipo\nStatus: $status$motivoTexto';
  static String motivoInline(String motivo) => _isPt ? '\nMotivo: $motivo' : '\nReason: $motivo';
  static String get fazerCheckIn => _isPt ? 'Fazer Check-in' : 'Check in';
  static String get avaliarAtendimento => _isPt ? 'Avaliar Atendimento' : 'Rate Service';
  static String get buscarPorTipo => _isPt ? 'Buscar por tipo...' : 'Search by type...';
  static String get cupomDesconto => _isPt ? 'Cupom de Desconto' : 'Discount Coupon';
  static String get cupomAplicado => _isPt ? 'Cupom aplicado!' : 'Coupon applied!';
  static String get cupomInvalido => _isPt ? 'Cupom inválido ou expirado.' : 'Invalid or expired coupon.';
  static String get avaliarSessao => _isPt ? 'Avaliar Sessão' : 'Rate Session';
  static String get comoFoiExperiencia => _isPt ? 'Como foi sua experiência?' : 'How was your experience?';
  static String get deixeComentario => _isPt ? 'Deixe um comentário (opcional)' : 'Leave a comment (optional)';
  static String get obrigadoAvaliacao => _isPt ? 'Obrigado pela avaliação!' : 'Thanks for your rating!';
  static String get enviar => _isPt ? 'Enviar' : 'Send';
  static String get erroUsuarioNaoAutenticado => _isPt ? 'Erro: Usuário não autenticado.' : 'Error: User not authenticated.';
  static String get naoPodeCancelarPassado => _isPt ? 'Não é possível cancelar agendamentos passados.' : 'Cannot cancel past appointments.';
  static String get cancelamentoTardio => _isPt ? 'Cancelamento Tardio' : 'Late Cancellation';
  static String get cancelarAgendamento => _isPt ? 'Cancelar Agendamento' : 'Cancel Appointment';
  static String get informeMotivoCancelamento => _isPt ? 'Por favor, informe o motivo do cancelamento:' : 'Please inform the reason for cancellation:';
  static String get exemploMotivo => _isPt ? 'Ex: Imprevisto de saúde' : 'E.g.: Health emergency';
  static String get voltar => _isPt ? 'Voltar' : 'Back';
  static String get detalhesAgendamento => _isPt ? 'Detalhes do Agendamento' : 'Appointment Details';
  static String get motivoCancelamento => _isPt ? 'Motivo do Cancelamento:' : 'Cancellation Reason:';

  // Admin Agendamentos
  static String get administracao => _isPt ? 'Administração' : 'Administration';
  static String get relatorios => _isPt ? 'Relatórios' : 'Reports';
  static String get configuracoes => _isPt ? 'Configurações' : 'Settings';
  static String get devToolsDb => _isPt ? 'Dev Tools (DB)' : 'Dev Tools (DB)';
  static String get dash => _isPt ? 'Dash' : 'Dash';
  static String get agenda => _isPt ? 'Agenda' : 'Schedule';
  static String get clientes => _isPt ? 'Clientes' : 'Clients';
  static String get pendentes => _isPt ? 'Pendentes' : 'Pending';
  static String get agendamentosDia => _isPt ? 'Agendamentos (Dia)' : 'Appointments (Day)';
  static String get receitaEstimadaMes => _isPt ? 'Receita Est. (Mês)' : 'Est. Revenue (Month)';
  static String get aprovados => _isPt ? 'Aprovados' : 'Approved';
  static String get cancelRec => _isPt ? 'Cancel/Rec' : 'Cancel/Rej';
  static String get hoje => _isPt ? 'Hoje' : 'Today';
  static String get semana => _isPt ? 'Semana' : 'Week';
  static String get statusDoDia => _isPt ? 'Status do Dia' : 'Daily Status';
  static String get taxaCancelamento => _isPt ? 'Taxa de Cancelamento' : 'Cancellation Rate';
  static String get mes => _isPt ? 'Mês' : 'Month';
  static String get tiposMaisAgendados => _isPt ? 'Tipos Mais Agendados (Mês)' : 'Most Scheduled Types (Month)';
  static String get semDadosGrafico => _isPt ? 'Sem dados para gráfico.' : 'No data for chart.';
  static String get ativarGravacaoHistorico => _isPt ? 'Dev: Ativar Gravação de Histórico' : 'Dev: Enable History Logging';
  static String get permiteSalvarMetricas => _isPt ? 'Permite salvar as métricas de hoje no banco de dados.' : 'Allows saving today\'s metrics to the database.';
  static String get gravarSnapshot => _isPt ? 'Gravar Snapshot do Dia (metricas_diarias)' : 'Save Daily Snapshot (daily_metrics)';
  static String get metricasSalvasSucesso => _isPt ? 'Métricas do dia salvas com sucesso!' : 'Daily metrics saved successfully!';
  static String erroSalvarMetricas(String erro) => _isPt ? 'Erro ao salvar métricas: $erro' : 'Error saving metrics: $erro';
  static String get nenhumAgendamentoPendente => _isPt ? 'Nenhum agendamento pendente.' : 'No pending appointments.';
  static String get nenhumUsuarioPendente => _isPt ? 'Nenhum usuário pendente.' : 'No pending users.';
  static String get pesquisarCliente => _isPt ? 'Pesquisar Cliente' : 'Search Client';
  static String get nenhumClienteEncontrado => _isPt ? 'Nenhum cliente encontrado.' : 'No clients found.';
  static String saldoSessoesLabel(int saldo) => _isPt ? 'Saldo de Sessões: $saldo' : 'Session Balance: $saldo';
  static String emailCadastroLabel(String email, String dataCadastro) => _isPt
    ? 'Email: $email\nCadastrado em: $dataCadastro'
    : 'Email: $email\nRegistered on: $dataCadastro';
  static String get aprovarCadastro => _isPt ? 'Aprovar Cadastro' : 'Approve Registration';
  static String get permitirVerTodosHorarios => _isPt ? 'Permitir ver todos os horários' : 'Allow viewing all times';
  static String get alterarTemaUsuario => _isPt ? 'Alterar Tema do Usuário' : 'Change User Theme';
  static String resumoClienteTipo(String clienteId, String tipo) => _isPt
    ? 'Cliente: $clienteId\nTipo: $tipo'
    : 'Client: $clienteId\nType: $tipo';
  static String esperaLabel(int quantidade) => _isPt ? 'Espera: $quantidade' : 'Waitlist: $quantidade';
  static String get aprovar => _isPt ? 'Aprovar' : 'Approve';
  static String get recusar => _isPt ? 'Recusar' : 'Reject';
  static String get pacote => _isPt ? 'Pacote' : 'Package';
  static String temaDe(String nome) => _isPt ? 'Tema de $nome' : '$nome\'s Theme';
  static String temaAlteradoPara(String labelTema) => _isPt ? 'Tema alterado para $labelTema' : 'Theme changed to $labelTema';
  static String pacoteAdicionadoPara(String nome) => _isPt ? 'Pacote de 10 sessões adicionado para $nome!' : '10-session package added for $nome!';
  static String agendamentoStatusSucesso(String status) => _isPt ? 'Agendamento $status com sucesso!' : 'Appointment $status successfully!';
  static String usuarioAprovadoSucesso(String nome) => _isPt ? 'Usuário $nome aprovado com sucesso!' : 'User $nome approved successfully!';

  // Chat Agendamento
  static String erroEnvio(String erro) => _isPt ? 'Erro no envio: $erro' : 'Send error: $erro';
  static String get galeriaImagens => _isPt ? 'Galeria de Imagens' : 'Image Gallery';
  static String get arquivoAudio => _isPt ? 'Arquivo de Áudio' : 'Audio File';

  // Admin - Senha Setup
  static String get senhaAdminConfigurada => _isPt ? 'Senha de admin configurada com sucesso!' : 'Admin password configured successfully!';
  static String erroSalvarSenha(String erro) => _isPt ? 'Erro ao salvar senha: $erro' : 'Error saving password: $erro';
  static String get configuracaoInicial => _isPt ? 'Configuração Inicial' : 'Initial Setup';
  static String get salvarContinuar => _isPt ? 'Salvar e Continuar' : 'Save and Continue';
  static String get verificandoConfiguracao => _isPt ? 'Verificando configuração...' : 'Checking configuration...';
  static String get cliqueLogoConfigurar => _isPt ? 'Clique no logo para configurar' : 'Click the logo to configure';
  static String get configureSenhaAdmin => _isPt ? 'Configure a Senha de Admin' : 'Configure Admin Password';
  static String get senhaAdminDescricao => _isPt ? 'Esta senha será usada para acessar ferramentas administrativas perigosas como DevTools e operações diretas no banco de dados.' : 'This password will be used to access dangerous administrative tools such as DevTools and direct database operations.';
  static String get senhaAdminLabel => _isPt ? 'Senha de Admin' : 'Admin Password';
  static String get guardeSenhaLocalSeguro => _isPt ? 'Guarde esta senha em local seguro. Ela será necessária para operações críticas.' : 'Keep this password in a safe place. It will be required for critical operations.';

  // Admin - Ferramentas Senha Setup
  static String get senhaConfiguradaSucesso => _isPt ? 'Senha configurada com sucesso!' : 'Password configured successfully!';
  static String get configuracaoFerramentas => _isPt ? 'Configuração de Ferramentas' : 'Tools Configuration';
  static String get databaseSetup => _isPt ? 'Database Setup' : 'Database Setup';
  static String get alterarSenha => _isPt ? 'Alterar Senha' : 'Change Password';
  static String get salvar => _isPt ? 'Salvar' : 'Save';

  // Admin - Database Setup
  static String erroCarregar(String erro) => _isPt ? 'Erro ao carregar: $erro' : 'Error loading: $erro';
  static String get alteracoesSalvasSucesso => _isPt ? 'Alterações salvas com sucesso!' : 'Changes saved successfully!';
  static String erroSalvar(String erro) => _isPt ? 'Erro ao salvar: $erro' : 'Error saving: $erro';
  static String get ferramentasDatabaseSetup => _isPt ? 'Ferramentas - Database Setup' : 'Tools - Database Setup';
  static String get salvarAlteracoes => _isPt ? 'Salvar Alterações' : 'Save Changes';

  // Admin - Config
  static String erroExportar(String erro) => _isPt ? 'Erro ao exportar: $erro' : 'Error exporting: $erro';
  static String get backupRestauradoSucesso => _isPt ? 'Backup restaurado com sucesso!' : 'Backup restored successfully!';
  static String erroImportar(String erro) => _isPt ? 'Erro ao importar: $erro' : 'Error importing: $erro';
  static String get configurarSenhaAdmin => _isPt ? 'Configurar Senha Admin' : 'Configure Admin Password';
  static String get alterarSenhaAdmin => _isPt ? 'Alterar Senha Admin' : 'Change Admin Password';
  static String get senhaSalvaSucesso => _isPt ? 'Senha salva com sucesso!' : 'Password saved successfully!';
  static String get segurancaSenhaAdmin => _isPt ? 'Segurança - Senha Admin' : 'Security - Admin Password';
  static String get ativarBiometria => _isPt ? 'Ativar FaceID/TouchID' : 'Enable FaceID/TouchID';
  static String get exibirIconesLido => _isPt ? 'Exibir ícones de "Lido" nas mensagens' : 'Show "Read" icons in messages';

  // Admin - Relatórios
  static String get relatoriosGerenciais => _isPt ? 'Relatórios Gerenciais' : 'Management Reports';
  static String get semDadosMes => _isPt ? 'Sem dados para este mês.' : 'No data for this month.';
  static String get detalhamentoCancelamentos => _isPt ? 'Detalhamento de Cancelamentos' : 'Cancellation Details';
  static String get tardio => _isPt ? 'Tardio' : 'Late';
  static String get normal => _isPt ? 'Normal' : 'Normal';
  static String get gerandoPdf => _isPt ? 'Gerando PDF...' : 'Generating PDF...';
  static String get relatorioMensalTitulo => _isPt ? 'Relatório Mensal - Agenda Massoterapia' : 'Monthly Report - Massage Therapy Agenda';
  static String get resumoFinanceiro => _isPt ? 'Resumo Financeiro' : 'Financial Summary';
  static String totalAgendamentos(int total) => _isPt ? 'Total de Agendamentos: $total' : 'Total Appointments: $total';
  static String sessoesRealizadas(int total) => _isPt ? 'Sessões Realizadas/Aprovadas: $total' : 'Sessions Completed/Approved: $total';
  static String receitaBruta(String valor) => _isPt ? 'Receita Bruta Estimada: $valor' : 'Estimated Gross Revenue: $valor';
  static String get detalhamento => _isPt ? 'Detalhamento' : 'Details';
  static String erroGerarPdf(String erro) => _isPt ? 'Erro ao gerar PDF: $erro' : 'Error generating PDF: $erro';

  // Admin - Logs
  static String get logsSistema => _isPt ? 'Logs do Sistema' : 'System Logs';
  static String get nenhumLogEncontrado => _isPt ? 'Nenhum log encontrado.' : 'No logs found.';
  static String get segurancaAuth => _isPt ? 'Segurança Auth' : 'Auth Security';
  static String get filtroTodos => _isPt ? 'Todos' : 'All';
  static String get filtroCancelamento => _isPt ? 'Cancelamento' : 'Cancellation';
  static String get filtroAprovacao => _isPt ? 'Aprovação' : 'Approval';
  static String get filtroEspera => _isPt ? 'Espera' : 'Waitlist';
  static String get filtroSistema => _isPt ? 'Sistema' : 'System';
  static String get emailCampo => _isPt ? 'E-mail' : 'Email';
  static String get acaoCampo => _isPt ? 'Ação' : 'Action';
  static String get tentativasCampo => _isPt ? 'Tentativas' : 'Attempts';
  static String get motivoCampo => _isPt ? 'Motivo' : 'Reason';
  static String get desbloqueioCampo => _isPt ? 'Desbloqueio' : 'Unlock time';
  static String get naoInformado => _isPt ? 'Não informado' : 'Not informed';
  static String acaoSegurancaLabel(String acao) {
    switch (acao) {
      case 'login':
        return _isPt ? 'Login' : 'Login';
      case 'esqueceu_senha':
        return _isPt ? 'Esqueceu a senha' : 'Forgot password';
      default:
        return acao;
    }
  }
  static String get sistema => _isPt ? 'Sistema' : 'System';
  static String usuarioLog(String usuarioId) => _isPt ? 'Usuário: $usuarioId' : 'User: $usuarioId';

  // Admin - LGPD Logs
  static String get auditoriaLgpd => _isPt ? 'Auditoria LGPD' : 'LGPD Audit';
  static String get nenhumRegistroLgpd => _isPt ? 'Nenhum registro de auditoria LGPD encontrado.' : 'No LGPD audit records found.';
  static String get acaoDesconhecida => _isPt ? 'Ação Desconhecida' : 'Unknown Action';
  static String get dataDesconhecida => _isPt ? 'Data desconhecida' : 'Unknown date';
  static String resumoLogLgpd(String data, String usuarioId, String motivo) => _isPt
    ? 'Data: $data\nID Usuário: $usuarioId\nMotivo: $motivo'
    : 'Date: $data\nUser ID: $usuarioId\nReason: $motivo';

  // Financeiro
  static String get semDadosFinanceiros => _isPt ? 'Sem dados financeiros.' : 'No financial data.';
  static String get selecioneCliente => _isPt ? 'Selecione um cliente' : 'Select a client';
  static String get transacaoRegistradaSucesso => _isPt ? 'Transação registrada com sucesso!' : 'Transaction registered successfully!';
  static String erro(String erro) => _isPt ? 'Erro: $erro' : 'Error: $erro';
  static String get novaTransacao => _isPt ? 'Nova Transação' : 'New Transaction';
  static String get clienteLabel => _isPt ? 'Cliente' : 'Client';
  static String get valorBrutoLabel => _isPt ? 'Valor Bruto (R\$)' : 'Gross Amount (R\$)';
  static String get descontoLabel => _isPt ? 'Desconto (R\$)' : 'Discount (R\$)';
  static String get valorLiquidoLabel => _isPt ? 'Valor Líquido (R\$)' : 'Net Amount (R\$)';
  static String get metodoPagamentoLabel => _isPt ? 'Método de Pagamento' : 'Payment Method';
  static String get statusLabel => _isPt ? 'Status' : 'Status';
  static String dataPagamentoLabel(String data) => _isPt ? 'Data do Pagamento: $data' : 'Payment Date: $data';
  static String get pix => _isPt ? 'Pix' : 'Pix';
  static String get dinheiro => _isPt ? 'Dinheiro' : 'Cash';
  static String get cartao => _isPt ? 'Cartão' : 'Card';
  static String get pendente => _isPt ? 'Pendente' : 'Pending';
  static String get pago => _isPt ? 'Pago' : 'Paid';
  static String get estornado => _isPt ? 'Estornado' : 'Refunded';
  static String get registrarTransacao => _isPt ? 'Registrar Transação' : 'Register Transaction';

  // Dashboard
  static String get acessoNegado => _isPt ? 'Acesso negado.' : 'Access denied.';
  static String get dashboardAdministrativo => _isPt ? 'Dashboard Administrativo' : 'Administrative Dashboard';
  static String get resumoDoDia => _isPt ? 'Resumo do Dia' : 'Daily Summary';
  static String get estoqueBaixo => _isPt ? 'Estoque Baixo' : 'Low Stock';
  static String get estoqueEmDia => _isPt ? 'Estoque em dia!' : 'Stock is up to date!';
  static String restamApenas(int quantidade) => _isPt ? 'Restam apenas $quantidade unidades' : 'Only $quantidade units remaining';
  static String get desativarManutencao => _isPt ? 'Desativar Manutenção' : 'Disable Maintenance';
  static String get ativarManutencao => _isPt ? 'Ativar Manutenção' : 'Enable Maintenance';
  static String get nenhumDadoExportar => _isPt ? 'Nenhum dado para exportar.' : 'No data to export.';
  static String get ativarModoManutencao => _isPt ? 'Ativar Modo Manutenção?' : 'Enable Maintenance Mode?';
  static String get desativarModoManutencao => _isPt ? 'Desativar Modo Manutenção?' : 'Disable Maintenance Mode?';
  static String get confirmar => _isPt ? 'Confirmar' : 'Confirm';

  // Dev Tools
  static String get reinicieApp => _isPt ? 'Reinicie o app para aplicar a alteração.' : 'Restart the app to apply the change.';
  static String get naoValidarSenhaCollection => _isPt ? 'Nao foi possivel validar a senha da collection.' : 'Could not validate collection password.';
  static String get senhaCollectionIncorreta => _isPt ? 'Senha da collection incorreta.' : 'Incorrect collection password.';
  static String get senhaDevIncorreta => _isPt ? 'Senha dev incorreta.' : 'Incorrect dev password.';
  static String semScriptSeed(String collection) => _isPt ? 'Sem script de seed para $collection' : 'No seed script for $collection';
  static String tabelaPopulada(String collection) => _isPt ? 'Tabela $collection populada (Merge/Ignore se existe).' : 'Table $collection populated (Merge/Ignore if exists).';
  static String truncateTable(String collection) => _isPt ? 'TRUNCATE TABLE $collection?' : 'TRUNCATE TABLE $collection?';
  static String truncateConfirmacao(String collection) => _isPt 
    ? 'Tem certeza que deseja apagar TODOS os dados de $collection? Esta ação é irreversível.' 
    : 'Are you sure you want to delete ALL data from $collection? This action is irreversible.';
  static String get apagarTudo => _isPt ? 'APAGAR TUDO' : 'DELETE EVERYTHING';
  static String collectionLimpa(String collection) => _isPt ? 'Collection $collection limpa com sucesso.' : 'Collection $collection cleared successfully.';
  static String get gerandoArquivo => _isPt ? 'Gerando arquivo...' : 'Generating file...';
  static String get colecaoVazia => _isPt ? 'Coleção vazia.' : 'Empty collection.';
  static String get excelApenasAgendamentos => _isPt ? 'Excel disponível apenas para Agendamentos.' : 'Excel available only for Appointments.';
  static String get enviandoParaJsonBin => _isPt ? 'Enviando para JSONBin...' : 'Uploading to JSONBin...';
  static String get exportacaoConcluida => _isPt ? 'Exportação Concluída ☁️' : 'Export Completed ☁️';
  static String get dadosSalvosNuvem => _isPt ? 'Dados salvos na nuvem com sucesso!' : 'Data saved to cloud successfully!';
  static String binId(String id) => _isPt ? 'Bin ID: $id' : 'Bin ID: $id';
  static String get urlApi => _isPt ? 'URL API:' : 'API URL:';
  static String get copiarUrl => _isPt ? 'Copiar URL' : 'Copy URL';
  static String get urlCopiada => _isPt ? 'URL copiada!' : 'URL copied!';
  static String get fechar => _isPt ? 'Fechar' : 'Close';
  static String erroExportarWeb(String erro) => _isPt ? 'Erro ao exportar para web: $erro' : 'Error exporting to web: $erro';

  // Widgets compartilhados
  static String get alterarTemaTooltip => _isPt ? 'Alterar Tema' : 'Change Theme';
  static String get escolherTema => _isPt ? 'Escolher Tema' : 'Choose Theme';
  static String get preVisualizacao => _isPt ? 'Pré-visualização' : 'Preview';
  static String get selecioneUmTema => _isPt ? 'Selecione um tema' : 'Select a theme';
  static String temaBloqueado(String label) => _isPt ? '$label (Bloqueado)' : '$label (Locked)';
  static String get aplicar => _isPt ? 'Aplicar' : 'Apply';
  static String get dispararLembretes => _isPt ? 'Disparar Lembretes 🔔' : 'Send Reminders 🔔';
  static String get confirmarDisparoLembretes => _isPt ? 'Deseja enviar notificações para agendamentos próximos?' : 'Do you want to send notifications for upcoming appointments?';
  static String get horasAntecedencia => _isPt ? 'Horas de antecedência' : 'Hours in advance';
  static String get horasUnidade => _isPt ? 'horas' : 'hours';
  static String get enviarLembretesManuais => _isPt ? 'Enviar Lembretes Manuais' : 'Send Manual Reminders';
  static String get processoConcluido => _isPt ? 'Processo concluído!' : 'Process completed!';
  static String erroAoDisparar(String erro) => _isPt ? 'Erro ao disparar: $erro' : 'Error sending reminders: $erro';
  static String get tooltipAlterarIdioma => _isPt ? 'Alterar Idioma / Change Language' : 'Change Language / Alterar Idioma';
  static String get idiomaPortugues => _isPt ? '🇧🇷 Português (Brasileiro)' : '🇧🇷 Portuguese (Brazilian)';
  static String get idiomaIngles => _isPt ? '🇺🇸 Inglês (English)' : '🇺🇸 English';
  static String get idiomaEspanhol => _isPt ? '🇪🇸 Espanhol (Español)' : '🇪🇸 Spanish (Español)';
  static String get idiomaJapones => _isPt ? '🇯🇵 Japonês (日本語)' : '🇯🇵 Japanese (日本語)';

  // Login/Auth
  static String get erroLogin => _isPt ? 'Erro ao fazer login' : 'Login error';
  static String get erroCadastro => _isPt ? 'Erro ao cadastrar' : 'Registration error';
  static String erroGoogleLogin(String erro) => _isPt ? 'Erro no Google Login: $erro' : 'Google Login error: $erro';
  static String get biometriaLoginMsg => _isPt ? 'Faça login com senha uma vez para habilitar o acesso rápido.' : 'Log in with password once to enable quick access.';

  // Geral
  static String erroGenerico(String erro) => _isPt ? 'Erro: $erro' : 'Error: $erro';
  static String get administracaoAgendamentos => _isPt ? 'Administração de Agendamentos' : 'Appointment Administration';
  static String get telaAdministracao => _isPt ? 'Tela de Administração' : 'Administration Screen';
}