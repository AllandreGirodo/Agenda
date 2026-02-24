class ConfigModel {
  final Map<String, bool> camposObrigatorios;
  final int horasAntecedenciaCancelamento;
  final int inicioSono; // Hora inteira (0-23)
  final int fimSono; // Hora inteira (0-23)
  final double precoSessao;

  ConfigModel({
    required this.camposObrigatorios,
    this.horasAntecedenciaCancelamento = 24,
    this.inicioSono = 22, // 22:00
    this.fimSono = 6, // 06:00
    this.precoSessao = 100.0,
  });

  // Campos padrão do sistema
  static Map<String, bool> get padrao => {
        'whatsapp': true,
        'endereco': false,
        'data_nascimento': true,
        'historico_medico': false,
        'alergias': false,
        'medicamentos': false,
        'cirurgias': false,
      };

  Map<String, dynamic> toMap() {
    return {
      'campos_obrigatorios': camposObrigatorios,
      'horas_antecedencia_cancelamento': horasAntecedenciaCancelamento,
      'inicio_sono': inicioSono,
      'fim_sono': fimSono,
      'preco_sessao': precoSessao,
    };
  }

  factory ConfigModel.fromMap(Map<String, dynamic> map) {
    return ConfigModel(
      camposObrigatorios: map['campos_obrigatorios'] != null
          ? Map<String, bool>.from(map['campos_obrigatorios'])
          : padrao,
      horasAntecedenciaCancelamento: map['horas_antecedencia_cancelamento'] ?? 24,
      inicioSono: map['inicio_sono'] ?? 22,
      fimSono: map['fim_sono'] ?? 6,
      precoSessao: (map['preco_sessao'] ?? 100).toDouble(),
    );
  }
}