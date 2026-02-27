class AppStrings {
  // Validators
  static const String dataNascimentoObrigatoria = 'Data de nascimento obrigatória.';
  static String erroIdadeMinima(int idade) => 'É necessário ter pelo menos $idade anos para se cadastrar.';

  // Termos de Uso
  static const String termosUsoTitulo = 'Termos de Uso';
  static const String termosUsoTexto = """
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
""",
    en: """
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
""",
    es: """
1. Aceptación de los Términos
Al utilizar esta aplicación para programar servicios de masoterapia, aceptas los términos descritos a continuación.

2. Programación y Cancelaciones
Las cancelaciones deben realizarse respetando el plazo mínimo configurado en el sistema. Las cancelaciones tardías o la no presentación pueden estar sujetas a restricciones en futuras citas.

3. Salud y Anamnesis
Es responsabilidad del cliente informar condiciones de salud, alergias, cirugías recientes y uso de medicamentos en la ficha de anamnesis. La omisión de datos puede conllevar riesgos para la salud durante el procedimiento.

4. Privacidad y Datos (LGPD)
Tus datos personales se recopilan para fines de registro e historial de servicio. Tienes derecho a solicitar la anonimización de tu cuenta en cualquier momento a través de la configuración del perfil.

5. Pagos
Los precios de los servicios y paquetes están sujetos a cambios. El pago debe realizarse según lo acordado con el profesional.
""",
    jp: """
1. 利用規約の同意
マッサージ療法サービスの予約にこのアプリケーションを使用することで、以下の規約に同意したものとみなされます。

2. 予約とキャンセル
キャンセルは、システムで設定された最低通知期間を守って行う必要があります。遅刻や無断キャンセルは、将来の予約に制限がかかる場合があります。

3. 健康と問診
問診票にて、健康状態、アレルギー、最近の手術、服薬状況を報告することは利用者の責任です。データの漏洩は施術中の健康リスクを招く可能性があります。

4. プライバシーとデータ (GDPR)
個人データは登録およびサービス履歴のために収集されます。プロフィール設定からいつでもアカウントの匿名化をリクエストする権利があります。

5. 支払い
サービスおよびパッケージの価格は変更される場合があります。支払いは専門家との合意に基づいて行われる必要があります。
"""
  );

  static String get termosUsoAceite => _tr(pt: 'Li e concordo com os Termos de Uso e Política de Privacidade.', en: 'I have read and agree to the Terms of Use and Privacy Policy.', es: 'He leído y acepto los Términos de Uso y la Política de Privacidad.', jp: '利用規約とプライバシーポリシーを読み、同意します。');
  static String get termosUsoBotao => _tr(pt: 'Confirmar e Continuar', en: 'Confirm and Continue', es: 'Confirmar y Continuar', jp: '確認して続行');

  // Admin Config
  static String get configTitulo => _tr(pt: 'Configuração de Campos', en: 'Field Configuration', es: 'Configuración de Campos', jp: 'フィールド設定');
  static String get configSalvaSucesso => _tr(pt: 'Configurações salvas com sucesso!', en: 'Settings saved successfully!', es: '¡Configuraciones guardadas con éxito!', jp: '設定が正常に保存されました！');
  static String get configFinanceiro => _tr(pt: 'Financeiro', en: 'Financial', es: 'Financiero', jp: '財務');
  static String get configPrecoSessao => _tr(pt: 'Preço da Sessão (R\$)', en: 'Session Price (R\$)', es: 'Precio de la Sesión (R\$)', jp: 'セッション価格 (R\$)');
  static String get configRegrasCancelamento => _tr(pt: 'Regras de Cancelamento', en: 'Cancellation Rules', es: 'Reglas de Cancelación', jp: 'キャンセルルール');
  static String get configAntecedencia => _tr(pt: 'Antecedência mínima (horas)', en: 'Minimum notice (hours)', es: 'Antelación mínima (horas)', jp: '最低通知時間（時間）');
  static String get configHorarioSono => _tr(pt: 'Horário de Sono da Administradora', en: 'Administrator Sleep Schedule', es: 'Horario de Sueño del Administrador', jp: '管理者の睡眠スケジュール');
  static String get configHorarioSonoDesc => _tr(pt: 'Este intervalo não conta para o cálculo de antecedência.', en: 'This interval does not count towards the notice calculation.', es: 'Este intervalo no cuenta para el cálculo de antelación.', jp: 'この間隔は通知計算には含まれません。');
  static String get configDormeAs => _tr(pt: 'Dorme às', en: 'Sleeps at', es: 'Duerme a las', jp: '就寝時間');
  static String get configAcordaAs => _tr(pt: 'Acorda às', en: 'Wakes up at', es: 'Despierta a las', jp: '起床時間');
  static String get configCupons => _tr(pt: 'Configuração de Cupons', en: 'Coupon Configuration', es: 'Configuración de Cupones', jp: 'クーポン設定');
  static String get configCupomAtivo => _tr(pt: 'Ativo (Campo visível)', en: 'Active (Field visible)', es: 'Activo (Campo visible)', jp: 'アクティブ（フィールド表示）');
  static String get configCupomOculto => _tr(pt: 'Oculto (Campo não aparece)', en: 'Hidden (Field not shown)', es: 'Oculto (Campo no aparece)', jp: '非表示（フィールド非表示）');
  static String get configCupomOpaco => _tr(pt: 'Opacidade (Visível mas inativo)', en: 'Opacity (Visible but inactive)', es: 'Opacidad (Visible pero inactivo)', jp: '不透明度（表示されるが非アクティブ）');
  static String get configCupomOpacoDesc => _tr(pt: 'Aparece com transparência e não clicável', en: 'Appears transparent and not clickable', es: 'Aparece transparente y no clicable', jp: '透明でクリック不可として表示');
  static String get configCamposObrigatorios => _tr(pt: 'Marque os campos que devem ser OBRIGATÓRIOS para o cliente:', en: 'Check the fields that must be MANDATORY for the client:', es: 'Marque los campos que deben ser OBLIGATORIOS para el cliente:', jp: 'クライアントに必須とするフィールドをチェックしてください：');
  static String get configCampoCritico => _tr(pt: 'Campo crítico (Sempre obrigatório)', en: 'Critical field (Always mandatory)', es: 'Campo crítico (Siempre obligatorio)', jp: '重要フィールド（常に必須）');
  static String get configBiometria => _tr(pt: 'Autenticação Biométrica (Login Rápido)', en: 'Biometric Authentication (Quick Login)', es: 'Autenticación Biométrica (Inicio Rápido)', jp: '生体認証（クイックログイン）');
  static String get configBiometriaDesc => _tr(pt: 'Permitir que usuários usem FaceID/TouchID na tela de login.', en: 'Allow users to use FaceID/TouchID on the login screen.', es: 'Permitir a los usuarios usar FaceID/TouchID en la pantalla de inicio de sesión.', jp: 'ログイン画面でFaceID/TouchIDの使用を許可します。');

  static Map<String, String> get labelsConfig => {
    'whatsapp': 'WhatsApp',
    'endereco': _tr(pt: 'Endereço Completo', en: 'Full Address', es: 'Dirección Completa', jp: '完全な住所'),
    'data_nascimento': _tr(pt: 'Data de Nascimento', en: 'Date of Birth', es: 'Fecha de Nacimiento', jp: '生年月日'),
    'historico_medico': _tr(pt: 'Histórico Médico', en: 'Medical History', es: 'Historial Médico', jp: '病歴'),
    'alergias': _tr(pt: 'Alergias', en: 'Allergies', es: 'Alergias', jp: 'アレルギー'),
    'medicamentos': _tr(pt: 'Uso de Medicamentos', en: 'Medication Use', es: 'Uso de Medicamentos', jp: '服薬'),
    'cirurgias': _tr(pt: 'Cirurgias Recentes', en: 'Recent Surgeries', es: 'Cirugías Recientes', jp: '最近の手術'),
    'termos_uso': _tr(pt: 'Termos de Uso (Aceite Obrigatório)', en: 'Terms of Use (Mandatory Acceptance)', es: 'Términos de Uso (Aceptación Obligatoria)', jp: '利用規約（必須同意）'),
  };

  // Login
  static String get loginTitulo => _tr(pt: 'Bem-vindo(a)', en: 'Welcome', es: 'Bienvenido(a)', jp: 'ようこそ');
  static String get loginSubtitulo => _tr(pt: 'Faça login para agendar sua sessão', en: 'Sign in to schedule your session', es: 'Inicia sesión para agendar tu cita', jp: 'セッションを予約するためにログインしてください');
  static String get emailLabel => _tr(pt: 'E-mail', en: 'Email', es: 'Correo electrónico', jp: 'メールアドレス');
  static String get senhaLabel => _tr(pt: 'Senha', en: 'Password', es: 'Contraseña', jp: 'パスワード');
  static String get entrarBtn => _tr(pt: 'Entrar', en: 'Sign In', es: 'Entrar', jp: 'ログイン');
  static String get cadastrarBtn => _tr(pt: 'Criar Conta', en: 'Create Account', es: 'Crear Cuenta', jp: 'アカウント作成');
  static String get esqueceuSenha => _tr(pt: 'Esqueceu a senha?', en: 'Forgot password?', es: '¿Olvidaste tu contraseña?', jp: 'パスワードをお忘れですか？');
  static String get erroEmailObrigatorio => _tr(pt: 'Por favor, digite seu e-mail para recuperar a senha.', en: 'Please enter your email to reset password.', es: 'Por favor, introduce tu correo para restablecer la contraseña.', jp: 'パスワードをリセットするにはメールアドレスを入力してください。');
  static String get emailRecuperacaoEnviado => _tr(pt: 'E-mail de recuperação enviado! Verifique sua caixa de entrada.', en: 'Recovery email sent! Check your inbox.', es: '¡Correo de recuperación enviado! Revisa tu bandeja de entrada.', jp: 'リカバリーメールを送信しました！受信トレイを確認してください。');
  static String get biometriaBtn => _tr(pt: 'Entrar com Biometria', en: 'Login with Biometrics', es: 'Entrar con Biometría', jp: '生体認証でログイン');
  static String get biometriaErro => _tr(pt: 'Não foi possível autenticar.', en: 'Could not authenticate.', es: 'No se pudo autenticar.', jp: '認証できませんでした。');
  static String get biometriaNaoConfigurada => _tr(pt: 'Biometria não configurada no dispositivo.', en: 'Biometrics not configured on device.', es: 'Biometría no configurada en el dispositivo.', jp: 'デバイスに生体認証が設定されていません。');

  // Onboarding
  static String get onboardingTitulo1 => _tr(pt: 'Bem-vindo(a)', en: 'Welcome', es: 'Bienvenido(a)', jp: 'ようこそ');
  static String get onboardingTexto1 => _tr(pt: 'Gerencie seus agendamentos de massoterapia de forma fácil e rápida.', en: 'Manage your massage therapy appointments easily and quickly.', es: 'Gestiona tus citas de masoterapia de forma fácil y rápida.', jp: 'マッサージ療法の予約を簡単かつ迅速に管理します。');
  static String get onboardingTitulo2 => _tr(pt: 'Notificações', en: 'Notifications', es: 'Notificaciones', jp: '通知');
  static String get onboardingTexto2 => _tr(pt: 'Receba lembretes automáticos e atualizações sobre suas sessões.', en: 'Receive automatic reminders and updates about your sessions.', es: 'Recibe recordatorios automáticos y actualizaciones sobre tus sesiones.', jp: 'セッションに関する自動リマインダーと更新を受け取ります。');
  static String get onboardingTitulo3 => _tr(pt: 'Histórico Completo', en: 'Full History', es: 'Historial Completo', jp: '完全な履歴');
  static String get onboardingTexto3 => _tr(pt: 'Acompanhe seu histórico de atendimentos e controle seus pacotes.', en: 'Track your service history and control your packages.', es: 'Sigue tu historial de servicios y controla tus paquetes.', jp: 'サービス履歴を追跡し、パッケージを管理します。');
  static String get pularBtn => _tr(pt: 'Pular', en: 'Skip', es: 'Saltar', jp: 'スキップ');
  static String get comecarBtn => _tr(pt: 'Começar', en: 'Get Started', es: 'Comenzar', jp: '始める');
  static String get googleLoginBtn => _tr(pt: 'Entrar com Google', en: 'Sign in with Google', es: 'Entrar con Google', jp: 'Googleでログイン');
}