class ConfigModel {
  final Map<String, bool> camposObrigatorios;
  final double horasAntecedenciaCancelamento;
  final int inicioSono; // Hora inteira (0-23)
  final int fimSono; // Hora inteira (0-23)
  final double precoSessao;
  final bool biometriaAtiva;
  final bool chatAtivo;
  final int statusCampoCupom;
  final bool reciboLeitura;
  final bool mensagensAleatoriasAtivas;
  final int intervaloMensagensDias;
  final bool usarNomePreferidoNasMensagens;
  final bool enviarMensagensSemAgendamento;
  final List<String> mensagensAleatoriasClientes;
  final int indiceMensagemSelecionadaClientes;

  ConfigModel({
    required this.camposObrigatorios,
    this.horasAntecedenciaCancelamento = 24.0,
    this.inicioSono = 22, // 22:00
    this.fimSono = 6, // 06:00
    this.precoSessao = 100.0,
    this.biometriaAtiva = true,
    this.statusCampoCupom = 1,
    this.chatAtivo = true,
    this.reciboLeitura = true,
    this.mensagensAleatoriasAtivas = false,
    this.intervaloMensagensDias = 7,
    this.usarNomePreferidoNasMensagens = true,
    this.enviarMensagensSemAgendamento = false,
    this.indiceMensagemSelecionadaClientes = -1,
    List<String>? mensagensAleatoriasClientes,
  }) : mensagensAleatoriasClientes =
           (mensagensAleatoriasClientes != null &&
               mensagensAleatoriasClientes.isNotEmpty)
           ? mensagensAleatoriasClientes
           : const <String>[];

  // Campos padrão do sistema
  static Map<String, bool> get padrao => {
    'whatsapp': true,
    'endereco': false,
    'data_nascimento': true,
    'historico_medico': false,
    'alergias': false,
    'medicamentos': false,
    'cirurgias': false,
    'termos_uso': true,
  };

  Map<String, dynamic> toMap() {
    return {
      'campos_obrigatorios': camposObrigatorios,
      'horas_antecedencia_cancelamento': horasAntecedenciaCancelamento,
      'inicio_sono': inicioSono,
      'fim_sono': fimSono,
      'preco_sessao': precoSessao,
      'biometria_ativa': biometriaAtiva,
      'chat_ativo': chatAtivo,
      'status_campo_cupom': statusCampoCupom,
      'recibo_leitura': reciboLeitura,
      'mensagens_aleatorias_ativas': mensagensAleatoriasAtivas,
      'mensagens_intervalo_dias': intervaloMensagensDias,
      'mensagens_usar_nome_preferido': usarNomePreferidoNasMensagens,
      'mensagens_enviar_sem_agendamento': enviarMensagensSemAgendamento,
      'mensagens_aleatorias_clientes': mensagensAleatoriasClientes,
      'mensagens_indice_selecionada_clientes':
          indiceMensagemSelecionadaClientes,
    };
  }

  factory ConfigModel.fromMap(Map<String, dynamic> map) {
    final mensagens = (map['mensagens_aleatorias_clientes'] is List)
        ? List<String>.from(
            (map['mensagens_aleatorias_clientes'] as List)
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty),
          )
        : <String>[];

    final intervalo = map['mensagens_intervalo_dias'];
    final intervaloNormalizado = intervalo is num
        ? intervalo.toInt().clamp(1, 90)
        : 7;

    final indiceSelecionado = map['mensagens_indice_selecionada_clientes'];
    final indiceSelecionadoNormalizado = indiceSelecionado is num
      ? indiceSelecionado.toInt()
      : -1;

    return ConfigModel(
      camposObrigatorios: map['campos_obrigatorios'] != null
          ? Map<String, bool>.from(map['campos_obrigatorios'])
          : padrao,
      horasAntecedenciaCancelamento:
          (map['horas_antecedencia_cancelamento'] ?? 24).toDouble(),
      inicioSono: map['inicio_sono'] ?? 22,
      fimSono: map['fim_sono'] ?? 6,
      precoSessao: (map['preco_sessao'] ?? 100).toDouble(),
      biometriaAtiva: map['biometria_ativa'] ?? true,
      chatAtivo: map['chat_ativo'] ?? true,
      statusCampoCupom: map['status_campo_cupom'] ?? 1,
      reciboLeitura: map['recibo_leitura'] ?? true,
      mensagensAleatoriasAtivas: map['mensagens_aleatorias_ativas'] ?? false,
      intervaloMensagensDias: intervaloNormalizado,
      usarNomePreferidoNasMensagens:
          map['mensagens_usar_nome_preferido'] ?? true,
      enviarMensagensSemAgendamento:
          map['mensagens_enviar_sem_agendamento'] ?? false,
        indiceMensagemSelecionadaClientes:
          indiceSelecionadoNormalizado >= 0 ? indiceSelecionadoNormalizado : -1,
      mensagensAleatoriasClientes: mensagens,
    );
  }

  // Factory para criar uma instância vazia/padrão (útil para evitar null safety issues)
  factory ConfigModel.empty() {
    return ConfigModel(camposObrigatorios: padrao);
  }
}
