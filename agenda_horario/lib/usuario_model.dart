import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String id;
  final String nome;
  final String email;
  final String tipo; // 'admin' ou 'cliente'
  final bool aprovado;
  final DateTime? dataCadastro;

  UsuarioModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
    this.aprovado = false,
    this.dataCadastro,
  });

  // Converter para Map (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'tipo': tipo,
      'aprovado': aprovado,
      'data_cadastro': dataCadastro != null ? Timestamp.fromDate(dataCadastro!) : FieldValue.serverTimestamp(),
    };
  }

  // Criar a partir de Map (ao ler do Firestore)
  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      tipo: map['tipo'] ?? 'cliente',
      aprovado: map['aprovado'] ?? false,
      dataCadastro: map['data_cadastro'] != null 
          ? (map['data_cadastro'] as Timestamp).toDate() 
          : null,
    );
  }
}