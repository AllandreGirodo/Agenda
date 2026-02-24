import 'package:cloud_firestore/cloud_firestore.dart';

class LogModel {
  final String? id;
  final DateTime dataHora;
  final String tipo; // 'cancelamento', 'aprovacao', 'sistema', 'espera'
  final String mensagem;
  final String? usuarioId;

  LogModel({
    this.id,
    required this.dataHora,
    required this.tipo,
    required this.mensagem,
    this.usuarioId,
  });

  Map<String, dynamic> toMap() => {
    'data_hora': Timestamp.fromDate(dataHora),
    'tipo': tipo,
    'mensagem': mensagem,
    'usuario_id': usuarioId,
  };

  factory LogModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return LogModel(
      id: id,
      dataHora: (map['data_hora'] as Timestamp).toDate(),
      tipo: map['tipo'] ?? 'sistema',
      mensagem: map['mensagem'] ?? '',
      usuarioId: map['usuario_id'],
    );
  }
}