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
""";
  static const String termosUsoAceite = 'Li e concordo com os Termos de Uso e Política de Privacidade.';
  static const String termosUsoBotao = 'Confirmar e Continuar';

  // Admin Config
  static const String configTitulo = 'Configuração de Campos';
  static const String configSalvaSucesso = 'Configurações salvas com sucesso!';
  static const String configFinanceiro = 'Financeiro';
  static const String configPrecoSessao = 'Preço da Sessão (R\$)';
  static const String configRegrasCancelamento = 'Regras de Cancelamento';
  static const String configAntecedencia = 'Antecedência mínima (horas)';
  static const String configHorarioSono = 'Horário de Sono da Administradora';
  static const String configHorarioSonoDesc = 'Este intervalo não conta para o cálculo de antecedência.';
  static const String configDormeAs = 'Dorme às';
  static const String configAcordaAs = 'Acorda às';
  static const String configCupons = 'Configuração de Cupons';
  static const String configCupomAtivo = 'Ativo (Campo visível)';
  static const String configCupomOculto = 'Oculto (Campo não aparece)';
  static const String configCupomOpaco = 'Opacidade (Visível mas inativo)';
  static const String configCupomOpacoDesc = 'Aparece com transparência e não clicável';
  static const String configCamposObrigatorios = 'Marque os campos que devem ser OBRIGATÓRIOS para o cliente:';
  static const String configCampoCritico = 'Campo crítico (Sempre obrigatório)';

  static const Map<String, String> labelsConfig = {
    'whatsapp': 'WhatsApp',
    'endereco': 'Endereço Completo',
    'data_nascimento': 'Data de Nascimento',
    'historico_medico': 'Histórico Médico',
    'alergias': 'Alergias',
    'medicamentos': 'Uso de Medicamentos',
    'cirurgias': 'Cirurgias Recentes',
    'termos_uso': 'Termos de Uso (Aceite Obrigatório)',
  };
}