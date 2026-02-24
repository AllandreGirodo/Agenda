import 'package:cloud_firestore/cloud_firestore.dart';

class Agendamento {
  final String? id;
  final String clienteId;
  final DateTime dataHora;
  final String tipo; // Fixa ou Itinerante
  final String status; // 'pendente', 'aprovado', 'recusado'
  final String? motivoCancelamento;
  final List<String> listaEspera;

  Agendamento({
    this.id,
    required this.clienteId,
    required this.dataHora,
    required this.tipo,
    this.status = 'pendente',
    this.motivoCancelamento,
    this.listaEspera = const [],
  });

  Map<String, dynamic> toMap() => {
    'cliente_id': clienteId,
    'data_hora': Timestamp.fromDate(dataHora),
    'tipo': tipo,
    'status': status,
    'motivo_cancelamento': motivoCancelamento,
    'lista_espera': listaEspera,
  };

  factory Agendamento.fromMap(Map<String, dynamic> map, {String? id}) {
    return Agendamento(
      id: id,
      clienteId: map['cliente_id'] ?? '',
      dataHora: (map['data_hora'] as Timestamp).toDate(),
      tipo: map['tipo'] ?? '',
      status: map['status'] ?? 'pendente',
      motivoCancelamento: map['motivo_cancelamento'],
      listaEspera: map['lista_espera'] != null 
          ? List<String>.from(map['lista_espera']) 
          : [],
    );
  }
}