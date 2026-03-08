import 'package:cloud_firestore/cloud_firestore.dart';

class Cliente {
  final String idCliente;
  final String? nomeCliente;
  final String? whatsappCliente;
  final int? saldoSessoesCliente;
  final DateTime? dataNascimentoCliente;
  final List<String>? favoritosCliente;
  final String? enderecoCliente;
  final String? historicoMedicoCliente;
  final String? alergiasCliente;
  final String? medicamentosCliente;
  final String? cirurgiasCliente;
  final bool? anamneseOkCliente;

  // Getters de compatibilidade para PerfilView
  String? get nome => nomeCliente;
  String? get whatsapp => whatsappCliente;
  String? get endereco => enderecoCliente;
  String? get historicoMedico => historicoMedicoCliente;
  String? get alergias => alergiasCliente;
  String? get medicamentos => medicamentosCliente;
  String? get cirurgias => cirurgiasCliente;
  DateTime? get dataNascimento => dataNascimentoCliente;
  List<String>? get favoritos => favoritosCliente;

  Cliente({
    required this.idCliente,
    this.nomeCliente,
    this.whatsappCliente,
    this.dataNascimentoCliente,
    this.saldoSessoesCliente,
    this.favoritosCliente,
    this.enderecoCliente,
    this.historicoMedicoCliente,
    this.alergiasCliente,
    this.medicamentosCliente,
    this.cirurgiasCliente,
    this.anamneseOkCliente,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': idCliente,
      'nome': nomeCliente,
      'whatsapp': whatsappCliente,
      'data_nascimento':
          dataNascimentoCliente != null ? Timestamp.fromDate(dataNascimentoCliente!) : null,
      'saldo_sessoes': saldoSessoesCliente,
      'favoritos': favoritosCliente,
      'endereco': enderecoCliente,
      'historico_medico': historicoMedicoCliente,
      'alergias': alergiasCliente,
      'medicamentos': medicamentosCliente,
      'cirurgias': cirurgiasCliente,
      'anamnese_ok': anamneseOkCliente,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      idCliente: map['uid'] ?? '',
      nomeCliente: map['nome'],
      whatsappCliente: map['whatsapp'],
      dataNascimentoCliente: map['data_nascimento'] != null
          ? (map['data_nascimento'] as Timestamp).toDate()
          : null,
      saldoSessoesCliente: map['saldo_sessoes'],
      favoritosCliente: map['favoritos'] != null ? List<String>.from(map['favoritos']) : null,
      enderecoCliente: map['endereco'],
      historicoMedicoCliente: map['historico_medico'],
      alergiasCliente: map['alergias'],
      medicamentosCliente: map['medicamentos'],
      cirurgiasCliente: map['cirurgias'],
      anamneseOkCliente: map['anamnese_ok'],
    );
  }
}
