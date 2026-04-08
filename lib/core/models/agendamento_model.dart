import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agenda/core/utils/massage_type_catalog.dart';

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
  final int? avaliacao; // 1 a 5 estrelas
  final String? comentarioAvaliacao;
  final String? cupomAplicado;
  final double? valorOriginal;
  final double? valorFinal;
  final String? administradoraAtrelada;

  // Getters de compatibilidade para evitar erros no FirestoreService
  String get idCliente => clienteId;
  String? get nomeClienteSnapshot => clienteNomeSnapshot;

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
    this.avaliacao,
    this.comentarioAvaliacao,
    this.cupomAplicado,
    this.valorOriginal,
    this.valorFinal,
    this.administradoraAtrelada,
  });

  Map<String, dynamic> toMap() {
    final tipoId = MassageTypeCatalog.normalizeId(tipo);

    return {
      'cliente_id': clienteId,
      'data_hora': Timestamp.fromDate(dataHora),
      'tipo': tipoId,
      'tipo_id': tipoId,
      'tipo_massagem': tipoId,
      'status': status,
      'motivo_cancelamento': motivoCancelamento,
      'lista_espera': listaEspera,
      'data_criacao': dataCriacao != null ? Timestamp.fromDate(dataCriacao!) : FieldValue.serverTimestamp(),
      'cliente_nome_snapshot': clienteNomeSnapshot,
      'cliente_telefone_snapshot': clienteTelefoneSnapshot,
      'avaliacao': avaliacao,
      'comentario_avaliacao': comentarioAvaliacao,
      'cupom_aplicado': cupomAplicado,
      'valor_original': valorOriginal,
      'valor_final': valorFinal,
      'preco': valorFinal ?? valorOriginal,
      'administradora_atrelada': administradoraAtrelada,
    };
  }

  static DateTime _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  static double _asDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.replaceAll(',', '.').trim());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  factory Agendamento.fromMap(Map<String, dynamic> map, {String? id}) {
    return Agendamento(
      id: id,
      clienteId: map['cliente_id'] ?? '',
      dataHora: _asDateTime(map['data_hora']),
      tipo: MassageTypeCatalog.normalizeId(
        (map['tipo_id'] ?? map['tipo'] ?? map['tipo_massagem'] ?? '').toString(),
      ),
      status: map['status'] ?? 'pendente',
      motivoCancelamento: map['motivo_cancelamento'],
      listaEspera: map['lista_espera'] != null 
          ? List<String>.from(map['lista_espera']) 
          : [],
      dataCriacao: map['data_criacao'] != null 
          ? _asDateTime(map['data_criacao']) 
          : null,
      clienteNomeSnapshot: map['cliente_nome_snapshot'],
      clienteTelefoneSnapshot: map['cliente_telefone_snapshot'],
      avaliacao: map['avaliacao'],
      comentarioAvaliacao: map['comentario_avaliacao'],
      cupomAplicado: map['cupom_aplicado'],
      valorOriginal: _asDouble(map['valor_original'] ?? map['preco']),
      valorFinal: _asDouble(map['valor_final'] ?? map['preco']),
      administradoraAtrelada: map['administradora_atrelada'] as String?,
    );
  }
}