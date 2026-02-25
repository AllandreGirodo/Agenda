import 'package:cloud_firestore/cloud_firestore.dart';

class LogModel {
  final String tipo;
  final String mensagem;
  final DateTime dataHora;
  final String? usuarioId;

  LogModel({required this.tipo, required this.mensagem, required this.dataHora, this.usuarioId});

  Map<String, dynamic> toMap() => {
    'data_hora': Timestamp.fromDate(dataHora),
    'tipo': tipo,
    'mensagem': mensagem,
    'usuario_id': usuarioId,
  };

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      tipo: map['tipo'] as String,
      mensagem: map['mensagem'] as String,
      dataHora: (map['dataHora'] as Timestamp).toDate(),
      usuarioId: map['usuarioId'] as String?,
    );
  }
}