import 'package:cloud_firestore/cloud_firestore.dart';

class ChangeLogModel {
  final String versao;
  final DateTime data;
  final List<String> mudancas;
  final String autor;

  ChangeLogModel({
    required this.versao,
    required this.data,
    required this.mudancas,
    required this.autor,
  });

  Map<String, dynamic> toMap() => {
    'versao': versao,
    'data': Timestamp.fromDate(data),
    'mudancas': mudancas,
    'autor': autor,
  };

  factory ChangeLogModel.fromMap(Map<String, dynamic> map) {
    return ChangeLogModel(
      versao: map['versao'] ?? '',
      data: (map['data'] as Timestamp).toDate(),
      mudancas: List<String>.from(map['mudancas'] ?? []),
      autor: map['autor'] ?? 'Sistema',
    );
  }
}