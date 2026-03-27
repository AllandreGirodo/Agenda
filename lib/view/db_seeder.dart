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
    // Cria o cadastro base unificado em usuarios/{email}
    final usuarioRef = _db.collection('usuarios').doc('cliente@teste.com');
    await usuarioRef.set({
      'id': 'cliente_teste',
      'nome': 'Cliente Teste',
      'nome_cliente': 'Cliente Teste',
      'email': 'cliente@teste.com',
      'email_normalizado': 'cliente@teste.com',
      'tipo': 'cliente',
      'aprovado': true,
      'data_cadastro': FieldValue.serverTimestamp(),
    });

    // Cria o perfil de cliente como subcoleção no mesmo cadastro
    await usuarioRef.collection('perfil').doc('cliente').set({
      'uid': 'cliente_teste',
      'cliente_nome': 'Cliente Teste',
      'email': 'cliente@teste.com',
      'nome_preferido': '',
      'ddi': '55',
      'whatsapp': _whatsappAdmin,
      'telefone_principal': _whatsappAdmin,
      'nome_contato_secundario': '',
      'telefone_secundario': '',
      'nome_indicacao': '',
      'telefone_indicacao': '',
      'categoria_origem': '',
      'presenca_agenda': false,
      'frequencia_historica_agenda': 0,
      'ultimo_horario_agendado': '',
      'ultimo_dia_semana_agendado': '',
      'sugestao_cliente_fixo': false,
      'agenda_fixa_semana': {
        'domingo': false,
        'segunda_feira': false,
        'terca_feira': false,
        'quarta_feira': false,
        'quinta_feira': false,
        'sexta_feira': false,
        'sabado': false,
      },
      'agenda_historico': {
        'horarios_recorrentes': '',
        'outro_horario_1': '',
        'outro_horario_2': '',
        'outro_horario_3': '',
        'outro_horario_4': '',
        'outro_horario_5': '',
      },
      'cpf': '',
      'cep': '',
      'saldo_sessoes': 0,
      'data_nascimento': Timestamp.fromDate(DateTime(1990, 1, 1)),
      'endereco': 'Rua Exemplo, 123',
      'historico_medico': '',
      'alergias': '',
      'medicamentos': '',
      'cirurgias': '',
      'anamnese_ok': true,
      'favoritos': [],
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