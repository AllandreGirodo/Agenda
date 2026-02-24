import 'package:cloud_firestore/cloud_firestore.dart';
import '../controller/cliente_model.dart';
import '../controller/agendamento_model.dart';
import '../usuario_model.dart';
import 'config_model.dart';
import 'estoque_model.dart';

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
            .map((doc) => Agendamento.fromMap(doc.data()!, id: doc.id))
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
    } else {
      await _db.collection('agendamentos').doc(id).update({'status': novoStatus});
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
      }
    });
  }
}