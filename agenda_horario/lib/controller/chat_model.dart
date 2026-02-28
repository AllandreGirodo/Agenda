import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMensagem {
  final String? id;
  final String texto;
  final String tipo;
  final String autorId;
  final DateTime dataHora;
  final bool lida;

  ChatMensagem({
    this.id,
    required this.texto,
    this.tipo = 'texto',
    required this.autorId,
    required this.dataHora,
    this.lida = false,
  });

  Map<String, dynamic> toMap() => {
    'texto': texto,
    'autor_id': autorId,
    'tipo': tipo,
    'data_hora': Timestamp.fromDate(dataHora),
    'lida': lida,
  };

  factory ChatMensagem.fromMap(Map<String, dynamic> map, {String? id}) {
    return ChatMensagem(
      id: id,
      texto: map['texto'] ?? '',
      tipo: map['tipo'] ?? 'texto',
      autorId: map['autor_id'] ?? '',
      dataHora: (map['data_hora'] as Timestamp).toDate(),
      lida: map['lida'] ?? false,
    );
  }
}