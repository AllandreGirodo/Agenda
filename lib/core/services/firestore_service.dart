import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:agenda/core/models/agendamento_model.dart';
import 'package:agenda/core/models/app_software_config_model.dart';
import 'package:agenda/core/models/changelog_model.dart';
import 'package:agenda/core/models/chat_model.dart';
import 'package:agenda/core/models/config_model.dart';
import 'package:agenda/core/models/cupom_model.dart';
import 'package:agenda/core/models/estoque_model.dart';
import 'package:agenda/core/models/log_model.dart';
import 'package:agenda/core/models/transacao_model.dart';
import 'package:agenda/core/models/usuario_model.dart';
import 'package:agenda/core/utils/app_strings.dart';
import 'package:agenda/core/utils/massage_type_catalog.dart';
import 'package:agenda/core/models/cliente_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static const String _tenantPadraoId = 'administrador_padrao_atrelado';
  static const String _tenantPadraoNomeExibicao =
      'administrador_padrao_atrelado';

  String _normalizarTelefone(String telefone) {
    return telefone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _normalizarEmail(String email) {
    return email.trim().toLowerCase();
  }

  String _normalizarNomeBusca(String nome) {
    return nome.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _normalizarSlug(String valor) {
    final limpo = valor.trim().toLowerCase();
    final semAcento = limpo
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');

    return semAcento
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  String _devEmailConfigurado() {
    try {
      final valorEnv = (dotenv.env['DEV_EMAIL'] ?? '').trim();
      if (valorEnv.isNotEmpty) {
        return _normalizarEmail(valorEnv);
      }
    } catch (_) {
      // dotenv pode nao estar inicializado em alguns contextos de teste.
    }

    const valorDefine = String.fromEnvironment('DEV_EMAIL', defaultValue: '');
    return _normalizarEmail(valorDefine);
  }

  String _pushNotificationFunctionName() {
    try {
      final valorEnv = (dotenv.env['PUSH_NOTIFICATION_FUNCTION_NAME'] ?? '')
          .trim();
      if (valorEnv.isNotEmpty) {
        return valorEnv;
      }
    } catch (_) {
      // dotenv pode nao estar inicializado em alguns contextos de teste.
    }

    return const String.fromEnvironment(
      'PUSH_NOTIFICATION_FUNCTION_NAME',
      defaultValue: '',
    ).trim();
  }

  String _pushNotificationProxyUrl() {
    try {
      final valorEnv = (dotenv.env['PUSH_NOTIFICATION_PROXY_URL'] ?? '').trim();
      if (valorEnv.isNotEmpty) {
        return valorEnv;
      }
    } catch (_) {
      // dotenv pode nao estar inicializado em alguns contextos de teste.
    }

    return const String.fromEnvironment(
      'PUSH_NOTIFICATION_PROXY_URL',
      defaultValue: '',
    ).trim();
  }

  bool emailEhDevMaster(String email) {
    final devEmail = _devEmailConfigurado();
    if (devEmail.isEmpty) return false;
    return _normalizarEmail(email) == devEmail;
  }

  bool podeAcessarPainelDev(UsuarioModel? usuario) {
    if (usuario == null) return false;
    return usuario.devMaster && emailEhDevMaster(usuario.email);
  }

  Future<void> _garantirConfiguracoesGeraisTenantPadrao({
    String tenantId = _tenantPadraoId,
    String nomeExibicao = _tenantPadraoNomeExibicao,
  }) async {
    final tenantSlug = _normalizarSlug(tenantId);
    final nome = nomeExibicao.trim().isNotEmpty
        ? nomeExibicao.trim()
        : _tenantPadraoNomeExibicao;

    await _db.collection('configuracoes_gerais').doc(tenantSlug).set({
      'id': tenantSlug,
      'nome_exibicao': nome,
      'nome_normalizado': _normalizarNomeBusca(nome),
      'ativo': true,
      'atualizado_em': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> getAdministradoraPadraoAtreladaId() async {
    try {
      final doc = await _db.collection('configuracoes').doc('geral').get();
      final dados = doc.data() ?? const <String, dynamic>{};

      final valorId =
          (dados['administradora_padrao_atrelada_id'] as String? ?? '').trim();
      final valorLegado =
          (dados['administradora_padrao_atrelada'] as String? ?? '').trim();

      final tenantId = _normalizarSlug(
        valorId.isNotEmpty
            ? valorId
            : (valorLegado.isNotEmpty ? valorLegado : _tenantPadraoId),
      );
      final nomeExibicao = valorLegado.isNotEmpty
          ? valorLegado
          : _tenantPadraoNomeExibicao;

      if (tenantId.isNotEmpty) {
        await _db.collection('configuracoes').doc('geral').set({
          'administradora_padrao_atrelada_id': tenantId,
        }, SetOptions(merge: true));

        await _garantirConfiguracoesGeraisTenantPadrao(
          tenantId: tenantId,
          nomeExibicao: nomeExibicao,
        );

        return tenantId;
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
    }

    return _tenantPadraoId;
  }

  Future<String> getNomeAdministradoraPorId(String adminId) async {
    final tenantId = _normalizarSlug(adminId);
    if (tenantId.isEmpty) return _tenantPadraoNomeExibicao;

    try {
      final doc = await _db
          .collection('configuracoes_gerais')
          .doc(tenantId)
          .get();
      final nome = (doc.data()?['nome_exibicao'] as String? ?? '').trim();
      if (nome.isNotEmpty) return nome;
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
    }

    return adminId;
  }

  DocumentReference<Map<String, dynamic>> _usuarioRefPorEmail(String email) {
    return _db.collection('usuarios').doc(_normalizarEmail(email));
  }

  Future<DocumentReference<Map<String, dynamic>>?> _buscarUsuarioRefPorUid(
    String uid,
  ) async {
    final uidNormalizado = uid.trim();
    if (uidNormalizado.isEmpty) return null;

    final usuarioAtual = FirebaseAuth.instance.currentUser;
    final bool uidEhDoUsuarioLogado =
        usuarioAtual != null && usuarioAtual.uid == uidNormalizado;

    if (uidEhDoUsuarioLogado) {
      final emailAutenticado = _normalizarEmail(usuarioAtual.email ?? '');
      if (emailAutenticado.isNotEmpty) {
        final usuarioRefPorEmail = _db
            .collection('usuarios')
            .doc(emailAutenticado);
        final usuarioSnapPorEmail = await usuarioRefPorEmail.get();
        if (usuarioSnapPorEmail.exists) {
          return usuarioRefPorEmail;
        }
      }

      final usuarioLegadoRef = _db.collection('usuarios').doc(uidNormalizado);
      final usuarioLegadoSnap = await usuarioLegadoRef.get();
      if (usuarioLegadoSnap.exists) {
        return usuarioLegadoRef;
      }
    }

    final indiceEmail = await _db
        .collection('usuarios_por_email')
        .where('uid', isEqualTo: uidNormalizado)
        .limit(1)
        .get();

    if (indiceEmail.docs.isNotEmpty) {
      final dataIndice = indiceEmail.docs.first.data();
      final emailNormalizado = _normalizarEmail(
        (dataIndice['email_normalizado'] as String? ??
                indiceEmail.docs.first.id)
            .trim(),
      );
      if (emailNormalizado.isNotEmpty) {
        final usuarioRefPorEmail = _db
            .collection('usuarios')
            .doc(emailNormalizado);
        final usuarioSnapPorEmail = await usuarioRefPorEmail.get();
        if (usuarioSnapPorEmail.exists) {
          return usuarioRefPorEmail;
        }
      }
    }

    final usuariosPorId = await _db
        .collection('usuarios')
        .where('id', isEqualTo: uidNormalizado)
        .limit(1)
        .get();

    if (usuariosPorId.docs.isNotEmpty) {
      return usuariosPorId.docs.first.reference;
    }

    // Compatibilidade com documentos legados cuja chave era o UID.
    final usuarioLegadoRef = _db.collection('usuarios').doc(uidNormalizado);
    final usuarioLegadoSnap = await usuarioLegadoRef.get();
    if (usuarioLegadoSnap.exists) {
      return usuarioLegadoRef;
    }

    return null;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _buscarUsuarioSnapPorUid(
    String uid,
  ) async {
    final usuarioRef = await _buscarUsuarioRefPorUid(uid);
    if (usuarioRef == null) return null;

    final snap = await usuarioRef.get();
    if (!snap.exists || snap.data() == null) return null;
    return snap;
  }

  String _hashValorSensivel(String valor) {
    return crypto.sha256.convert(utf8.encode(valor)).toString();
  }

  String _normalizarVersaoSoftware(String versao) {
    final partes = _partesVersao(versao);
    while (partes.length < 4) {
      partes.add(0);
    }
    return partes.join('.');
  }

  List<int> _partesVersao(String versao) {
    final normalized = versao.trim().replaceFirst(RegExp(r'^[vV]'), '');
    if (normalized.isEmpty) return <int>[0];

    final parts = normalized
        .split(RegExp(r'[^0-9]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => int.tryParse(part) ?? 0)
        .toList();

    return parts.isEmpty ? <int>[0] : parts;
  }

  int compararVersoesSoftware(String versaoA, String versaoB) {
    final a = _partesVersao(versaoA);
    final b = _partesVersao(versaoB);
    final maxLen = a.length > b.length ? a.length : b.length;

    for (var i = 0; i < maxLen; i++) {
      final ai = i < a.length ? a[i] : 0;
      final bi = i < b.length ? b[i] : 0;
      if (ai != bi) return ai.compareTo(bi);
    }

    return 0;
  }

  Future<String> getVersaoLocalAplicativo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return _normalizarVersaoSoftware(info.version);
    } catch (_) {
      const fallbackVersion = String.fromEnvironment(
        'APP_VERSION',
        defaultValue: '1.0.0.0',
      );
      return _normalizarVersaoSoftware(fallbackVersion);
    }
  }

  Future<AppSoftwareConfigModel> getAppSoftwareConfig() async {
    const padrao = AppSoftwareConfigModel.padrao;
    final docRef = _db.collection('app_software').doc('config');

    try {
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        return AppSoftwareConfigModel.fromMap(doc.data()!);
      }

      await docRef.set(padrao.toMap(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
    }

    return padrao;
  }

  String _whatsappAdminPadrao() {
    try {
      final telefoneEnv = (dotenv.env['WHATSAPP_ADMIN'] ?? '').trim();
      if (telefoneEnv.isNotEmpty) {
        return _normalizarTelefone(telefoneEnv);
      }
    } catch (_) {
      // dotenv pode nao estar inicializado em alguns contextos de teste.
    }

    const telefoneDefine = String.fromEnvironment(
      'WHATSAPP_ADMIN',
      defaultValue: '',
    );
    return _normalizarTelefone(telefoneDefine);
  }

  // --- Clientes ---
  Future<void> salvarCliente(Cliente cliente) async {
    // Usa o UID como ID do documento para facilitar a busca
    await _db
        .collection('clientes')
        .doc(cliente.idCliente)
        .set(cliente.toMap());
  }

  Future<Cliente?> getCliente(String uid) async {
    final doc = await _db.collection('clientes').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return Cliente.fromMap(doc.data()!);
    }
    return null;
  }

  Stream<List<Cliente>> getClientesAprovados() {
    // Busca usuários aprovados e cruza com a coleção de clientes se necessário
    // Para simplificar, vamos assumir que todo usuário aprovado tem um doc em 'clientes'
    // ou listar direto de 'clientes'.
    return _db
        .collection('clientes')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Cliente.fromMap(doc.data())).toList(),
        );
  }

  Future<void> adicionarPacote(String uid, int quantidade) async {
    await _db.collection('clientes').doc(uid).update({
      'saldo_sessoes': FieldValue.increment(quantidade),
    });
  }

  Future<void> toggleFavorito(String uid, String tipo) async {
    final docRef = _db.collection('clientes').doc(uid);
    final doc = await docRef.get();
    if (doc.exists) {
      final favoritosExistentes = List<String>.from(
        doc.data()?['favoritos'] ?? [],
      );
      final favoritos = MassageTypeCatalog.normalizeIds(favoritosExistentes);
      final tipoId = MassageTypeCatalog.normalizeId(tipo);

      if (favoritos.contains(tipoId)) {
        favoritos.remove(tipoId);
      } else {
        favoritos.add(tipoId);
      }
      await docRef.update({'favoritos': favoritos});
    }
  }

  // --- Estoque ---
  Stream<List<ItemEstoque>> getEstoque() {
    return _db
        .collection('estoque')
        .orderBy('nome')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ItemEstoque.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Future<void> salvarItemEstoque(ItemEstoque item) async {
    if (item.id == null) {
      await _db.collection('estoque').add(item.toMap());
    } else {
      await _db.collection('estoque').doc(item.id).update(item.toMap());
    }
  }

  Future<void> excluirItemEstoque(String id) async {
    await _db.collection('estoque').doc(id).delete();
  }

  // --- Configurações do Sistema ---
  Future<void> salvarConfiguracao(ConfigModel config) async {
    await _db
        .collection('configuracoes')
        .doc('geral')
        .set(config.toMap(), SetOptions(merge: true));
  }

  Future<ConfigModel> getConfiguracao() async {
    try {
      final doc = await _db.collection('configuracoes').doc('geral').get();
      if (doc.exists && doc.data() != null) {
        return ConfigModel.fromMap(doc.data()!);
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
      debugPrint(AppStrings.erroAoCarregarConfiguracao);
    } catch (e) {
      debugPrint(AppStrings.erroCarregandoConfiguracao('$e'));
    }
    return ConfigModel(camposObrigatorios: ConfigModel.padrao);
  }

  Future<String?> _buscarSenhaAdminFerramentas() async {
    final docSeguranca = await _db
        .collection('configuracoes')
        .doc('seguranca')
        .get();
    final senhaSeguranca = docSeguranca.data()?['senha_admin_ferramentas'];
    if (senhaSeguranca is String && senhaSeguranca.trim().isNotEmpty) {
      return senhaSeguranca.trim();
    }

    final docGeral = await _db.collection('configuracoes').doc('geral').get();
    final senhaGeral = docGeral.data()?['senha_admin_ferramentas'];
    if (senhaGeral is String && senhaGeral.trim().isNotEmpty) {
      return senhaGeral.trim();
    }

    return null;
  }

  Future<String?> buscarSenhaAdminFerramentasAtual() async {
    return await _buscarSenhaAdminFerramentas();
  }

  Future<bool> verificaSenhaAdminFerramentasConfigurada() async {
    return await _buscarSenhaAdminFerramentas() != null;
  }

  Future<void> salvarSenhaAdminFerramentas(String novaSenha) async {
    await _db.collection('configuracoes').doc('seguranca').set({
      'senha_admin_ferramentas': novaSenha.trim(),
    }, SetOptions(merge: true));
  }

  Future<bool> validarSenhaAdminFerramentas(String senhaInformada) async {
    final senhaConfigurada = await _buscarSenhaAdminFerramentas();
    if (senhaConfigurada == null) {
      throw StateError(
        'Senha de admin nao configurada em configuracoes/seguranca.senha_admin_ferramentas',
      );
    }
    return senhaInformada.trim() == senhaConfigurada;
  }

  // Busca o telefone do admin (WhatsApp) configurado.
  // Quando não existir no Firestore, usa WHATSAPP_ADMIN e tenta persistir no banco.
  Future<String> getTelefoneAdmin() async {
    final telefonePadrao = _whatsappAdminPadrao();
    final docRef = _db.collection('configuracoes').doc('geral');

    try {
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        final telefoneBanco = _normalizarTelefone(
          doc.data()!['whatsapp_admin'] as String? ?? '',
        );
        if (telefoneBanco.isNotEmpty) {
          return telefoneBanco;
        }
      }

      if (telefonePadrao.isNotEmpty) {
        try {
          await docRef.set({
            'whatsapp_admin': telefonePadrao,
          }, SetOptions(merge: true));
        } on FirebaseException catch (e) {
          if (e.code != 'permission-denied') {
            rethrow;
          }
        }
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
    }

    return telefonePadrao;
  }

  // Salva o telefone do admin (Conectar este método a um TextField na tela de Admin)
  Future<void> salvarTelefoneAdmin(String telefone) async {
    final telefoneNormalizado = _normalizarTelefone(telefone);
    await _db.collection('configuracoes').doc('geral').set({
      'whatsapp_admin': telefoneNormalizado,
    }, SetOptions(merge: true));
  }

  // Tenta garantir que WHATSAPP_ADMIN esteja persistido em configuracoes/geral.
  // Se o usuario atual nao tiver permissao (nao-admin), o fluxo segue sem erro.
  Future<void> sincronizarWhatsappAdminPadrao() async {
    final telefonePadrao = _whatsappAdminPadrao();
    if (telefonePadrao.isEmpty) return;

    try {
      await _db.collection('configuracoes').doc('geral').set({
        'whatsapp_admin': telefonePadrao,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
    }
  }

  Future<String> getAdministradoraPadraoAtrelada() async {
    return getAdministradoraPadraoAtreladaId();
  }

  // Busca a lista de tipos de massagem configurados no banco
  Future<List<String>> getTiposMassagem() async {
    final fallback = MassageTypeCatalog.defaultIds;

    final doc = await _db.collection('configuracoes').doc('servicos').get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      final tiposRaw =
          data['tipos_massagem_ids'] ?? data['tipos_massagem'] ?? data['tipos'];

      if (tiposRaw is List) {
        final tiposNormalizados = MassageTypeCatalog.normalizeIds(tiposRaw);
        if (tiposNormalizados.isNotEmpty) {
          // Migração transparente: garante campo por ID sem bloquear o fluxo se faltar permissão.
          try {
            await _db.collection('configuracoes').doc('servicos').set({
              'tipos_massagem_ids': tiposNormalizados,
              'tipos_massagem': tiposNormalizados,
            }, SetOptions(merge: true));
          } catch (_) {}
          return tiposNormalizados;
        }
      }
    }

    return fallback;
  }

  // --- Manutenção ---
  Stream<bool> getManutencaoStream() {
    return _db.collection('configuracoes').doc('geral').snapshots().map((doc) {
      return doc.data()?['em_manutencao'] ?? false;
    });
  }

  Future<void> atualizarStatusManutencao(bool status) async {
    await _db.collection('configuracoes').doc('geral').set({
      'em_manutencao': status,
    }, SetOptions(merge: true));
  }

  // --- Usuarios (Login) ---
  Future<UsuarioModel?> getUsuario(String uid) async {
    final doc = await _buscarUsuarioSnapPorUid(uid);
    if (doc != null && doc.data() != null) {
      return UsuarioModel.fromMap(doc.data()!);
    }
    return null;
  }

  Stream<UsuarioModel?> getUsuarioStream(String uid) {
    final uidNormalizado = uid.trim();
    if (uidNormalizado.isEmpty) {
      return Stream<UsuarioModel?>.value(null);
    }

    final usuarioAtual = FirebaseAuth.instance.currentUser;
    final bool uidEhDoUsuarioLogado =
        usuarioAtual != null && usuarioAtual.uid == uidNormalizado;

    if (uidEhDoUsuarioLogado) {
      final emailAutenticado = _normalizarEmail(usuarioAtual.email ?? '');
      if (emailAutenticado.isNotEmpty) {
        return _db
            .collection('usuarios')
            .doc(emailAutenticado)
            .snapshots()
            .asyncMap((doc) async {
              if (doc.exists && doc.data() != null) {
                return UsuarioModel.fromMap(doc.data()!);
              }

              final docLegado = await _db
                  .collection('usuarios')
                  .doc(uidNormalizado)
                  .get();
              if (docLegado.exists && docLegado.data() != null) {
                return UsuarioModel.fromMap(docLegado.data()!);
              }

              return null;
            });
      }

      return _db.collection('usuarios').doc(uidNormalizado).snapshots().map((
        doc,
      ) {
        if (doc.exists && doc.data() != null) {
          return UsuarioModel.fromMap(doc.data()!);
        }
        return null;
      });
    }

    return _db
        .collection('usuarios')
        .where('id', isEqualTo: uidNormalizado)
        .limit(1)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isNotEmpty) {
            return UsuarioModel.fromMap(snapshot.docs.first.data());
          }

          final docLegado = await _db
              .collection('usuarios')
              .doc(uidNormalizado)
              .get();
          if (docLegado.exists && docLegado.data() != null) {
            return UsuarioModel.fromMap(docLegado.data()!);
          }

          return null;
        });
  }

  Future<void> salvarUsuario(UsuarioModel usuario) async {
    final emailDocId = _normalizarEmail(
      usuario.emailNormalizado ?? usuario.email,
    );
    final docId = emailDocId.isNotEmpty ? emailDocId : usuario.id;

    await _db
        .collection('usuarios')
        .doc(docId)
        .set(usuario.toMap(), SetOptions(merge: true));
    await _sincronizarIndiceHumanoUsuario(
      uid: usuario.id,
      email: usuario.email,
      nomeCliente: usuario.nomeCliente ?? usuario.nome,
      tipo: usuario.tipo,
      aprovado: usuario.aprovado,
    );
  }

  Future<void> marcarChangelogComoVisto(String uid, String versao) async {
    final usuarioRef = await _buscarUsuarioRefPorUid(uid);
    if (usuarioRef == null) return;

    await usuarioRef.set({
      'last_changelog_seen': _normalizarVersaoSoftware(versao),
    }, SetOptions(merge: true));
  }

  Future<void> atualizarPreferenciaAutoChangelog(
    String uid,
    bool exibirAutomaticamente,
  ) async {
    final usuarioRef = await _buscarUsuarioRefPorUid(uid);
    if (usuarioRef == null) return;

    await usuarioRef.set({
      'show_changelog_auto': exibirAutomaticamente,
    }, SetOptions(merge: true));
  }

  Future<void> registrarAuditoriaCredencialInconforme({
    required String origem,
    required String emailDigitado,
    required String senhaInformada,
    required bool inconformidade,
    required bool lgpdConsentido,
    required List<String> motivos,
    String? nomeClienteDigitado,
    String? usuarioId,
    bool? emailValido,
    bool? senhaForte,
  }) async {
    final emailNormalizado = _normalizarEmail(emailDigitado);

    try {
      await _db.collection('auditoria_credenciais').add({
        'origem': origem,
        'email_digitado': emailDigitado,
        'email_normalizado': emailNormalizado,
        'nome_cliente_digitado': (nomeClienteDigitado ?? '').trim(),
        'senha_hash': _hashValorSensivel(senhaInformada),
        'senha_tamanho': senhaInformada.length,
        'motivos': motivos,
        'inconformidade': inconformidade,
        'lgpd_consentido': lgpdConsentido,
        'email_valido': emailValido ?? emailNormalizado.isNotEmpty,
        'senha_forte': senhaForte ?? false,
        'usuario_id': usuarioId,
        'criado_em': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Falha ao registrar auditoria de credenciais: $e');
    }
  }

  Future<void> _sincronizarIndiceHumanoUsuario({
    required String uid,
    required String email,
    required String nomeCliente,
    required String tipo,
    required bool aprovado,
  }) async {
    final emailNormalizado = _normalizarEmail(email);
    if (emailNormalizado.isEmpty) return;

    await _db.collection('usuarios_por_email').doc(emailNormalizado).set({
      'uid': uid,
      'email': email,
      'email_normalizado': emailNormalizado,
      'nome_cliente': nomeCliente,
      'nome_cliente_normalizado': _normalizarNomeBusca(nomeCliente),
      'tipo': tipo,
      'aprovado': aprovado,
      'atualizado_em': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> alternarTesteBooleanoLoginView({
    required String emailDigitado,
    required bool valorAtual,
    String? uid,
  }) async {
    final proximoValor = !valorAtual;
    final usuarioAtual = FirebaseAuth.instance.currentUser;
    final uidEfetivo = (uid ?? usuarioAtual?.uid ?? '').trim();
    final emailAutenticado = (usuarioAtual?.email ?? '').trim();
    final nomePadrao = (usuarioAtual?.displayName ?? '').trim().isNotEmpty
        ? (usuarioAtual?.displayName ?? '').trim()
        : 'Cliente';

    await _db.collection('teste').add({
      'ativo': proximoValor,
      'email_digitado': emailDigitado.isEmpty ? 'sem_email' : emailDigitado,
      'uid': uidEfetivo.isEmpty ? 'nao_autenticado' : uidEfetivo,
      'origem': 'login_view',
      'criado_em': FieldValue.serverTimestamp(),
    });

    if (uidEfetivo.isEmpty) {
      throw StateError(AppStrings.testeBooleanoRequerLogin);
    }

    final emailBase = emailAutenticado.isNotEmpty
        ? emailAutenticado
        : emailDigitado.trim();

    await _garantirCamposEssenciaisDoUsuario(
      uid: uidEfetivo,
      email: emailBase,
      nomePadrao: nomePadrao,
    );

    return proximoValor;
  }

  Future<void> _garantirCamposEssenciaisDoUsuario({
    required String uid,
    required String email,
    required String nomePadrao,
  }) async {
    final emailNormalizado = _normalizarEmail(email);
    final tenantPadraoId = await getAdministradoraPadraoAtreladaId();
    final devMaster = emailEhDevMaster(emailNormalizado);
    final tipoPadrao = devMaster ? 'admin' : 'cliente';
    final aprovadoPadrao = devMaster;

    final usuarioRef = emailNormalizado.isNotEmpty
        ? _usuarioRefPorEmail(emailNormalizado)
        : _db.collection('usuarios').doc(uid);
    final clienteRef = _db.collection('clientes').doc(uid);

    final usuarioSnap = await usuarioRef.get();
    final clienteSnap = await clienteRef.get();

    if (!usuarioSnap.exists || usuarioSnap.data() == null) {
      await usuarioRef.set({
        'id': uid,
        'nome': nomePadrao,
        'nome_cliente': nomePadrao,
        'email': email,
        'email_normalizado': _normalizarEmail(email),
        'nome_cliente_normalizado': _normalizarNomeBusca(nomePadrao),
        'tipo': tipoPadrao,
        'aprovado': aprovadoPadrao,
        'data_cadastro': FieldValue.serverTimestamp(),
        'fcm_token': null,
        'visualiza_todos': false,
        'theme': 'AppThemeType.sistema',
        'whatsapp': '',
        'numero_e_whatsapp': true,
        'locale': 'pt',
        'admin_atrelada_id': tenantPadraoId,
        'dev_master': devMaster,
        'lgpd_consentido': false,
        'last_changelog_seen': null,
        'show_changelog_auto': true,
      }, SetOptions(merge: true));
    } else {
      final usuarioData = usuarioSnap.data()!;
      final updatesUsuario = <String, dynamic>{};

      final nomeAtual = (usuarioData['nome'] as String? ?? '').trim();
      final emailAtual = (usuarioData['email'] as String? ?? '').trim();
      final nomeClienteAtual = (usuarioData['nome_cliente'] as String? ?? '')
          .trim();

      if (nomeAtual.isEmpty) updatesUsuario['nome'] = nomePadrao;
      if (nomeClienteAtual.isEmpty) {
        updatesUsuario['nome_cliente'] = nomePadrao;
      }
      if (emailAtual.isEmpty && email.isNotEmpty) {
        updatesUsuario['email'] = email;
      }
      if (!usuarioData.containsKey('email_normalizado') && email.isNotEmpty) {
        updatesUsuario['email_normalizado'] = _normalizarEmail(email);
      }
      if (!usuarioData.containsKey('nome_cliente_normalizado')) {
        updatesUsuario['nome_cliente_normalizado'] = _normalizarNomeBusca(
          nomePadrao,
        );
      }
      if (!usuarioData.containsKey('aprovado')) {
        updatesUsuario['aprovado'] = aprovadoPadrao;
      }
      if (!usuarioData.containsKey('tipo')) updatesUsuario['tipo'] = tipoPadrao;
      if (!usuarioData.containsKey('theme')) {
        updatesUsuario['theme'] = 'AppThemeType.sistema';
      }
      if (!usuarioData.containsKey('whatsapp')) updatesUsuario['whatsapp'] = '';
      if (!usuarioData.containsKey('numero_e_whatsapp')) {
        updatesUsuario['numero_e_whatsapp'] = true;
      }
      if (!usuarioData.containsKey('locale')) updatesUsuario['locale'] = 'pt';
      if (!usuarioData.containsKey('lgpd_consentido')) {
        updatesUsuario['lgpd_consentido'] = false;
      }
      if (!usuarioData.containsKey('show_changelog_auto')) {
        updatesUsuario['show_changelog_auto'] = true;
      }
      if (!usuarioData.containsKey('admin_atrelada_id')) {
        updatesUsuario['admin_atrelada_id'] = tenantPadraoId;
      }
      if (!usuarioData.containsKey('dev_master')) {
        updatesUsuario['dev_master'] = devMaster;
      }

      if (updatesUsuario.isNotEmpty) {
        await usuarioRef.set(updatesUsuario, SetOptions(merge: true));
      }
    }

    await _sincronizarIndiceHumanoUsuario(
      uid: uid,
      email: email,
      nomeCliente: nomePadrao,
      tipo: usuarioSnap.data()?['tipo'] as String? ?? tipoPadrao,
      aprovado: usuarioSnap.data()?['aprovado'] as bool? ?? aprovadoPadrao,
    );

    if (!clienteSnap.exists || clienteSnap.data() == null) {
      await clienteRef.set({
        'uid': uid,
        'cliente_nome': nomePadrao,
        'whatsapp': '',
        'saldo_sessoes': 0,
        'favoritos': <String>[],
        'endereco': '',
        'historico_medico': '',
        'alergias': '',
        'medicamentos': '',
        'cirurgias': '',
        'anamnese_ok': false,
      }, SetOptions(merge: true));
      return;
    }

    final clienteData = clienteSnap.data()!;
    final updatesCliente = <String, dynamic>{};

    final nomeClienteAtual =
        (clienteData['cliente_nome'] as String? ??
                clienteData['nome'] as String? ??
                '')
            .trim();

    if (nomeClienteAtual.isEmpty) updatesCliente['cliente_nome'] = nomePadrao;
    if (!clienteData.containsKey('whatsapp')) updatesCliente['whatsapp'] = '';
    if (!clienteData.containsKey('favoritos')) {
      updatesCliente['favoritos'] = <String>[];
    }
    if (!clienteData.containsKey('endereco')) updatesCliente['endereco'] = '';
    if (!clienteData.containsKey('historico_medico')) {
      updatesCliente['historico_medico'] = '';
    }
    if (!clienteData.containsKey('alergias')) updatesCliente['alergias'] = '';
    if (!clienteData.containsKey('medicamentos')) {
      updatesCliente['medicamentos'] = '';
    }
    if (!clienteData.containsKey('cirurgias')) updatesCliente['cirurgias'] = '';
    if (!clienteData.containsKey('anamnese_ok')) {
      updatesCliente['anamnese_ok'] = false;
    }

    if (updatesCliente.isNotEmpty) {
      await clienteRef.set(updatesCliente, SetOptions(merge: true));
    }
  }

  Stream<List<UsuarioModel>> getUsuariosPendentes() {
    return _db
        .collection('usuarios')
        .where('aprovado', isEqualTo: false)
        .where('tipo', isEqualTo: 'cliente')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UsuarioModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> aprovarUsuario(String uid) async {
    final usuarioRef = await _buscarUsuarioRefPorUid(uid);
    if (usuarioRef == null) {
      throw StateError('Usuario nao encontrado para aprovacao: $uid');
    }

    final usuarioSnap = await usuarioRef.get();
    final usuarioData = usuarioSnap.data() ?? <String, dynamic>{};
    final nomeCliente =
        (usuarioData['nome_cliente'] as String? ??
                usuarioData['nome'] as String? ??
                'Cliente')
            .trim();
    final email = (usuarioData['email'] as String? ?? '').trim();
    final whatsapp = (usuarioData['whatsapp'] as String? ?? '').trim();
    final adminAtreladaId =
        (usuarioData['admin_atrelada_id'] as String? ??
                await getAdministradoraPadraoAtreladaId())
            .trim();

    await usuarioRef.set({
      'aprovado': true,
      'nome_cliente': nomeCliente,
      'email_normalizado': _normalizarEmail(email),
      'nome_cliente_normalizado': _normalizarNomeBusca(nomeCliente),
      'admin_atrelada_id': adminAtreladaId,
    }, SetOptions(merge: true));

    await _db.collection('clientes').doc(uid).set({
      'uid': uid,
      'cliente_nome': nomeCliente,
      'whatsapp': whatsapp,
      'saldo_sessoes': 0,
      'favoritos': <String>[],
      'endereco': '',
      'historico_medico': '',
      'alergias': '',
      'medicamentos': '',
      'cirurgias': '',
      'anamnese_ok': false,
    }, SetOptions(merge: true));

    await _sincronizarIndiceHumanoUsuario(
      uid: uid,
      email: email,
      nomeCliente: nomeCliente,
      tipo: 'cliente',
      aprovado: true,
    );
  }

  Future<void> atualizarToken(String uid, String token) async {
    final usuarioRef = await _buscarUsuarioRefPorUid(uid);
    if (usuarioRef == null) return;

    await usuarioRef.update({'fcm_token': token});
  }

  Future<void> atualizarPermissaoVisualizacao(String uid, bool permitir) async {
    final usuarioRef = await _buscarUsuarioRefPorUid(uid);
    if (usuarioRef == null) return;

    await usuarioRef.update({'visualiza_todos': permitir});
  }

  Future<void> atualizarTemaUsuario(String uid, String theme) async {
    final usuarioRef = await _buscarUsuarioRefPorUid(uid);
    if (usuarioRef == null) return;

    await usuarioRef.update({'theme': theme});
  }

  // --- Agendamentos ---
  Future<void> salvarAgendamento(Agendamento agendamento) async {
    // RF009: Snapshotting para Integridade Histórica
    // Antes de salvar, buscamos os dados atuais do cliente para "congelar" no agendamento
    final clienteDoc = await _db
        .collection('clientes')
        .doc(agendamento.idCliente)
        .get();
    final clienteData = clienteDoc.data();
    final administradoraPadrao = await getAdministradoraPadraoAtreladaId();

    final dadosParaSalvar = agendamento.toMap();

    if (clienteData != null) {
      dadosParaSalvar['cliente_nome_snapshot'] =
          clienteData['cliente_nome'] ??
          clienteData['nome'] ??
          'Cliente Sem Nome';
      dadosParaSalvar['cliente_telefone_snapshot'] =
          clienteData['whatsapp'] ?? '';
    } else {
      dadosParaSalvar['cliente_nome_snapshot'] = 'Cliente Desconhecido';
    }

    dadosParaSalvar['administradora_atrelada'] =
        agendamento.administradoraAtrelada ?? administradoraPadrao;

    // O toMap() já inclui 'data_criacao' automaticamente
    await _db.collection('agendamentos').add(dadosParaSalvar);
  }

  Future<Agendamento?> buscarAgendamentoAtivoNoHorario(
    DateTime dataHora,
  ) async {
    final snapshot = await _db
        .collection('agendamentos')
        .where('data_hora', isEqualTo: Timestamp.fromDate(dataHora))
        .get();

    for (final doc in snapshot.docs) {
      final agendamento = Agendamento.fromMap(doc.data(), id: doc.id);
      final status = agendamento.status;
      final ocupado =
          status != 'cancelado' &&
          status != 'cancelado_tardio' &&
          status != 'recusado';
      if (ocupado) {
        return agendamento;
      }
    }

    return null;
  }

  // Retorna um Stream para atualização em tempo real
  Stream<List<Agendamento>> getAgendamentos() {
    return _db
        .collection('agendamentos')
        .orderBy('data_hora')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Agendamento.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Stream<List<Agendamento>> getAgendamentosDoCliente(String uid) {
    return _db
        .collection('agendamentos')
        .where('cliente_id', isEqualTo: uid)
        .orderBy('data_hora', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Agendamento.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Future<void> atualizarStatusAgendamento(
    String id,
    String novoStatus, {
    String? clienteId,
  }) async {
    // Se estiver aprovando, tenta descontar do pacote
    if (novoStatus == 'aprovado' && clienteId != null) {
      final usuarioClienteRef = await _buscarUsuarioRefPorUid(clienteId);

      await _db.runTransaction((transaction) async {
        final clienteRef = _db.collection('clientes').doc(clienteId);
        final clienteDoc = await transaction.get(clienteRef);

        if (clienteDoc.exists) {
          final saldo = clienteDoc.data()?['saldo_sessoes'] ?? 0;
          if (saldo > 0) {
            transaction.update(clienteRef, {'saldo_sessoes': saldo - 1});
          }
        }

        final agendamentoRef = _db.collection('agendamentos').doc(id);
        transaction.update(agendamentoRef, {
          'status': novoStatus,
        }); // statusAgendamento no map

        // NOTA: O envio de notificação push foi movido para Cloud Functions (Backend)
        // para evitar expor a FCM Server Key no aplicativo e garantir segurança.
        // A função 'notificarAprovacaoAgendamento' no Firebase observará a mudança de status.
        // Envio de Notificação Push Real
        if (usuarioClienteRef != null) {
          final usuarioDoc = await transaction.get(usuarioClienteRef);
          final token = usuarioDoc.data()?['fcm_token'];
          if (token != null) {
            // Chama o método de envio (fora da transação pois é async/http)
            // Usamos Future.microtask para não bloquear a transação
            Future.microtask(
              () => enviarNotificacaoPush(
                token,
                AppStrings.notifAgendamentoAprovadoTitulo,
                AppStrings.notifAgendamentoAprovadoCorpo,
              ),
            );
          }
        }

        // Registrar Log na transação (ou logo após)
        // Como registrarLog é Future<void> fora da transaction, faremos após o commit ou aqui se usarmos a transaction para escrever em 'logs'
      });

      // Baixa automática no estoque (fora da transação do pacote para simplificar query)
      // Decrementa 1 unidade de todos os itens marcados como consumo automático
      final batch = _db.batch();
      final estoqueSnapshot = await _db
          .collection('estoque')
          .where('consumo_automatico', isEqualTo: true)
          .get();
      for (var doc in estoqueSnapshot.docs) {
        final qtdAtual = doc.data()['quantidade'] ?? 0;
        if (qtdAtual > 0) {
          batch.update(doc.reference, {'quantidade': qtdAtual - 1});
        }
      }
      await batch.commit();
    } else {
      await _db.collection('agendamentos').doc(id).update({
        'status': novoStatus,
      });
    }
  }

  // --- Lembretes Manuais (Cloud Functions) ---
  Future<Map<String, dynamic>> dispararLembretes({int horas = 24}) async {
    final callable = _functions.httpsCallable('enviarLembretesManual');
    final result = await callable.call(<String, dynamic>{'horas': horas});
    return Map<String, dynamic>.from(result.data as Map);
  }

  // --- Lista de Espera ---
  Future<void> toggleListaEspera(
    String agendamentoId,
    String uid,
    bool entrar,
  ) async {
    final usuario = await getUsuario(uid);
    final nomeCliente = (usuario?.nomeCliente ?? usuario?.nome ?? 'Cliente')
        .trim();
    final agendamentoRef = _db.collection('agendamentos').doc(agendamentoId);

    await _db.runTransaction((transaction) async {
      final agendamentoSnap = await transaction.get(agendamentoRef);
      if (!agendamentoSnap.exists || agendamentoSnap.data() == null) {
        return;
      }

      final data = agendamentoSnap.data()!;
      final filaAtual = List<String>.from(
        data['lista_espera'] ?? const <String>[],
      );
      final detalhesRaw = List<dynamic>.from(
        data['lista_espera_detalhes'] ?? const <dynamic>[],
      );
      final detalhes = detalhesRaw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      if (entrar) {
        if (!filaAtual.contains(uid)) {
          filaAtual.add(uid);
          detalhes.add({
            'uid': uid,
            'nome_cliente': nomeCliente,
            'prioridade': filaAtual.length,
            'entrada_em': Timestamp.now(),
          });
        }
      } else {
        filaAtual.removeWhere((item) => item == uid);
        detalhes.removeWhere((item) => item['uid'] == uid);
      }

      for (var i = 0; i < detalhes.length; i++) {
        detalhes[i]['prioridade'] = i + 1;
      }

      transaction.update(agendamentoRef, {
        'lista_espera': filaAtual,
        'lista_espera_detalhes': detalhes,
      });
    });
  }

  Future<void> cancelarAgendamento(
    String id,
    String motivo,
    String status,
  ) async {
    await _db.collection('agendamentos').doc(id).update({
      'status': status,
      'motivo_cancelamento': motivo,
    });
    await registrarLog(
      'cancelamento',
      'Agendamento $id cancelado. Motivo: $motivo',
    );
  }

  // --- Avaliacao ---
  Future<void> avaliarAgendamento(
    String id,
    int nota,
    String comentario,
  ) async {
    await _db.collection('agendamentos').doc(id).update({
      'avaliacao': nota,
      'comentario_avaliacao': comentario,
    });
  }

  // --- Chat (Agendamento) ---
  Future<void> enviarMensagem(
    String agendamentoId,
    String texto,
    String autorId, {
    String tipo = 'texto',
  }) async {
    final mensagem = ChatMensagem(
      texto: texto,
      tipo: tipo,
      autorId: autorId,
      dataHora: DateTime.now(),
      lida: false,
    );

    await _db
        .collection('agendamentos')
        .doc(agendamentoId)
        .collection('mensagens')
        .add(mensagem.toMap());
  }

  Stream<List<ChatMensagem>> getMensagens(String agendamentoId) {
    return _db
        .collection('agendamentos')
        .doc(agendamentoId)
        .collection('mensagens')
        .orderBy('data_hora', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMensagem.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Future<void> marcarMensagensComoLidas(
    String agendamentoId,
    String usuarioLogadoId,
  ) async {
    final batch = _db.batch();
    final snapshot = await _db
        .collection('agendamentos')
        .doc(agendamentoId)
        .collection('mensagens')
        .where('lida', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      if (doc.data()['autor_id'] != usuarioLogadoId) {
        batch.update(doc.reference, {'lida': true});
      }
    }
    await batch.commit();
  }

  Future<String> uploadArquivoChat(String agendamentoId, XFile arquivo) async {
    final nomeArquivo =
        '${DateTime.now().millisecondsSinceEpoch}_${arquivo.name}';
    final ref = FirebaseStorage.instance.ref().child(
      'chats/$agendamentoId/$nomeArquivo',
    );
    await ref.putData(await arquivo.readAsBytes());
    return ref.getDownloadURL();
  }

  // --- Cupons ---
  Future<CupomModel?> validarCupom(String codigo) async {
    final snapshot = await _db
        .collection('cupons')
        .where('codigo', isEqualTo: codigo.toUpperCase())
        .where('ativo', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final cupom = CupomModel.fromMap(snapshot.docs.first.data());
    if (cupom.validade.isAfter(DateTime.now())) {
      return cupom;
    }
    return null;
  }

  Future<void> enviarNotificacaoPush(
    String token,
    String titulo,
    String corpo,
  ) async {
    final callableName = _pushNotificationFunctionName();
    final proxyUrl = _pushNotificationProxyUrl();

    if (callableName.isEmpty && proxyUrl.isEmpty) {
      debugPrint(
        'Push nao enviado: configure PUSH_NOTIFICATION_FUNCTION_NAME ou '
        'PUSH_NOTIFICATION_PROXY_URL no backend.',
      );
      return;
    }

    final payload = <String, dynamic>{
      'token': token,
      'titulo': titulo,
      'corpo': corpo,
      'notification': {'title': titulo, 'body': corpo},
    };

    try {
      if (callableName.isNotEmpty) {
        final callable = _functions.httpsCallable(callableName);
        await callable.call(payload);
        return;
      }
    } catch (e) {
      debugPrint('Erro ao enviar push via Cloud Functions: $e');
    }

    if (proxyUrl.isEmpty) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(proxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'Erro ao enviar push via proxy (${response.statusCode}): '
          '${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Erro ao enviar push via proxy: $e');
    }
  }

  // --- Financeiro ---
  Stream<List<TransacaoFinanceira>> getTransacoes() {
    return _db
        .collection('transacoes')
        .orderBy('data_pagamento', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransacaoFinanceira.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Future<void> salvarTransacao(TransacaoFinanceira transacao) async {
    await _db.collection('transacoes').add(transacao.toMap());
  }

  Future<double> calcularFaturamentoMensal(int mes, int ano) async {
    final inicio = DateTime(ano, mes, 1);
    final fim = DateTime(ano, mes + 1, 1);

    final snapshot = await _db
        .collection('transacoes')
        .where(
          'data_pagamento',
          isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
        )
        .where('data_pagamento', isLessThan: Timestamp.fromDate(fim))
        .where('status_pagamento', isEqualTo: 'pago')
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      final transacao = TransacaoFinanceira.fromMap(doc.data());
      total += transacao.valorLiquidoTransacao;
    }
    return total;
  }

  // --- LGPD / Anonimização de Conta ---
  // Não excluímos fisicamente para manter integridade financeira (agendamentos realizados),
  // mas removemos todos os dados pessoais identificáveis.
  Future<void> anonimizarConta(String uid) async {
    final batch = _db.batch();

    // 1. Anonimizar dados do Cliente (Remove PII, mantém ID e Saldo para auditoria)
    final clienteRef = _db.collection('clientes').doc(uid);
    batch.update(clienteRef, {
      'cliente_nome': 'Usuário Anonimizado (LGPD)',
      'whatsapp': '',
      'endereco': '',
      'historico_medico': 'Dados excluídos por solicitação do titular',
      'alergias': '',
      'medicamentos': '',
      'cirurgias': '',
      'anamnese_ok': false,
      // 'saldo_sessoes': Mantemos o saldo pois pode haver pendência financeira ou crédito
    });

    // 2. Anonimizar dados de Usuário (Login)
    final usuarioRef = await _buscarUsuarioRefPorUid(uid);
    if (usuarioRef != null) {
      batch.update(usuarioRef, {
        'nome': 'Anonimizado',
        'email':
            'excluido_$uid@anonimizado.com', // Email fictício para não quebrar unicidade se necessário
        'aprovado': false,
        'fcm_token': FieldValue.delete(), // Remove token de notificação
      });
    }

    // 3. Registrar na coleção específica de LGPD
    final lgpdRef = _db.collection('lgpd_logs').doc();
    batch.set(lgpdRef, {
      'usuario_id': uid,
      'acao': 'ANONIMIZACAO_CONTA',
      'data_hora': FieldValue.serverTimestamp(),
      'motivo': 'Solicitação do usuário via app',
    });

    // Nota: Agendamentos NÃO são excluídos para manter o histórico financeiro da clínica.
    await batch.commit();
  }

  // --- LGPD / Leitura de Logs ---
  Stream<List<Map<String, dynamic>>> getLgpdLogs() {
    return _db
        .collection('lgpd_logs')
        .orderBy('data_hora', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // --- Dev Tools (SQL-like Operations) ---

  // Apaga TODOS os documentos de uma coleção (Cuidado!)
  Future<void> limparColecao(String collectionPath) async {
    final batch = _db.batch();
    var snapshot = await _db.collection(collectionPath).limit(500).get();

    // Firestore limita batches a 500 operações. Em produção, precisaria de um loop while.
    // Para o TCC, assumimos que limpar 500 por vez é suficiente ou clicamos várias vezes.
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // --- Métricas / Analytics (Histórico) ---
  Future<void> salvarMetricasDiarias(Map<String, dynamic> metricas) async {
    final now = DateTime.now();
    // Usa a data atual como ID no formato brasileiro (dd-MM-yyyy)
    final id = DateFormat('dd-MM-yyyy').format(now);

    // Adiciona campo de ordenação (Timestamp) para permitir queries cronológicas,
    // já que o ID 'dd-MM-yyyy' não ordena corretamente por string.
    final dadosComOrdenacao = Map<String, dynamic>.from(metricas);
    dadosComOrdenacao['data_ordenacao'] = Timestamp.fromDate(
      DateTime(now.year, now.month, now.day),
    );

    // Salva ou atualiza (merge) as métricas do dia
    await _db
        .collection('metricas_diarias')
        .doc(id)
        .set(dadosComOrdenacao, SetOptions(merge: true));
  }

  // Retorna todos os dados de uma coleção como Lista de Mapas (para Exportação JSON/CSV)
  Future<List<Map<String, dynamic>>> getFullCollection(
    String collectionPath,
  ) async {
    final snapshot = await _db.collection(collectionPath).get();
    return snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
  }

  // Importa dados de uma lista de mapas para uma coleção (Batch Write)
  Future<void> importarColecao(
    String collectionPath,
    List<Map<String, dynamic>> dados,
  ) async {
    final batch = _db.batch();

    for (var item in dados) {
      // Remove o ID do mapa de dados para não duplicar dentro do documento,
      // mas usa ele para definir a referência do documento
      String? docId = item['id'];
      if (docId != null) {
        // Cria uma cópia para não alterar o original e remove o ID dos campos internos
        final dadosParaSalvar = Map<String, dynamic>.from(item)..remove('id');
        final docRef = _db.collection(collectionPath).doc(docId);
        batch.set(docRef, dadosParaSalvar, SetOptions(merge: true));
      }
    }

    await batch.commit();
  }

  // --- Backup Completo (JSON) ---
  Future<String> gerarBackupJson() async {
    final dados = <String, dynamic>{};

    // Exporta coleções principais
    dados['clientes'] = await getFullCollection('clientes');
    dados['agendamentos'] = await getFullCollection('agendamentos');
    dados['estoque'] = await getFullCollection('estoque');
    dados['configuracoes'] = await getFullCollection('configuracoes');

    return jsonEncode(dados);
  }

  Future<void> restaurarBackupJson(String jsonString) async {
    final dados = jsonDecode(jsonString) as Map<String, dynamic>;

    if (dados.containsKey('clientes')) {
      await importarColecao(
        'clientes',
        List<Map<String, dynamic>>.from(dados['clientes']),
      );
    }
    if (dados.containsKey('agendamentos')) {
      await importarColecao(
        'agendamentos',
        List<Map<String, dynamic>>.from(dados['agendamentos']),
      );
    }
    if (dados.containsKey('estoque')) {
      await importarColecao(
        'estoque',
        List<Map<String, dynamic>>.from(dados['estoque']),
      );
    }
    if (dados.containsKey('configuracoes')) {
      await importarColecao(
        'configuracoes',
        List<Map<String, dynamic>>.from(dados['configuracoes']),
      );
    }
  }

  // --- Relatórios (Excel) ---
  Future<Uint8List?> gerarRelatorioAgendamentosExcel() async {
    final agendamentosData = await getFullCollection('agendamentos');
    if (agendamentosData.isEmpty) return null;

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Agendamentos'];

    // Estilo para o cabeçalho
    var headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#FFC0CB'),
    );

    // Cabeçalho
    List<String> header = [
      'ID',
      'Data',
      'Cliente',
      'Telefone',
      'Tipo Serviço',
      'Status',
      'Preço',
      'Avaliação',
      'Comentário',
    ];
    sheetObject.appendRow(header.map((e) => TextCellValue(e)).toList());
    // Aplica o estilo na primeira linha
    for (var i = 0; i < header.length; i++) {
      sheetObject
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
              .cellStyle =
          headerStyle;
    }

    // Linhas de dados
    for (var agendamentoMap in agendamentosData) {
      final dataHora = (agendamentoMap['data_hora'] as Timestamp?)?.toDate();

      List<CellValue> row = [
        TextCellValue(agendamentoMap['id'] ?? ''),
        TextCellValue(
          dataHora != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(dataHora)
              : '',
        ),
        TextCellValue(
          agendamentoMap['cliente_nome_snapshot'] ?? '',
        ), // nomeClienteSnapshot
        TextCellValue(
          agendamentoMap['cliente_telefone_snapshot'] ?? '',
        ), // telefoneClienteSnapshot
        TextCellValue(agendamentoMap['tipo_massagem'] ?? ''),
        TextCellValue(agendamentoMap['status'] ?? ''),
        DoubleCellValue((agendamentoMap['preco'] as num?)?.toDouble() ?? 0.0),
        IntCellValue((agendamentoMap['avaliacao'] as num?)?.toInt() ?? 0),
        TextCellValue(agendamentoMap['comentario_avaliacao'] ?? ''),
      ];
      sheetObject.appendRow(row);
    }

    final bytes = excel.encode();
    return bytes != null ? Uint8List.fromList(bytes) : null;
  }

  // --- Logs ---
  Future<void> registrarLog(
    String tipo,
    String mensagem, {
    String? usuarioId,
  }) async {
    final log = LogModel(
      dataHora: DateTime.now(),
      tipo: tipo,
      mensagem: mensagem,
      usuarioId: usuarioId,
    );
    await _db.collection('logs').add(log.toMap());
  }

  Future<void> registrarLogPublicoSegurancaAuth(String mensagem) async {
    final log = LogModel(
      dataHora: DateTime.now(),
      tipo: 'seguranca_auth',
      mensagem: mensagem,
      usuarioId: null,
    );

    try {
      await _db.collection('logs').add(log.toMap());
    } catch (e) {
      debugPrint('Falha ao registrar log publico de seguranca: $e');
    }
  }

  Stream<List<LogModel>> getLogs() {
    return _db
        .collection('logs')
        .orderBy('data_hora', descending: true)
        .limit(100) // Limita para não carregar demais
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => LogModel.fromMap(doc.data())).toList(),
        );
  }

  // --- Change Logs (Versionamento) ---
  Stream<List<ChangeLogModel>> getChangeLogs() {
    return _db
        .collection('changelogs')
        .orderBy('data', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChangeLogModel.fromMap(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  Future<ChangeLogModel?> getLatestChangeLog() async {
    final snapshot = await _db
        .collection('changelogs')
        .orderBy('data', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return ChangeLogModel.fromMap(
        snapshot.docs.first.data(),
        docId: snapshot.docs.first.id,
      );
    }
    return null;
  }

  Future<ChangeLogModel?> getAppChangelogByVersion(String version) async {
    final normalizedVersion = _normalizarVersaoSoftware(version);

    try {
      final appDoc = await _db
          .collection('app_changelog')
          .doc(normalizedVersion)
          .get();
      if (appDoc.exists && appDoc.data() != null) {
        return ChangeLogModel.fromMap(appDoc.data()!, docId: appDoc.id);
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
    }

    final legacyDoc = await _db
        .collection('changelogs')
        .doc('v$normalizedVersion')
        .get();
    if (legacyDoc.exists && legacyDoc.data() != null) {
      return ChangeLogModel.fromMap(
        legacyDoc.data()!,
        docId: normalizedVersion,
      );
    }

    return null;
  }

  Future<ChangeLogModel?> getLatestAppChangelog() async {
    try {
      final snapshot = await _db
          .collection('app_changelog')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ChangeLogModel.fromMap(
          snapshot.docs.first.data(),
          docId: snapshot.docs.first.id,
        );
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
    }

    final config = await getAppSoftwareConfig();
    return await getAppChangelogByVersion(config.currentVersion);
  }

  Future<void> inicializarChangeLog() async {
    // Versão 1.3.0 - Interatividade e Física
    final doc130 = await _db.collection('changelogs').doc('v1.3.0').get();
    if (!doc130.exists) {
      await _db
          .collection('changelogs')
          .doc('v1.3.0')
          .set(
            ChangeLogModel(
              versao: '1.3.0',
              data: DateTime.now(),
              autor: 'Dev TCC',
              mudancas: [
                'Interatividade: Toque na tela para explodir fogos de artifício (Tema Aniversário).',
                'Física Avançada: Simulação de gravidade para confetes e neve.',
                'Efeitos Atmosféricos: Raios aleatórios no tema Tempestade.',
                'Animação Espacial: Planetas em órbita e estrelas cintilantes.',
                'Feedback Tátil (Haptic) nos botões principais.',
              ],
            ).toMap(),
          );
    }

    // Versão 1.2.0 - Temas e Visual
    final doc120 = await _db.collection('changelogs').doc('v1.2.0').get();
    if (!doc120.exists) {
      await _db
          .collection('changelogs')
          .doc('v1.2.0')
          .set(
            ChangeLogModel(
              versao: '1.2.0',
              data: DateTime.now(),
              autor: 'Dev TCC',
              mudancas: [
                'Novos Temas Visuais: Cyberpunk, Tempestade, Carnaval, Aniversário e Espaço.',
                'Efeitos de Fundo Animados: Neve, Chuva, Glitch, Confetes e Fogos de Artifício.',
                'Sons de Ambiente (Soundscapes) integrados aos temas.',
                'Controle de Mute na tela de login.',
                'Melhoria na persistência de preferências do usuário (Tema/Idioma).',
              ],
            ).toMap(),
          );
    }

    // Versão 1.1.0 - LGPD e Auditoria
    final doc110 = await _db.collection('changelogs').doc('v1.1.0').get();
    if (!doc110.exists) {
      await _db
          .collection('changelogs')
          .doc('v1.1.0')
          .set(
            ChangeLogModel(
              versao: '1.1.0',
              data: DateTime.now(),
              autor: 'Dev TCC',
              mudancas: [
                'Implementação de Anonimização de Conta (LGPD Art. 16).',
                'Criação de Logs de Auditoria para dados sensíveis.',
                'Correção de validação de CPF e máscaras de entrada.',
                'Melhoria na segurança de exclusão de conta.',
              ],
            ).toMap(),
          );
    }

    final doc = await _db.collection('changelogs').doc('v1.0.0').get();
    if (!doc.exists) {
      final initialLog = ChangeLogModel(
        versao: '1.0.0',
        data: DateTime.now(),
        autor: 'Admin',
        mudancas: [
          'Lançamento inicial do MVP.',
          'Sistema de Autenticação (Login/Cadastro).',
          'Gestão de Perfil e Anamnese (LGPD).',
          'Agendamento de sessões com fluxo de aprovação.',
          'Painel Administrativo com Relatórios.',
          'Controle de Logs do Sistema.',
          'Integração básica com WhatsApp.',
        ],
      );
      await _db.collection('changelogs').doc('v1.0.0').set(initialLog.toMap());
    }

    await _db
        .collection('app_software')
        .doc('config')
        .set(AppSoftwareConfigModel.padrao.toMap(), SetOptions(merge: true));

    await _db
        .collection('app_changelog')
        .doc(AppSoftwareConfigModel.padrao.currentVersion)
        .set(
          ChangeLogModel(
            versao: AppSoftwareConfigModel.padrao.currentVersion,
            data: DateTime.now(),
            titulo: 'Lançamento inicial',
            isCritical: true,
            autor: 'Sistema',
            mudancas: const [
              'Base inicial de governança de versões no aplicativo.',
              'Controle de bloqueio por versão mínima suportada.',
              'Exibição de changelog pós-login para clientes e administradora.',
            ],
          ).toMap(),
          SetOptions(merge: true),
        );
  }
}
