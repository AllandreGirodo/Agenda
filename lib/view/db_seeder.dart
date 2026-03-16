import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DbSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String get _whatsappAdmin {
    try {
      final telefoneEnv = (dotenv.env['WHATSAPP_ADMIN'] ?? '').trim();
      if (telefoneEnv.isNotEmpty) {
        return telefoneEnv;
      }
    } catch (_) {
      // dotenv pode nao estar inicializado em alguns contextos de teste.
    }

    return const String.fromEnvironment('WHATSAPP_ADMIN', defaultValue: '')
        .trim();
  }

  static Future<void> seedCupons() async {
    await _db.collection('cupons').doc('BEMVINDO').set({
      'codigo': 'BEMVINDO',
      'tipo': 'porcentagem',
      'valor': 10.0,
      'ativo': true,
      'validade': Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
    });
  }

  static Future<void> seedClientes() async {
    // Cria um cliente de teste
    await _db.collection('clientes').doc('cliente_teste').set({
      'uid': 'cliente_teste',
      'cliente_nome': 'Cliente Teste',
      'email': 'cliente@teste.com',
      'whatsapp': _whatsappAdmin,
      'saldo_sessoes': 0,
      'data_nascimento': '01/01/1990',
      'endereco': 'Rua Exemplo, 123',
      'historico_medico': '',
      'anamnese_ok': true,
      'favoritos': [],
    });

    // Cria o usuário de login correspondente
    await _db.collection('usuarios').doc('cliente_teste').set({
      'id': 'cliente_teste',
      'nome': 'Cliente Teste',
      'email': 'cliente@teste.com',
      'tipo': 'cliente',
      'aprovado': true,
      'data_cadastro': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> seedAgendamentos() async {
    await _db.collection('agendamentos').add({
      'cliente_id': 'cliente_teste',
      'cliente_nome_snapshot': 'Cliente Teste',
      'cliente_telefone_snapshot': _whatsappAdmin,
      'data_hora': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1, hours: 10))),
      'tipo': 'relaxante',
      'tipo_id': 'relaxante',
      'tipo_massagem': 'relaxante',
      'status': 'pendente',
      'preco': 120.0,
      'avaliacao': 0,
      'comentario_avaliacao': '',
      'data_criacao': FieldValue.serverTimestamp(),
      'lista_espera': [],
    });
  }

  static Future<void> seedEstoque() async {
    await _db.collection('estoque').add({
      'nome': 'Óleo de Massagem',
      'quantidade': 10,
      'unidade': 'frascos',
      'consumo_automatico': true,
      'minimo': 3,
    });
  }

  static Future<void> seedConfiguracoes() async {
    await _db.collection('configuracoes').doc('geral').set({
      'preco_sessao': 120.0,
      'antecedencia_minima_horas': 24,
      'whatsapp_admin': _whatsappAdmin,
      'chat_ativo': true,
      'em_manutencao': false,
    }, SetOptions(merge: true));

    await _db.collection('configuracoes').doc('servicos').set({
      'tipos_massagem_ids': [
        'relaxante',
        'drenagem_linfatica',
        'terapeutica',
        'desportiva',
        'pedras_quentes',
      ],
      'tipos_massagem': [
        'relaxante',
        'drenagem_linfatica',
        'terapeutica',
        'desportiva',
        'pedras_quentes',
      ],
    }, SetOptions(merge: true));
  }
}