class EstoqueModel {
  final String id;
  final String nome;
  final double quantidade;
  final String unidade; // Ex: 'ml', 'g', 'frasco'
  final double nivelMinimo; // Para alerta de estoque baixo

  EstoqueModel({
    required this.id,
    required this.nome,
    required this.quantidade,
    required this.unidade,
    required this.nivelMinimo,
  });

  // Converter para Map (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'quantidade': quantidade,
      'unidade': unidade,
      'nivel_minimo': nivelMinimo,
    };
  }

  factory EstoqueModel.fromMap(Map<String, dynamic> map) {
    return EstoqueModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      quantidade: (map['quantidade'] ?? 0).toDouble(),
      unidade: map['unidade'] ?? '',
      nivelMinimo: (map['nivel_minimo'] ?? 0).toDouble(),
    );
  }
}