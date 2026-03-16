import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Helper para garantir que a estrutura de collections e documents
/// no Firestore seja criada automaticamente quando não existir.
///
/// Exemplo de uso:
/// ```dart
/// final helper = FirestoreStructureHelper();
/// final senha = await helper.getOrCreateValue(
///   'configuracoes/seguranca',
///   'senha_admin_ferramentas',
///   defaultValue: '',
/// );
/// ```
class FirestoreStructureHelper {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _tenantPadraoId = 'administrador_padrao_atrelado';
  static const String _tenantPadraoNome = 'administrador_padrao_atrelado';

  static String get _whatsappAdminPadrao {
    try {
      final telefoneEnv = (dotenv.env['WHATSAPP_ADMIN'] ?? '').trim();
      if (telefoneEnv.isNotEmpty) {
        return telefoneEnv;
      }
    } catch (_) {
      // dotenv pode nao estar inicializado em alguns contextos de teste.
    }

    return const String.fromEnvironment(
      'WHATSAPP_ADMIN',
      defaultValue: '',
    ).trim();
  }

  /// Busca um valor em um path específico do Firestore.
  /// Se o documento não existir, cria com valores padrão.
  ///
  /// [path] - Caminho no formato 'collection/document' ou 'collection/document/subcollection/subdocument'
  /// [field] - Nome do campo a ser buscado
  /// [defaultValue] - Valor padrão caso o campo não exista
  /// [defaultDocumentData] - Dados padrão para criar o documento completo
  Future<dynamic> getOrCreateValue(
    String path,
    String field, {
    dynamic defaultValue,
    Map<String, dynamic>? defaultDocumentData,
  }) async {
    final docRef = _db.doc(path);
    final docSnap = await docRef.get();

    if (docSnap.exists && docSnap.data() != null) {
      final data = docSnap.data()!;
      if (data.containsKey(field)) {
        return data[field];
      }
    }

    // Documento não existe ou campo não existe - criar com valores padrão
    final dataToSave = defaultDocumentData ?? {field: defaultValue};
    await docRef.set(dataToSave, SetOptions(merge: true));

    return dataToSave[field] ?? defaultValue;
  }

  /// Garante que um documento existe com dados padrão específicos.
  /// Se o documento já existir, apenas faz merge dos campos que faltam.
  ///
  /// [path] - Caminho no formato 'collection/document'
  /// [defaultData] - Mapa com os dados padrão
  Future<Map<String, dynamic>> ensureDocumentExists(
    String path,
    Map<String, dynamic> defaultData,
  ) async {
    final docRef = _db.doc(path);
    final docSnap = await docRef.get();

    if (docSnap.exists && docSnap.data() != null) {
      final existingData = docSnap.data()!;

      // Identifica campos que faltam
      final missingFields = <String, dynamic>{};
      defaultData.forEach((key, value) {
        if (!existingData.containsKey(key)) {
          missingFields[key] = value;
        }
      });

      // Se há campos faltando, adiciona com merge
      if (missingFields.isNotEmpty) {
        await docRef.set(missingFields, SetOptions(merge: true));
        return {...existingData, ...missingFields};
      }

      return existingData;
    }

    // Documento não existe - criar com dados padrão
    await docRef.set(defaultData, SetOptions(merge: true));
    return defaultData;
  }

  /// Busca múltiplos campos de um documento, criando o documento
  /// com valores padrão se não existir.
  ///
  /// [path] - Caminho no formato 'collection/document'
  /// [fields] - Lista de campos a buscar
  /// [defaultData] - Mapa completo com todos os dados padrão do documento
  Future<Map<String, dynamic>> getOrCreateFields(
    String path,
    List<String> fields,
    Map<String, dynamic> defaultData,
  ) async {
    final data = await ensureDocumentExists(path, defaultData);

    final result = <String, dynamic>{};
    for (final field in fields) {
      result[field] = data[field];
    }

    return result;
  }

  /// Busca um documento inteiro, criando-o com valores padrão se não existir.
  ///
  /// [path] - Caminho no formato 'collection/document'
  /// [defaultData] - Dados padrão para criar o documento se não existir
  Future<Map<String, dynamic>> getOrCreateDocument(
    String path,
    Map<String, dynamic> defaultData,
  ) async {
    return await ensureDocumentExists(path, defaultData);
  }

  /// Verifica se um documento existe.
  ///
  /// [path] - Caminho no formato 'collection/document'
  Future<bool> documentExists(String path) async {
    final docSnap = await _db.doc(path).get();
    return docSnap.exists;
  }

  /// Verifica se um campo específico existe em um documento.
  ///
  /// [path] - Caminho no formato 'collection/document'
  /// [field] - Nome do campo
  Future<bool> fieldExists(String path, String field) async {
    final docSnap = await _db.doc(path).get();
    if (docSnap.exists && docSnap.data() != null) {
      return docSnap.data()!.containsKey(field);
    }
    return false;
  }

  /// Inicializa toda a estrutura de configurações padrão do sistema.
  /// Útil para primeira execução ou reset.
  Future<void> inicializarEstruturaConfiguracoes() async {
    // Configurações gerais
    await ensureDocumentExists('configuracoes/geral', {
      'horario_padrao_inicio': '08:00',
      'horario_padrao_fim': '18:00',
      'intervalo_agendamentos_minutos': 60,
      'tempo_antecedencia_minima_horas': 24,
      'whatsapp_admin': _whatsappAdminPadrao,
      'administradora_padrao_atrelada': _tenantPadraoNome,
      'administradora_padrao_atrelada_id': _tenantPadraoId,
      'tempo_bloqueio_noturno_inicio': '22:00',
      'tempo_bloqueio_noturno_fim': '06:00',
      'inicio_sono': 22,
      'fim_sono': 6,
      'preco_sessao': 100.0,
      'biometria_ativa': true,
      'chat_ativo': true,
      'recibo_leitura': true,
      'status_campo_cupom': 1,
      'horas_antecedencia_cancelamento': 24.0,
      'campos_obrigatorios': {
        'whatsapp': true,
        'endereco': false,
        'data_nascimento': true,
        'historico_medico': false,
        'alergias': false,
        'medicamentos': false,
        'cirurgias': false,
        'termos_uso': true,
      },
    });

    // Configuração geral por tenant (multitenancy).
    await ensureDocumentExists('configuracoes_gerais/$_tenantPadraoId', {
      'id': _tenantPadraoId,
      'nome_exibicao': _tenantPadraoNome,
      'nome_normalizado': _tenantPadraoNome.toLowerCase(),
      'ativo': true,
      'atualizado_em': FieldValue.serverTimestamp(),
    });

    // Configurações de segurança
    await ensureDocumentExists('configuracoes/seguranca', {
      'senha_admin_ferramentas': '',
      'tentativas_login_max': 3,
      'tempo_bloqueio_minutos': 15,
    });

    // Configurações de serviços
    await ensureDocumentExists('configuracoes/servicos', {
      'tipos_massagem': [
        'relaxante',
        'drenagem_linfatica',
        'terapeutica',
        'desportiva',
        'pedras_quentes',
      ],
      'tipos_massagem_ids': [
        'relaxante',
        'drenagem_linfatica',
        'terapeutica',
        'desportiva',
        'pedras_quentes',
      ],
      'duracao_padrao_minutos': 60,
      'preco_padrao': 150.0,
    });

    // Configurações de notificações
    await ensureDocumentExists('configuracoes/notificacoes', {
      'lembrete_antecedencia_horas': 24,
      'enviar_confirmacao_agendamento': true,
      'enviar_lembrete_automatico': true,
    });

    // Configurações de pagamento
    await ensureDocumentExists('configuracoes/pagamento', {
      'aceita_pix': true,
      'aceita_dinheiro': true,
      'aceita_cartao': true,
      'taxa_cancelamento_percent': 50,
      'prazo_cancelamento_horas': 24,
    });
  }

  Future<void> inicializarGovernancaSoftware() async {
    await ensureDocumentExists('app_software/config', {
      'current_version': '1.0.0.0',
      'min_required_version': '1.0.0.0',
    });

    await ensureDocumentExists('app_changelog/1.0.0.0', {
      'version_number': '1.0.0.0',
      'timestamp': FieldValue.serverTimestamp(),
      'title': 'Lançamento inicial',
      'modifications': [
        'Base inicial da Agenda Massoterapia.',
        'Fluxo de autenticação e aprovação de cadastro.',
        'Governança de versão com changelog por release.',
      ],
      'is_critical': true,
      // Compatibilidade com schema legado de changelog.
      'versao': '1.0.0.0',
      'data': FieldValue.serverTimestamp(),
      'mudancas': [
        'Base inicial da Agenda Massoterapia.',
        'Fluxo de autenticação e aprovação de cadastro.',
        'Governança de versão com changelog por release.',
      ],
      'autor': 'Sistema',
    });
  }

  /// Inicializa a estrutura completa do sistema (todas as collections).
  /// Garante que documentos essenciais existam com valores padrão.
  Future<void> inicializarSistemaCompleto() async {
    // 1. Configurações
    await inicializarEstruturaConfiguracoes();

    // 2. Governança de versão do aplicativo
    await inicializarGovernancaSoftware();

    // 3. Collections vazias (apenas para garantir que existam)
    // Nota: Firestore cria collections automaticamente no primeiro write,
    // este método apenas documenta a estrutura esperada
  }

  /// Retorna um mapa com todos os valores padrão de configuração geral.
  static Map<String, dynamic> getConfigGeralPadrao() {
    return {
      'horario_padrao_inicio': '08:00',
      'horario_padrao_fim': '18:00',
      'intervalo_agendamentos_minutos': 60,
      'tempo_antecedencia_minima_horas': 24,
      'whatsapp_admin': _whatsappAdminPadrao,
      'administradora_padrao_atrelada': _tenantPadraoNome,
      'administradora_padrao_atrelada_id': _tenantPadraoId,
      'tempo_bloqueio_noturno_inicio': '22:00',
      'tempo_bloqueio_noturno_fim': '06:00',
      'inicio_sono': 22,
      'fim_sono': 6,
      'preco_sessao': 100.0,
      'biometria_ativa': true,
      'chat_ativo': true,
      'recibo_leitura': true,
      'status_campo_cupom': 1,
      'horas_antecedencia_cancelamento': 24.0,
      'campos_obrigatorios': {
        'whatsapp': true,
        'endereco': false,
        'data_nascimento': true,
        'historico_medico': false,
        'alergias': false,
        'medicamentos': false,
        'cirurgias': false,
        'termos_uso': true,
      },
    };
  }

  /// Retorna um mapa com todos os valores padrão de configuração de segurança.
  static Map<String, dynamic> getConfigSegurancaPadrao() {
    return {
      'senha_admin_ferramentas': '',
      'tentativas_login_max': 3,
      'tempo_bloqueio_minutos': 15,
    };
  }

  /// Retorna um mapa com todos os valores padrão de configuração de serviços.
  static Map<String, dynamic> getConfigServicosPadrao() {
    return {
      'tipos_massagem': [
        'relaxante',
        'drenagem_linfatica',
        'terapeutica',
        'desportiva',
        'pedras_quentes',
      ],
      'tipos_massagem_ids': [
        'relaxante',
        'drenagem_linfatica',
        'terapeutica',
        'desportiva',
        'pedras_quentes',
      ],
      'duracao_padrao_minutos': 60,
      'preco_padrao': 150.0,
    };
  }

  /// Retorna um mapa com todos os valores padrão de configuração de notificações.
  static Map<String, dynamic> getConfigNotificacoesPadrao() {
    return {
      'lembrete_antecedencia_horas': 24,
      'enviar_confirmacao_agendamento': true,
      'enviar_lembrete_automatico': true,
    };
  }

  /// Retorna um mapa com todos os valores padrão de configuração de pagamento.
  static Map<String, dynamic> getConfigPagamentoPadrao() {
    return {
      'aceita_pix': true,
      'aceita_dinheiro': true,
      'aceita_cartao': true,
      'taxa_cancelamento_percent': 50,
      'prazo_cancelamento_horas': 24,
    };
  }
}
