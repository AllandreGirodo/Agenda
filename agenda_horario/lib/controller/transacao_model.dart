import 'package:cloud_firestore/cloud_firestore.dart';

class TransacaoFinanceira {
  final String? id; // transacao_id
  final String? agendamentoId; // agendamento_id (pode ser nulo se for venda avulsa)
  final String clienteUid; // cliente_uid
  
  // Valores
  final double valorBruto;
  final double valorDesconto;
  final double valorLiquido;

  // Detalhes
  final String metodoPagamento; // 'pix', 'dinheiro', 'cartao', 'pacote'
  final String statusPagamento; // 'pendente', 'pago', 'estornado'
  final DateTime dataPagamento;
  
  // Auditoria
  final DateTime? dataCriacao;
  final String criadoPorUid;

  TransacaoFinanceira({
    this.id,
    this.agendamentoId,
    required this.clienteUid,
    required this.valorBruto,
    this.valorDesconto = 0.0,
    required this.valorLiquido,
    required this.metodoPagamento,
    this.statusPagamento = 'pendente',
    required this.dataPagamento,
    this.dataCriacao,
    required this.criadoPorUid,
  });

  Map<String, dynamic> toMap() {
    return {
      'agendamento_id': agendamentoId,
      'cliente_uid': clienteUid,
      'valor_bruto': valorBruto,
      'valor_desconto': valorDesconto,
      'valor_liquido': valorLiquido,
      'metodo_pagamento': metodoPagamento,
      'status_pagamento': statusPagamento,
      'data_pagamento': Timestamp.fromDate(dataPagamento),
      'data_criacao': dataCriacao != null ? Timestamp.fromDate(dataCriacao!) : FieldValue.serverTimestamp(),
      'criado_por_uid': criadoPorUid,
    };
  }

  factory TransacaoFinanceira.fromMap(Map<String, dynamic> map, {String? id}) {
    return TransacaoFinanceira(
      id: id,
      agendamentoId: map['agendamento_id'],
      clienteUid: map['cliente_uid'] ?? '',
      valorBruto: (map['valor_bruto'] ?? 0.0).toDouble(),
      valorDesconto: (map['valor_desconto'] ?? 0.0).toDouble(),
      valorLiquido: (map['valor_liquido'] ?? 0.0).toDouble(),
      metodoPagamento: map['metodo_pagamento'] ?? 'dinheiro',
      statusPagamento: map['status_pagamento'] ?? 'pendente',
      dataPagamento: (map['data_pagamento'] as Timestamp).toDate(),
      dataCriacao: map['data_criacao'] != null ? (map['data_criacao'] as Timestamp).toDate() : null,
      criadoPorUid: map['criado_por_uid'] ?? '',
    );
  }
}