class UsuarioModel {
  final String id;
  final String nome;
  final String email;
  final String tipo; // 'admin' ou 'cliente'

  UsuarioModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
  });

  // Converter para Map (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'tipo': tipo,
    };
  }

  // Criar a partir de Map (ao ler do Firestore)
  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      tipo: map['tipo'] ?? 'cliente',
    );
  }
}