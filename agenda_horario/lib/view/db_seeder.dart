import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../controller/firestore_service.dart';

class DbSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Método mestre que chama todos
  static Future<void> popularBancoDados() async {
    await seedClientes();
    await seedAgendamentos();
    await seedEstoque();
    await seedConfiguracoes();
    await FirestoreService().inicializarChangeLog();
  }

  static Future<void> seedClientes() async {
    try {
      debugPrint('Seeding Clientes e Usuários...');

      // Usamos IDs fixos para garantir que se rodar 2 vezes, ele apenas atualiza (Merge)
      // em vez de criar duplicatas.
      final clientes = [
        {
          'uid': 'teste_cliente_1',
          'nome': 'Maria Silva',
          'whatsapp': '5511999999999',
          'endereco': 'Rua das Flores, 123',
          'saldo_sessoes': 5,
          'historico_medico': 'Nenhum',
          'anamnese_ok': true,
        },
        {
          'uid': 'teste_cliente_2',
          'nome': 'João Souza',
          'whatsapp': '5511888888888',
          'endereco': 'Av. Paulista, 1000',
          'saldo_sessoes': 0,
          'historico_medico': 'Dor nas costas',
          'anamnese_ok': true,
        },
      ];

      for (var c in clientes) {
        // SetOptions(merge: true) garante que se o dado já existe, não sobrescreve tudo, apenas atualiza
        await _db.collection('clientes').doc(c['uid'] as String).set(c, SetOptions(merge: true));
        
        await _db.collection('usuarios').doc(c['uid'] as String).set({
          'id': c['uid'],
          'nome': c['nome'],
          'email': '${c['uid']}@teste.com',
          'tipo': 'cliente',
          'aprovado': true,
          // Não sobrescreve data de cadastro se já existir
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Erro ao popular Clientes: $e');
    }
  }

  static Future<void> seedAgendamentos() async {
    try {
      debugPrint('Seeding Agendamentos...');
      final agora = DateTime.now();
      
      // Verifica se já existem agendamentos para não duplicar infinitamente
      final snapshot = await _db.collection('agendamentos').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        debugPrint('Agendamentos já existem. Pulando seed.');
        return;
      }

      // Cria apenas se a coleção estiver vazia
      await _db.collection('agendamentos').add({
        'cliente_id': 'teste_cliente_1',
        'data_hora': agora.add(const Duration(days: 1, hours: 2)),
        'status': 'aprovado',
        'tipo': 'Massagem Relaxante',
        'lista_espera': [],
      });
      
      await _db.collection('agendamentos').add({
        'cliente_id': 'teste_cliente_2',
        'data_hora': agora.add(const Duration(days: 2, hours: 4)),
        'status': 'pendente',
        'tipo': 'Drenagem Linfática',
        'lista_espera': [],
      });
    } catch (e) {
      debugPrint('Erro ao popular Agendamentos: $e');
    }
  }

  static Future<void> seedEstoque() async {
    try {
      debugPrint('Seeding Estoque...');
      // Verifica duplicidade pelo nome
      final query = await _db.collection('estoque').where('nome', isEqualTo: 'Creme de Massagem Neutro').get();
      
      if (query.docs.isEmpty) {
        await _db.collection('estoque').add({
          'nome': 'Creme de Massagem Neutro',
          'quantidade': 10,
          'consumo_automatico': true,
          'unidade': 'potes'
        });
      }
    } catch (e) {
      debugPrint('Erro ao popular Estoque: $e');
    }
  }

  static Future<void> seedConfiguracoes() async {
    try {
      await _db.collection('configuracoes').doc('geral').set({
        'preco_sessao': 120.0,
        'horas_antecedencia_cancelamento': 24,
      }, SetOptions(merge: true));
      
      await _db.collection('configuracoes').doc('servicos').set({
        'tipos': ['Massagem Relaxante', 'Drenagem Linfática', 'Shiatsu', 'Reflexologia']
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erro ao popular Configurações: $e');
    }
  }
}