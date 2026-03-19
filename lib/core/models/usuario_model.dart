import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String id;
  final String nome;
  final String? nomeCliente;
  final String? nomePreferido;
  final String email;
  final String? emailNormalizado;
  final String? nomeClienteNormalizado;
  final String tipo; // 'admin' ou 'cliente'
  final bool aprovado;
  final DateTime? dataCadastro;
  final String? fcmToken;
  final bool visualizaTodos;
  final String? theme;
  final String? whatsapp;
  final String? ddi;
  final String? telefonePrincipal;
  final String? nomeContatoSecundario;
  final String? telefoneSecundario;
  final String? nomeIndicacao;
  final String? telefoneIndicacao;
  final String? categoriaOrigem;
  final bool numeroEhWhatsapp;
  final String? locale;
  final String? adminAtreladaId;
  final bool devMaster;
  final bool lgpdConsentido;
  final DateTime? lgpdConsentimentoEm;
  final String? lastChangelogSeen;
  final bool showChangelogAuto;

  UsuarioModel({
    required this.id,
    required this.nome,
    this.nomeCliente,
    this.nomePreferido,
    required this.email,
    this.emailNormalizado,
    this.nomeClienteNormalizado,
    required this.tipo,
    this.aprovado = false,
    this.dataCadastro,
    this.fcmToken,
    this.visualizaTodos = false,
    this.theme,
    this.whatsapp,
    this.ddi,
    this.telefonePrincipal,
    this.nomeContatoSecundario,
    this.telefoneSecundario,
    this.nomeIndicacao,
    this.telefoneIndicacao,
    this.categoriaOrigem,
    this.numeroEhWhatsapp = true,
    this.locale,
    this.adminAtreladaId,
    this.devMaster = false,
    this.lgpdConsentido = false,
    this.lgpdConsentimentoEm,
    this.lastChangelogSeen,
    this.showChangelogAuto = true,
  });

  // Converter para Map (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'nome': nome,
      'nome_cliente': nomeCliente ?? nome,
      'nome_preferido': nomePreferido,
      'email': email,
      'email_normalizado': emailNormalizado ?? email.trim().toLowerCase(),
      'nome_cliente_normalizado':
          nomeClienteNormalizado ?? (nomeCliente ?? nome).trim().toLowerCase(),
      'tipo': tipo,
      'aprovado': aprovado,
      'data_cadastro': dataCadastro != null
          ? Timestamp.fromDate(dataCadastro!)
          : FieldValue.serverTimestamp(),
      'fcm_token': fcmToken,
      'visualiza_todos': visualizaTodos,
      'theme': theme,
      'whatsapp': whatsapp,
      'ddi': ddi ?? '55',
      'telefone_principal': telefonePrincipal ?? whatsapp,
      'nome_contato_secundario': nomeContatoSecundario,
      'telefone_secundario': telefoneSecundario,
      'nome_indicacao': nomeIndicacao,
      'telefone_indicacao': telefoneIndicacao,
      'categoria_origem': categoriaOrigem,
      'numero_e_whatsapp': numeroEhWhatsapp,
      'locale': locale,
      'admin_atrelada_id': adminAtreladaId,
      'dev_master': devMaster,
      'lgpd_consentido': lgpdConsentido,
      'lgpd_consentimento_em': lgpdConsentimentoEm != null
          ? Timestamp.fromDate(lgpdConsentimentoEm!)
          : (lgpdConsentido ? FieldValue.serverTimestamp() : null),
      'last_changelog_seen': lastChangelogSeen,
      'show_changelog_auto': showChangelogAuto,
    };

    map.removeWhere((key, value) => value == null);
    return map;
  }

  // Criar a partir de Map (ao ler do Firestore)
  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      nomeCliente: map['nome_cliente'] ?? map['nome'],
      nomePreferido: map['nome_preferido'] as String?,
      email: map['email'] ?? '',
      emailNormalizado: map['email_normalizado'] as String?,
      nomeClienteNormalizado: map['nome_cliente_normalizado'] as String?,
      tipo: map['tipo'] ?? 'cliente',
      aprovado: map['aprovado'] ?? false,
      dataCadastro: map['data_cadastro'] != null
          ? (map['data_cadastro'] as Timestamp).toDate()
          : null,
      fcmToken: map['fcm_token'],
      visualizaTodos: map['visualiza_todos'] ?? false,
      theme: map['theme'],
      whatsapp: map['whatsapp'] as String?,
        ddi: map['ddi'] as String?,
        telefonePrincipal:
          map['telefone_principal'] as String? ?? map['whatsapp'] as String?,
        nomeContatoSecundario: map['nome_contato_secundario'] as String?,
        telefoneSecundario: map['telefone_secundario'] as String?,
        nomeIndicacao: map['nome_indicacao'] as String?,
        telefoneIndicacao: map['telefone_indicacao'] as String?,
        categoriaOrigem: map['categoria_origem'] as String?,
      numeroEhWhatsapp: map['numero_e_whatsapp'] as bool? ?? true,
      locale: map['locale'] as String?,
      adminAtreladaId: map['admin_atrelada_id'] as String?,
      devMaster: map['dev_master'] as bool? ?? false,
      lgpdConsentido: map['lgpd_consentido'] as bool? ?? false,
      lgpdConsentimentoEm: map['lgpd_consentimento_em'] != null
          ? (map['lgpd_consentimento_em'] as Timestamp).toDate()
          : null,
      lastChangelogSeen: map['last_changelog_seen'] as String?,
      showChangelogAuto: map['show_changelog_auto'] as bool? ?? true,
    );
  }
}
