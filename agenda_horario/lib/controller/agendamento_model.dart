import 'package:cloud_firestore/cloud_firestore.dart';

class Agendamento {
  final String clienteId;
  final DateTime dataHora;
  final String tipo; // Fixa ou Itinerante

  Agendamento({
    required this.clienteId,
    required this.dataHora,
    required this.tipo,
  });

  Map<String, dynamic> toMap() => {
    'cliente_id': clienteId,
    'data_hora': Timestamp.fromDate(dataHora),
    'tipo': tipo,
  };

  factory Agendamento.fromMap(Map<String, dynamic> map) {
    return Agendamento(
      clienteId: map['cliente_id'] ?? '',
      dataHora: (map['data_hora'] as Timestamp).toDate(),
      tipo: map['tipo'] ?? '',
    );
  }
}