import 'package:cloud_firestore/cloud_firestore.dart';

class Cliente {
  final String uid;
  final String nome;
  final String whatsapp;
  final String endereco;
  final DateTime? dataNascimento;
  // Anamnese
  final String historicoMedico;
  final String alergias;
  final String medicamentos;
  final String cirurgias;
  final bool anamneseOk;
  final int saldoSessoes;

  Cliente({
    required this.uid,
    required this.nome,
    required this.whatsapp,
    this.endereco = '',
    this.dataNascimento,
    this.historicoMedico = '',
    this.alergias = '',
    this.medicamentos = '',
    this.cirurgias = '',
    this.anamneseOk = false,
    this.saldoSessoes = 0,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'nome': nome,
    'whatsapp': whatsapp,
    'endereco': endereco,
    'data_nascimento': dataNascimento != null ? Timestamp.fromDate(dataNascimento!) : null,
    'historico_medico': historicoMedico,
    'alergias': alergias,
    'medicamentos': medicamentos,
    'cirurgias': cirurgias,
    'anamnese_ok': anamneseOk,
    'saldo_sessoes': saldoSessoes,
  };

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      uid: map['uid'] ?? '',
      nome: map['nome'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      endereco: map['endereco'] ?? '',
      dataNascimento: map['data_nascimento'] != null ? (map['data_nascimento'] as Timestamp).toDate() : null,
      historicoMedico: map['historico_medico'] ?? '',
      alergias: map['alergias'] ?? '',
      medicamentos: map['medicamentos'] ?? '',
      cirurgias: map['cirurgias'] ?? '',
      anamneseOk: map['anamnese_ok'] ?? false,
      saldoSessoes: map['saldo_sessoes'] ?? 0,
    );
  }
}