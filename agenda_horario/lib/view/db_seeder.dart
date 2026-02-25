import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DbSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Popula o banco de dados com dados fictícios para teste.
  /// ATENÇÃO: Use apenas em ambiente de desenvolvimento.
  static Future<void> popularBancoDados() async {
    try {
      debugPrint('Iniciando população do banco de dados...');

      // 1. Criar Clientes Fictícios
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
        await _db.collection('clientes').doc(c['uid'] as String).set(c);
        // Cria também o usuário correspondente para login funcionar visualmente nas listas
        await _db.collection('usuarios').doc(c['uid'] as String).set({
          'id': c['uid'],
          'nome': c['nome'],
          'email': '${c['uid']}@teste.com',
          'tipo': 'cliente',
          'aprovado': true,
          'data_cadastro': DateTime.now(),
        });
      }

      // 2. Criar Agendamentos
      final agora = DateTime.now();
      final agendamentos = [
        {
          'cliente_id': 'teste_cliente_1',
          'data_hora': agora.add(const Duration(days: 1, hours: 2)), // Amanhã
          'status': 'aprovado',
          'tipo': 'Massagem Relaxante',
          'lista_espera': [],
        },
        {
          'cliente_id': 'teste_cliente_2',
          'data_hora': agora.add(const Duration(days: 2, hours: 4)), // Depois de amanhã
          'status': 'pendente',
          'tipo': 'Drenagem Linfática',
          'lista_espera': [],
        },
      ];

      for (var a in agendamentos) {
        await _db.collection('agendamentos').add(a);
      }

      // 3. Criar Estoque
      await _db.collection('estoque').add({
        'nome': 'Creme de Massagem Neutro',
        'quantidade': 10,
        'consumo_automatico': true,
        'unidade': 'potes'
      });

      debugPrint('Banco de dados populado com sucesso!');
    } catch (e) {
      debugPrint('Erro ao popular banco: $e');
    }
  }
}