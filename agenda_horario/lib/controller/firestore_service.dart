import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controller/cliente_model.dart';
import '../controller/agendamento_model.dart';
import '../usuario_model.dart';
import 'config_model.dart';
import 'estoque_model.dart';
import 'log_model.dart';
import 'changelog_model.dart';

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

  // --- Agendamentos ---
  Future<void> salvarAgendamento(Agendamento agendamento) async {
    await _db.collection('agendamentos').add(agendamento.toMap());
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

        // Simulação de envio de notificação (Requer Backend/Cloud Functions para envio real seguro)
        // Aqui apenas logamos que o token seria usado
        // final usuarioDoc = await transaction.get(_db.collection('usuarios').doc(clienteId));
        // final token = usuarioDoc.data()?['fcm_token'];
        // if (token != null) print('Enviando push para $token: Seu agendamento foi aprovado!');
        
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

  // --- LGPD / Exclusão de Conta ---
  Future<void> excluirConta(String uid) async {
    final batch = _db.batch();

    // 1. Excluir agendamentos do cliente
    final agendamentos = await _db.collection('agendamentos').where('cliente_id', isEqualTo: uid).get();
    for (var doc in agendamentos.docs) {
      batch.delete(doc.reference);
    }

    // 2. Excluir dados do cliente e usuário
    batch.delete(_db.collection('clientes').doc(uid));
    batch.delete(_db.collection('usuarios').doc(uid));

    await batch.commit();
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