class ItemEstoque {
  final String? id;
  final String nome;
  final int quantidade; // Em unidades ou doses
  final bool consumoAutomatico; // Se true, desconta ao aprovar agendamento

  ItemEstoque({
    this.id,
    required this.nome,
    required this.quantidade,
    this.consumoAutomatico = false,
  });

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'quantidade': quantidade,
        'consumo_automatico': consumoAutomatico,
      };

  factory ItemEstoque.fromMap(Map<String, dynamic> map, {String? id}) {
    return ItemEstoque(
      id: id,
      nome: map['nome'] ?? '',
      quantidade: map['quantidade'] ?? 0,
      consumoAutomatico: map['consumo_automatico'] ?? false,
    );
  }
}