class Cliente {
  final String uid;
  final String? nome;
  final String? whatsapp;
  final int? saldo_sessoes;
  final List<String>? favoritos;
  final String? endereco;
  final String? historico_medico;
  final String? alergias;
  final String? medicamentos;
  final String? cirurgias;
  final bool? anamnese_ok;


  Cliente({
    required this.uid,
    this.nome,
    this.whatsapp,
    this.saldo_sessoes,
    this.favoritos,
    this.endereco,
    this.historico_medico,
    this.alergias,
    this.medicamentos,
    this.cirurgias,
    this.anamnese_ok,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'whatsapp': whatsapp,
      'saldo_sessoes': saldo_sessoes,
      'favoritos': favoritos,
      'endereco': endereco,
      'historico_medico': historico_medico,
      'alergias': alergias,
      'medicamentos': medicamentos,
      'cirurgias': cirurgias,
      'anamnese_ok': anamnese_ok,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      uid: map['uid'] ?? '',
      nome: map['nome'],
      whatsapp: map['whatsapp'],
      saldo_sessoes: map['saldo_sessoes'],
      favoritos: map['favoritos'] != null ? List<String>.from(map['favoritos']) : null,
      endereco: map['endereco'],
      historico_medico: map['historico_medico'],
      alergias: map['alergias'],
      medicamentos: map['medicamentos'],
      cirurgias: map['cirurgias'],
      anamnese_ok: map['anamnese_ok'],
    );
  }
}
