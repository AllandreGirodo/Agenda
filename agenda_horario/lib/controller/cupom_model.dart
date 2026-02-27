import 'package:cloud_firestore/cloud_firestore.dart';

class CupomModel {
  final String codigo; // Ex: DESC10
  final String tipo; // 'porcentagem' ou 'fixo'
  final double valor; // 10.0 (10% ou R$ 10,00)
  final DateTime validade;
  final bool ativo;

  CupomModel({
    required this.codigo,
    required this.tipo,
    required this.valor,
    required this.validade,
    this.ativo = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo.toUpperCase(),
      'tipo': tipo,
      'valor': valor,
      'validade': Timestamp.fromDate(validade),
      'ativo': ativo,
    };
  }

  factory CupomModel.fromMap(Map<String, dynamic> map) {
    return CupomModel(
      codigo: map['codigo'] ?? '',
      tipo: map['tipo'] ?? 'fixo',
      valor: (map['valor'] ?? 0.0).toDouble(),
      validade: (map['validade'] as Timestamp).toDate(),
      ativo: map['ativo'] ?? false,
    );
  }
}