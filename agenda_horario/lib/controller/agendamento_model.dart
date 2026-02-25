import 'package:cloud_firestore/cloud_firestore.dart';

class Agendamento {
  final String? id;
  final String clienteId;
  final DateTime dataHora;
  final String tipo; // Fixa ou Itinerante
  final String status; // 'pendente', 'aprovado', 'recusado'
  final String? motivoCancelamento;
  final List<String> listaEspera;
  final DateTime? dataCriacao; // Log de auditoria
  // Snapshots para integridade histórica (RF009)
  final String? clienteNomeSnapshot;
  final String? clienteTelefoneSnapshot;

  Agendamento({
    this.id,
    required this.clienteId,
    required this.dataHora,
    required this.tipo,
    this.status = 'pendente',
    this.motivoCancelamento,
    this.listaEspera = const [],
    this.dataCriacao,
    this.clienteNomeSnapshot,
    this.clienteTelefoneSnapshot,
  });

  Map<String, dynamic> toMap() => {
    'cliente_id': clienteId,
    'data_hora': Timestamp.fromDate(dataHora),
    'tipo': tipo,
    'status': status,
    'motivo_cancelamento': motivoCancelamento,
    'lista_espera': listaEspera,
    'data_criacao': dataCriacao != null ? Timestamp.fromDate(dataCriacao!) : FieldValue.serverTimestamp(),
    'cliente_nome_snapshot': clienteNomeSnapshot,
    'cliente_telefone_snapshot': clienteTelefoneSnapshot,
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
      dataCriacao: map['data_criacao'] != null 
          ? (map['data_criacao'] as Timestamp).toDate() 
          : null,
      clienteNomeSnapshot: map['cliente_nome_snapshot'],
      clienteTelefoneSnapshot: map['cliente_telefone_snapshot'],
    );
  }
}