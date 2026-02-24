class Cliente {
  final String uid;
  final String nome;
  final String whatsapp;
  final bool anamneseOk;

  Cliente({
    required this.uid,
    required this.nome,
    required this.whatsapp,
    this.anamneseOk = false,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'nome': nome,
    'whatsapp': whatsapp,
    'anamnese_ok': anamneseOk,
  };

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      uid: map['uid'] ?? '',
      nome: map['nome'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      anamneseOk: map['anamnese_ok'] ?? false,
    );
  }
}