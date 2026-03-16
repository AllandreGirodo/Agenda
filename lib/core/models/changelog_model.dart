import 'package:cloud_firestore/cloud_firestore.dart';

class ChangeLogModel {
  final String versao;
  final DateTime data;
  final List<String> mudancas;
  final String titulo;
  final bool isCritical;
  final String autor;

  ChangeLogModel({
    required this.versao,
    required this.data,
    required this.mudancas,
    this.titulo = '',
    this.isCritical = false,
    required this.autor,
  });

  String get versionNumber => versao;
  DateTime get timestamp => data;
  List<String> get modifications => mudancas;
  String get title =>
      titulo.isEmpty ? 'Atualizacoes da versao $versao' : titulo;

  Map<String, dynamic> toMap() => {
    // Campos legados
    'versao': versao,
    'data': Timestamp.fromDate(data),
    'mudancas': mudancas,
    'autor': autor,
    // Campos novos
    'version_number': versao,
    'timestamp': Timestamp.fromDate(data),
    'title': title,
    'modifications': mudancas,
    'is_critical': isCritical,
  };

  factory ChangeLogModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final dynamic rawData = map['timestamp'] ?? map['data'];
    final DateTime data = rawData is Timestamp
        ? rawData.toDate()
        : DateTime.now();

    final dynamic rawMudancas = map['modifications'] ?? map['mudancas'];
    final List<String> mudancas = rawMudancas is List
        ? rawMudancas.map((item) => item.toString()).toList()
        : <String>[];

    final String versao =
        (map['version_number'] ?? map['versao'] ?? docId ?? '').toString();

    return ChangeLogModel(
      versao: versao,
      data: data,
      mudancas: mudancas,
      titulo: (map['title'] as String?)?.trim() ?? '',
      isCritical: map['is_critical'] as bool? ?? false,
      autor: (map['autor'] as String?)?.trim().isNotEmpty == true
          ? (map['autor'] as String).trim()
          : 'Sistema',
    );
  }
}
