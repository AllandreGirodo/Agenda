import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String id;
  final String nome;
  final String email;
  final String tipo; // 'admin' ou 'cliente'
  final bool aprovado;
  final DateTime? dataCadastro;
  final String? fcmToken;
  final bool visualizaTodos;
  final String? theme;
  final String? whatsapp;
  final bool numeroEhWhatsapp;
  final String? locale;

  UsuarioModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
    this.aprovado = false,
    this.dataCadastro,
    this.fcmToken,
    this.visualizaTodos = false,
    this.theme,
    this.whatsapp,
    this.numeroEhWhatsapp = true,
    this.locale,
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
      'fcm_token': fcmToken,
      'visualiza_todos': visualizaTodos,
      'theme': theme,
      'whatsapp': whatsapp,
      'numero_e_whatsapp': numeroEhWhatsapp,
      'locale': locale,
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
      fcmToken: map['fcm_token'],
      visualizaTodos: map['visualiza_todos'] ?? false,
      theme: map['theme'],
      whatsapp: map['whatsapp'] as String?,
      numeroEhWhatsapp: map['numero_e_whatsapp'] as bool? ?? true,
      locale: map['locale'] as String?,
    );
  }
}