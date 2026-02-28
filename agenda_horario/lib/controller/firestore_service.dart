import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:agenda/controller/cliente_model.dart';
import 'package:agenda/controller/agendamento_model.dart';
import 'package:agenda/controller/transacao_model.dart';
import 'package:agenda/usuario_model.dart';
import 'package:agenda/controller/config_model.dart';
import 'package:agenda/controller/estoque_model.dart';
import 'package:agenda/controller/log_model.dart';
import 'package:agenda/controller/changelog_model.dart';
import 'package:agenda/controller/cupom_model.dart';
import 'package:agenda/view/app_strings.dart';
import 'package:agenda/controller/chat_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Clientes ---
  Future<void> salvarCliente(Cliente cliente) async {
    // Usa o UID como ID do documento para facilitar a busca
    await _db.collection('clientes').doc(cliente.uid).set(cliente.toMap());
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
    return _db.collection('clientes')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Cliente.fromMap(doc.data()))
            .toList());
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
      final favoritos = List<String>.from(doc.data()?['favoritos'] ?? []);
      if (favoritos.contains(tipo)) {
        favoritos.remove(tipo);
      } else {
        favoritos.add(tipo);
      }
      await docRef.update({'favoritos': favoritos});
    }
  }

  // --- Estoque ---
  Stream<List<ItemEstoque>> getEstoque() {
    return _db.collection('estoque').orderBy('nome').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ItemEstoque.fromMap(doc.data(), id: doc.id)).toList());
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
    await _db.collection('configuracoes').doc('geral').set(config.toMap());
  }

  Future<ConfigModel> getConfiguracao() async {
    final doc = await _db.collection('configuracoes').doc('geral').get();
    if (doc.exists && doc.data() != null) {
      return ConfigModel.fromMap(doc.data()!);
    }
    return ConfigModel(camposObrigatorios: ConfigModel.padrao);
  }

  // Busca o telefone do admin (WhatsApp) configurado, ou retorna um padrão se não existir
  Future<String> getTelefoneAdmin() async {
    final doc = await _db.collection('configuracoes').doc('geral').get();
    if (doc.exists && doc.data() != null) {
      return doc.data()!['whatsapp_admin'] as String? ?? '5516999999999';
    }
    return '5516999999999';
  }

  // Salva o telefone do admin (Conectar este método a um TextField na tela de Admin)
  Future<void> salvarTelefoneAdmin(String telefone) async {
    await _db.collection('configuracoes').doc('geral').set({'whatsapp_admin': telefone}, SetOptions(merge: true));
  }

  // Busca a lista de tipos de massagem configurados no banco
  Future<List<String>> getTiposMassagem() async {
    final doc = await _db.collection('configuracoes').doc('servicos').get();
    if (doc.exists && doc.data() != null) {
      return List<String>.from(doc.data()!['tipos'] ?? []);
    }
    return ['Massagem Relaxante', 'Drenagem Linfática', 'Massagem Terapêutica']; // Fallback padrão
  }

  // --- Usuarios (Login) ---
  Future<UsuarioModel?> getUsuario(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UsuarioModel.fromMap(doc.data()!);
    }
    return null;
  }

  Stream<UsuarioModel?> getUsuarioStream(String uid) {
    return _db.collection('usuarios').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UsuarioModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  Future<void> salvarUsuario(UsuarioModel usuario) async {
    await _db.collection('usuarios').doc(usuario.id).set(usuario.toMap());
  }

  Stream<List<UsuarioModel>> getUsuariosPendentes() {
    return _db.collection('usuarios')
        .where('aprovado', isEqualTo: false)
        .where('tipo', isEqualTo: 'cliente')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UsuarioModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> aprovarUsuario(String uid) async {
    await _db.collection('usuarios').doc(uid).update({'aprovado': true});
  }

  Future<void> atualizarToken(String uid, String token) async {
    await _db.collection('usuarios').doc(uid).update({'fcm_token': token});
  }

  Future<void> atualizarPermissaoVisualizacao(String uid, bool permitir) async {
    await _db.collection('usuarios').doc(uid).update({'visualiza_todos': permitir});
  }

  Future<void> atualizarTemaUsuario(String uid, String theme) async {
    await _db.collection('usuarios').doc(uid).update({'theme': theme});
  }

  // --- Agendamentos ---
  Future<void> salvarAgendamento(Agendamento agendamento) async {
    // RF009: Snapshotting para Integridade Histórica
    // Antes de salvar, buscamos os dados atuais do cliente para "congelar" no agendamento
    final clienteDoc = await _db.collection('clientes').doc(agendamento.clienteId).get();
    final clienteData = clienteDoc.data();

    final dadosParaSalvar = agendamento.toMap();
    
    if (clienteData != null) {
      dadosParaSalvar['cliente_nome_snapshot'] = clienteData['nome'];
      dadosParaSalvar['cliente_telefone_snapshot'] = clienteData['whatsapp'];
    } else {
      dadosParaSalvar['cliente_nome_snapshot'] = 'Cliente Desconhecido';
    }

    // O toMap() já inclui 'data_criacao' automaticamente
    await _db.collection('agendamentos').add(dadosParaSalvar);
  }

  // Retorna um Stream para atualização em tempo real
  Stream<List<Agendamento>> getAgendamentos() {
    return _db.collection('agendamentos')
        .orderBy('data_hora')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Agendamento.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  Stream<List<Agendamento>> getAgendamentosDoCliente(String uid) {
    return _db.collection('agendamentos')
        .where('cliente_id', isEqualTo: uid)
        .orderBy('data_hora', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Agendamento.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  Future<void> atualizarStatusAgendamento(String id, String novoStatus, {String? clienteId}) async {
    // Se estiver aprovando, tenta descontar do pacote
    if (novoStatus == 'aprovado' && clienteId != null) {
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
        transaction.update(agendamentoRef, {'status': novoStatus});

        // Envio de Notificação Push Real
        final usuarioDoc = await transaction.get(_db.collection('usuarios').doc(clienteId));
        final token = usuarioDoc.data()?['fcm_token'];
        if (token != null) {
          // Chama o método de envio (fora da transação pois é async/http)
          // Usamos Future.microtask para não bloquear a transação
          Future.microtask(() => enviarNotificacaoPush(token, AppStrings.notifAgendamentoAprovadoTitulo, AppStrings.notifAgendamentoAprovadoCorpo));
        }
        
        // Registrar Log na transação (ou logo após)
        // Como registrarLog é Future<void> fora da transaction, faremos após o commit ou aqui se usarmos a transaction para escrever em 'logs'
      });

      // Baixa automática no estoque (fora da transação do pacote para simplificar query)
      // Decrementa 1 unidade de todos os itens marcados como consumo automático
      final batch = _db.batch();
      final estoqueSnapshot = await _db.collection('estoque').where('consumo_automatico', isEqualTo: true).get();
      
      for (var doc in estoqueSnapshot.docs) {
        // FieldValue.increment(-1) garante atomicidade e permite ficar negativo (histórico)
        batch.update(doc.reference, {'quantidade': FieldValue.increment(-1)});
      }
      await batch.commit();
      
      await registrarLog('aprovacao', 'Agendamento $id aprovado. Estoque baixado.', usuarioId: clienteId);
      
    } else {
      await _db.collection('agendamentos').doc(id).update({'status': novoStatus});
      await registrarLog('atualizacao', 'Status do agendamento $id alterado para $novoStatus', usuarioId: clienteId);
    }
  }

  // --- Notificações Push (FCM) ---
  Future<void> enviarNotificacaoPush(String token, String titulo, String corpo) async {
    try {
      // ATENÇÃO: Em produção, mova isso para uma Cloud Function para proteger sua Server Key.
      // Para o TCC, você pode usar a chave de servidor (Legacy) do console do Firebase.
      const String serverKey = 'SUA_SERVER_KEY_AQUI'; 
      
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{'body': corpo, 'title': titulo},
            'priority': 'high',
            'data': <String, dynamic>{'click_action': 'FLUTTER_NOTIFICATION_CLICK', 'id': '1', 'status': 'done'},
            'to': token,
          },
        ),
      );
    } catch (e) {
      debugPrint('Erro ao enviar push: $e');
    }
  }

  // --- Lista de Espera ---
  Future<void> toggleListaEspera(String agendamentoId, String uid, bool entrar) async {
    if (entrar) {
      await _db.collection('agendamentos').doc(agendamentoId).update({
        'lista_espera': FieldValue.arrayUnion([uid])
      });
    } else {
      await _db.collection('agendamentos').doc(agendamentoId).update({
        'lista_espera': FieldValue.arrayRemove([uid])
      });
      await registrarLog('espera', 'Usuário $uid saiu da lista de espera do agendamento $agendamentoId', usuarioId: uid);
    }
  }

  Future<void> cancelarAgendamento(String id, String motivo, String status) async {
    await _db.runTransaction((transaction) async {
      final docRef = _db.collection('agendamentos').doc(id);
      final snapshot = await transaction.get(docRef);
      
      if (snapshot.exists) {
        transaction.update(docRef, {
          'status': status,
          'motivo_cancelamento': motivo,
        });

        // Notificar Lista de Espera
        final listaEspera = List<String>.from(snapshot.data()?['lista_espera'] ?? []);
        if (listaEspera.isNotEmpty) {
          // Aqui seria implementada a chamada real para o FCM (Cloud Functions)
          debugPrint('NOTIFICAÇÃO: Enviando alerta para ${listaEspera.length} usuários na lista de espera sobre o cancelamento.');
        }

        // Notificar Administradora
        debugPrint('NOTIFICAÇÃO: Alerta para Administradora - Agendamento cancelado. Motivo: $motivo');
        
        // O log será registrado fora da transação para simplificar, ou poderíamos adicionar uma escrita na coleção 'logs' aqui.
      }
    });
    await registrarLog('cancelamento', 'Agendamento $id cancelado. Motivo: $motivo');
  }

  // --- Avaliação ---
  Future<void> avaliarAgendamento(String id, int nota, String comentario) async {
    await _db.collection('agendamentos').doc(id).update({
      'avaliacao': nota,
      'comentario_avaliacao': comentario,
    });
  }

  // --- Chat (Agendamento) ---
  Future<void> enviarMensagem(String agendamentoId, String texto, String autorId, {String tipo = 'texto'}) async {
    final mensagem = ChatMensagem(
      texto: texto,
      tipo: tipo,
      autorId: autorId,
      dataHora: DateTime.now(),
      lida: false,
    );
    await _db.collection('agendamentos').doc(agendamentoId).collection('mensagens').add(mensagem.toMap());

    // --- Lógica de Notificação Push ---
    try {
      // 1. Obter dados do agendamento para saber quem é o cliente
      final agendamentoDoc = await _db.collection('agendamentos').doc(agendamentoId).get();
      if (!agendamentoDoc.exists) return;
      final agendamento = Agendamento.fromMap(agendamentoDoc.data()!, id: agendamentoDoc.id);

      // 2. Identificar o destinatário
      String? destinatarioUid;
      String? nomeRemetente;

      // Se o autor da mensagem é o cliente do agendamento
      if (autorId == agendamento.clienteId) {
        // O destinatário é o admin. Vamos buscar o primeiro admin.
        final adminSnapshot = await _db.collection('usuarios').where('tipo', isEqualTo: 'admin').limit(1).get();
        if (adminSnapshot.docs.isNotEmpty) {
          destinatarioUid = adminSnapshot.docs.first.id;
        }
        nomeRemetente = agendamento.clienteNomeSnapshot ?? 'Um cliente';
      } else { // Se o autor é o admin
        // O destinatário é o cliente
        destinatarioUid = agendamento.clienteId;
        nomeRemetente = 'Administradora';
      }

      if (destinatarioUid == null) return;

      // 3. Obter o token FCM do destinatário
      final usuarioDoc = await _db.collection('usuarios').doc(destinatarioUid).get();
      final token = usuarioDoc.data()?['fcm_token'] as String?;

      if (token != null) {
        await enviarNotificacaoPush(token, AppStrings.notifNovaMensagemTitulo, AppStrings.notifNovaMensagemCorpo(nomeRemetente, tipo, texto));
      }
    } catch (e) {
      debugPrint('Erro ao tentar enviar notificação de chat: $e');
    }
  }

  Stream<List<ChatMensagem>> getMensagens(String agendamentoId) {
    return _db.collection('agendamentos').doc(agendamentoId).collection('mensagens')
        .orderBy('data_hora', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ChatMensagem.fromMap(doc.data(), id: doc.id)).toList());
  }

  Future<void> marcarMensagensComoLidas(String agendamentoId, String usuarioLogadoId) async {
    final batch = _db.batch();
    final snapshot = await _db.collection('agendamentos').doc(agendamentoId).collection('mensagens')
        .where('lida', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      // Só marca como lida se a mensagem NÃO foi enviada por mim (usuário logado)
      if (doc.data()['autor_id'] != usuarioLogadoId) {
        batch.update(doc.reference, {'lida': true});
      }
    }
    await batch.commit();
  }

  // Helper para upload de arquivos
  Future<String> uploadArquivoChat(String agendamentoId, File arquivo) async {
    final nomeArquivo = '${DateTime.now().millisecondsSinceEpoch}_${arquivo.path.split('/').last}';
    final ref = FirebaseStorage.instance.ref().child('chats/$agendamentoId/$nomeArquivo');
    await ref.putFile(arquivo);
    return await ref.getDownloadURL();
  }

  // --- Cupons ---
  Future<CupomModel?> validarCupom(String codigo) async {
    final snapshot = await _db.collection('cupons')
        .where('codigo', isEqualTo: codigo.toUpperCase())
        .where('ativo', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final cupom = CupomModel.fromMap(snapshot.docs.first.data());
      if (cupom.validade.isAfter(DateTime.now())) {
        return cupom;
      }
    }
    return null;
  }

  // --- Transações Financeiras (Novo Módulo) ---
  Future<void> salvarTransacao(TransacaoFinanceira transacao) async {
    await _db.collection('transacoes_financeiras').add(transacao.toMap());
  }

  Stream<List<TransacaoFinanceira>> getTransacoes() {
    return _db.collection('transacoes_financeiras')
        .orderBy('data_pagamento', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransacaoFinanceira.fromMap(doc.data(), id: doc.id))
            .toList());
  }


  // --- LGPD / Anonimização de Conta ---
  // Não excluímos fisicamente para manter integridade financeira (agendamentos realizados),
  // mas removemos todos os dados pessoais identificáveis.
  Future<void> anonimizarConta(String uid) async {
    final batch = _db.batch();

    // 1. Anonimizar dados do Cliente (Remove PII, mantém ID e Saldo para auditoria)
    final clienteRef = _db.collection('clientes').doc(uid);
    batch.update(clienteRef, {
      'nome': 'Usuário Anonimizado (LGPD)',
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
    final usuarioRef = _db.collection('usuarios').doc(uid);
    batch.update(usuarioRef, {
      'nome': 'Anonimizado',
      'email': 'excluido_$uid@anonimizado.com', // Email fictício para não quebrar unicidade se necessário
      'aprovado': false,
      'fcm_token': FieldValue.delete(), // Remove token de notificação
    });

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
    return _db.collection('lgpd_logs')
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
    // Usa a data atual como ID (ex: 2023-10-25) para facilitar busca histórica
    final id = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Salva ou atualiza (merge) as métricas do dia
    await _db.collection('metricas_diarias').doc(id).set(metricas, SetOptions(merge: true));
  }

  // Retorna todos os dados de uma coleção como Lista de Mapas (para Exportação JSON/CSV)
  Future<List<Map<String, dynamic>>> getFullCollection(String collectionPath) async {
    final snapshot = await _db.collection(collectionPath).get();
    return snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
  }

  // Importa dados de uma lista de mapas para uma coleção (Batch Write)
  Future<void> importarColecao(String collectionPath, List<Map<String, dynamic>> dados) async {
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
    
    if (dados.containsKey('clientes')) await importarColecao('clientes', List<Map<String, dynamic>>.from(dados['clientes']));
    if (dados.containsKey('agendamentos')) await importarColecao('agendamentos', List<Map<String, dynamic>>.from(dados['agendamentos']));
    if (dados.containsKey('estoque')) await importarColecao('estoque', List<Map<String, dynamic>>.from(dados['estoque']));
    if (dados.containsKey('configuracoes')) await importarColecao('configuracoes', List<Map<String, dynamic>>.from(dados['configuracoes']));
  }

  // --- Logs ---
  Future<void> registrarLog(String tipo, String mensagem, {String? usuarioId}) async {
    final log = LogModel(
      dataHora: DateTime.now(),
      tipo: tipo,
      mensagem: mensagem,
      usuarioId: usuarioId,
    );
    await _db.collection('logs').add(log.toMap());
  }

  Stream<List<LogModel>> getLogs() {
    return _db.collection('logs')
        .orderBy('data_hora', descending: true)
        .limit(100) // Limita para não carregar demais
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LogModel.fromMap(doc.data()))
            .toList());
  }

  // --- Change Logs (Versionamento) ---
  Stream<List<ChangeLogModel>> getChangeLogs() {
    return _db.collection('changelogs')
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChangeLogModel.fromMap(doc.data()))
            .toList());
  }

  Future<ChangeLogModel?> getLatestChangeLog() async {
    final snapshot = await _db.collection('changelogs')
        .orderBy('data', descending: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return ChangeLogModel.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  Future<void> inicializarChangeLog() async {
    // Versão 1.3.0 - Interatividade e Física
    final doc130 = await _db.collection('changelogs').doc('v1.3.0').get();
    if (!doc130.exists) {
      await _db.collection('changelogs').doc('v1.3.0').set(ChangeLogModel(
        versao: '1.3.0',
        data: DateTime.now(),
        autor: 'Dev TCC',
        mudancas: [
          'Interatividade: Toque na tela para explodir fogos de artifício (Tema Aniversário).',
          'Física Avançada: Simulação de gravidade para confetes e neve.',
          'Efeitos Atmosféricos: Raios aleatórios no tema Tempestade.',
          'Animação Espacial: Planetas em órbita e estrelas cintilantes.',
          'Feedback Tátil (Haptic) nos botões principais.'
        ],
      ).toMap());
    }

    // Versão 1.2.0 - Temas e Visual
    final doc120 = await _db.collection('changelogs').doc('v1.2.0').get();
    if (!doc120.exists) {
      await _db.collection('changelogs').doc('v1.2.0').set(ChangeLogModel(
        versao: '1.2.0',
        data: DateTime.now(),
        autor: 'Dev TCC',
        mudancas: [
          'Novos Temas Visuais: Cyberpunk, Tempestade, Carnaval, Aniversário e Espaço.',
          'Efeitos de Fundo Animados: Neve, Chuva, Glitch, Confetes e Fogos de Artifício.',
          'Sons de Ambiente (Soundscapes) integrados aos temas.',
          'Controle de Mute na tela de login.',
          'Melhoria na persistência de preferências do usuário (Tema/Idioma).'
        ],
      ).toMap());
    }

    // Versão 1.1.0 - LGPD e Auditoria
    final doc110 = await _db.collection('changelogs').doc('v1.1.0').get();
    if (!doc110.exists) {
      await _db.collection('changelogs').doc('v1.1.0').set(ChangeLogModel(
        versao: '1.1.0',
        data: DateTime.now(),
        autor: 'Dev TCC',
        mudancas: [
          'Implementação de Anonimização de Conta (LGPD Art. 16).',
          'Criação de Logs de Auditoria para dados sensíveis.',
          'Correção de validação de CPF e máscaras de entrada.',
          'Melhoria na segurança de exclusão de conta.'
        ],
      ).toMap());
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
          'Integração básica com WhatsApp.'
        ],
      );
      await _db.collection('changelogs').doc('v1.0.0').set(initialLog.toMap());
    }
  }
}