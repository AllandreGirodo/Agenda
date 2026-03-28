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

class VinculoClienteCadastroStatus {
  final String emailNormalizado;
  final String vinculoIdCliente;
  final String nomeSugerido;
  final String telefoneSugerido;
  final bool possuiUsuario;
  final bool possuiCliente;
  final bool cadastroCompleto;
  final List<String> camposObrigatoriosPendentes;

  const VinculoClienteCadastroStatus({
    required this.emailNormalizado,
    required this.vinculoIdCliente,
    required this.nomeSugerido,
    required this.telefoneSugerido,
    required this.possuiUsuario,
    required this.possuiCliente,
    required this.cadastroCompleto,
    required this.camposObrigatoriosPendentes,
  });

  bool get possuiVinculo => vinculoIdCliente.trim().isNotEmpty;
}

class ContatoAprovacaoConfig {
  final String nomeAdministradoraExibicao;
  final String whatsappRedirecionamento;
  final String mensagemTemplate;

  const ContatoAprovacaoConfig({
    required this.nomeAdministradoraExibicao,
    required this.whatsappRedirecionamento,
    required this.mensagemTemplate,
  });
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static const String _tenantPadraoId = 'administrador_padrao_atrelado';
  static const String _tenantPadraoNomeExibicao = 'Administradora padrão';
  static const int _limiteSolicitacoesListaEsperaPorCliente = 5;
  static const List<String> _diasSemanaAgenda = [
    '1_domingo',
    '2_segunda',
    '3_terca',
    '4_quarta',
    '5_quinta',
    '6_sexta',
    '7_sabado',
  ];
  static const Map<String, String> _diaSemanaLegadoParaOrdenado = {
    'domingo': '1_domingo',
    'segunda_feira': '2_segunda',
    'terca_feira': '3_terca',
    'quarta_feira': '4_quarta',
    'quinta_feira': '5_quinta',
    'sexta_feira': '6_sexta',
    'sabado': '7_sabado',
  };

  Map<String, bool> _agendaFixaSemanaPadrao() {
    return {
      '1_domingo': false,
      '2_segunda': false,
      '3_terca': false,
      '4_quarta': false,
      '5_quinta': false,
      '6_sexta': false,
      '7_sabado': false,
    };
  }

  Map<String, dynamic> _agendaHistoricoPadrao() {
    return {
      'horarios_recorrentes': '',
      'outro_horario_1': '',
      'outro_horario_2': '',
      'outro_horario_3': '',
      'outro_horario_4': '',
      'outro_horario_5': '',
    };
  }

  String _nomeExibicaoTenantPadrao([String? valor]) {
    final nomeInformado = (valor ?? '').trim();
    if (nomeInformado.isEmpty) return _tenantPadraoNomeExibicao;

    final nomeNormalizado = _normalizarSlug(nomeInformado);
    if (nomeNormalizado == _tenantPadraoId && !nomeInformado.contains(' ')) {
      return _tenantPadraoNomeExibicao;
    }

    return nomeInformado;
  }

  Map<String, dynamic> _dadosPadraoCliente({
    required String uid,
    required String nomeCliente,
    String whatsapp = '',
  }) {
    return {
      'uid': uid,
      'cliente_nome': nomeCliente,
      'nome_preferido': '',
      'ddi': '55',
      'whatsapp': whatsapp,
      'telefone_principal': whatsapp,
      'nome_contato_secundario': '',
      'telefone_secundario': '',
      'nome_indicacao': '',
      'telefone_indicacao': '',
      'categoria_origem': '',
      'presenca_agenda': false,
      'frequencia_historica_agenda': 0,
      'ultima_data_agendada': null,
      'ultimo_horario_agendado': '',
      'ultimo_dia_semana_agendado': '',
      'sugestao_cliente_fixo': false,
      'agenda_fixa_semana': _agendaFixaSemanaPadrao(),
      'agenda_historico': _agendaHistoricoPadrao(),
      'cpf': '',
      'cep': '',
      'saldo_sessoes': 0,
      'favoritos': <String>[],
      'endereco': '',
      'historico_medico': '',
      'alergias': '',
      'medicamentos': '',
      'cirurgias': '',
      'anamnese_ok': false,
    };
  }

  String _normalizarTelefone(String telefone) {
    return telefone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _formatarTelefoneComMascara(String telefone) {
    final digitos = _normalizarTelefone(telefone);
    if (digitos.length >= 11) {
      final numero = digitos.substring(digitos.length - 11);
      return '(${numero.substring(0, 2)}) ${numero.substring(2, 7)}-${numero.substring(7, 11)}';
    }
    if (digitos.length == 10) {
      return '(${digitos.substring(0, 2)}) ${digitos.substring(2, 6)}-${digitos.substring(6, 10)}';
    }
    return telefone.trim();
  }

  String _normalizarDiaSemanaOrdenado(String valor) {
    final texto = valor.trim();
    if (texto.isEmpty) return '';

    if (_diasSemanaAgenda.contains(texto)) {
      return texto;
    }

    final textoNormalizado = texto.toLowerCase();
    return _diaSemanaLegadoParaOrdenado[textoNormalizado] ?? texto;
  }

  Map<String, bool> _normalizarAgendaFixaSemana(Map<String, dynamic> agendaRaw) {
    final padrao = _agendaFixaSemanaPadrao();
    final normalizado = Map<String, bool>.from(padrao);

    for (final entry in agendaRaw.entries) {
      final chaveOriginal = entry.key.toString().trim();
      final chave = _normalizarDiaSemanaOrdenado(chaveOriginal);
      if (!normalizado.containsKey(chave)) continue;
      normalizado[chave] = _valorImportacaoParaBool(entry.value);
    }

    return normalizado;
  }

  String _mensagemContatoAprovacaoTemplatePadrao() {
    return 'Olá {admin_nome}, tudo bem?\n\n'
        'Acabei de concluir meu cadastro e aguardo aprovação.\n\n'
        'Nome Completo: {cliente_nome}\n'
        'Telefone: {cliente_telefone_com_mascara}\n'
        'Email: {cliente_email}\n'
        'Data e Hora: {data_hora}\n\n'
        'Poderia confirmar para mim?';
  }

  String _normalizarEmail(String email) {
    return email.trim().toLowerCase();
  }

  String _normalizarNomeBusca(String nome) {
    return nome.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _primeiroTextoPreenchido(
    Map<String, dynamic> dados,
    List<String> chaves,
  ) {
    for (final chave in chaves) {
      final valor = (dados[chave] as String? ?? '').trim();
      if (valor.isNotEmpty) {
        return valor;
      }
    }
    return '';
  }

  bool _campoTextoPreenchido(
    Map<String, dynamic> dados,
    List<String> chaves,
  ) {
    return _primeiroTextoPreenchido(dados, chaves).isNotEmpty;
  }

  bool _campoDataPreenchida(dynamic valor) {
    if (valor == null) return false;
    if (valor is Timestamp || valor is DateTime) return true;
    if (valor is String) {
      final texto = valor.trim();
      if (texto.isEmpty) return false;
      final textoNormalizado = texto.toLowerCase();
      return textoNormalizado != 'null' && textoNormalizado != 'none';
    }
    return false;
  }

  List<String> _resolverCamposObrigatoriosPendentes({
    required Map<String, bool> camposObrigatorios,
    required Map<String, dynamic> usuarioData,
    required Map<String, dynamic> clienteData,
  }) {
    bool campoAtivo(String chave) => camposObrigatorios[chave] == true;

    final telefoneCliente = _normalizarTelefone(
      _primeiroTextoPreenchido(
        clienteData,
        const ['telefone_principal', 'whatsapp'],
      ),
    );
    final telefoneUsuario = _normalizarTelefone(
      _primeiroTextoPreenchido(
        usuarioData,
        const ['telefone_principal', 'whatsapp'],
      ),
    );

    final pendentes = <String>[];

    if (campoAtivo('whatsapp')) {
      final telefoneEfetivo =
          telefoneCliente.isNotEmpty ? telefoneCliente : telefoneUsuario;
      if (telefoneEfetivo.length < 10) {
        pendentes.add('whatsapp');
      }
    }

    if (campoAtivo('endereco') &&
        !_campoTextoPreenchido(clienteData, const ['endereco'])) {
      pendentes.add('endereco');
    }

    if (campoAtivo('data_nascimento') &&
        !_campoDataPreenchida(clienteData['data_nascimento'])) {
      pendentes.add('data_nascimento');
    }

    if (campoAtivo('historico_medico') &&
        !_campoTextoPreenchido(clienteData, const ['historico_medico'])) {
      pendentes.add('historico_medico');
    }

    if (campoAtivo('alergias') &&
        !_campoTextoPreenchido(clienteData, const ['alergias'])) {
      pendentes.add('alergias');
    }

    if (campoAtivo('medicamentos') &&
        !_campoTextoPreenchido(clienteData, const ['medicamentos'])) {
      pendentes.add('medicamentos');
    }

    if (campoAtivo('cirurgias') &&
        !_campoTextoPreenchido(clienteData, const ['cirurgias'])) {
      pendentes.add('cirurgias');
    }

    if (campoAtivo('termos_uso')) {
      final consentiuLgpd = usuarioData['lgpd_consentido'] == true;
      if (!consentiuLgpd) {
        pendentes.add('termos_uso');
      }
    }

    return pendentes;
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

  String _normalizarCabecalhoImportacao(String valor) {
    return valor
        .trim()
        .toLowerCase()
        .replaceFirst('\ufeff', '')
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[_\-.]+'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _mapearCampoImportacao(String cabecalhoNormalizado) {
    switch (cabecalhoNormalizado) {
      case 'uid':
      case 'id':
        return 'uid';
      case 'nome principal':
      case 'nome':
      case 'nome cliente':
      case 'cliente nome':
        return 'cliente_nome';
      case 'nome preferido':
        return 'nome_preferido';
      case 'ddi':
        return 'ddi';
      case 'telefone principal':
      case 'telefone':
      case 'celular':
      case 'whatsapp':
        return 'telefone_principal';
      case 'nome contato secundario':
      case 'nome secundario':
        return 'nome_contato_secundario';
      case 'telefone secundario':
        return 'telefone_secundario';
      case 'nome indicacao':
      case 'nome indicado':
        return 'nome_indicacao';
      case 'telefone indicacao':
      case 'telefone indicado':
        return 'telefone_indicacao';
      case 'categoria origem':
        return 'categoria_origem';
      case 'presenca agenda':
        return 'presenca_agenda';
      case 'frequencia historica agenda':
        return 'frequencia_historica_agenda';
      case 'ultima data agendada':
        return 'ultima_data_agendada';
      case 'ultimo horario agendado':
        return 'ultimo_horario_agendado';
      case 'ultimo dia semana agendado':
      case 'ultimo dia da semana':
        return 'ultimo_dia_semana_agendado';
      case 'sugestao cliente fixo':
        return 'sugestao_cliente_fixo';
      case 'cpf':
        return 'cpf';
      case 'cep':
        return 'cep';
      case 'data nascimento':
      case 'data de nascimento':
        return 'data_nascimento';
      case 'saldo sessoes':
        return 'saldo_sessoes';
      case 'favoritos':
        return 'favoritos';
      case 'endereco':
        return 'endereco';
      case 'historico medico':
        return 'historico_medico';
      case 'alergias':
        return 'alergias';
      case 'medicamentos':
        return 'medicamentos';
      case 'cirurgias':
        return 'cirurgias';
      case 'anamnese ok':
        return 'anamnese_ok';
      case 'horarios recorrentes':
        return 'agenda_historico.horarios_recorrentes';
      case 'outro horario 1':
        return 'agenda_historico.outro_horario_1';
      case 'outro horario 2':
        return 'agenda_historico.outro_horario_2';
      case 'outro horario 3':
        return 'agenda_historico.outro_horario_3';
      case 'outro horario 4':
        return 'agenda_historico.outro_horario_4';
      case 'outro horario 5':
        return 'agenda_historico.outro_horario_5';
      case 'domingo fixo':
        return 'agenda_fixa_semana.1_domingo';
      case 'segunda feira fixo':
        return 'agenda_fixa_semana.2_segunda';
      case 'terca feira fixo':
        return 'agenda_fixa_semana.3_terca';
      case 'quarta feira fixo':
        return 'agenda_fixa_semana.4_quarta';
      case 'quinta feira fixo':
        return 'agenda_fixa_semana.5_quinta';
      case 'sexta feira fixo':
        return 'agenda_fixa_semana.6_sexta';
      case 'sabado fixo':
        return 'agenda_fixa_semana.7_sabado';
      case 'domingo':
        return 'agenda_historico.dia_semana.1_domingo';
      case 'segunda feira':
        return 'agenda_historico.dia_semana.2_segunda';
      case 'terca feira':
        return 'agenda_historico.dia_semana.3_terca';
      case 'quarta feira':
        return 'agenda_historico.dia_semana.4_quarta';
      case 'quinta feira':
        return 'agenda_historico.dia_semana.5_quinta';
      case 'sexta feira':
        return 'agenda_historico.dia_semana.6_sexta';
      case 'sabado':
        return 'agenda_historico.dia_semana.7_sabado';
      default:
        return null;
    }
  }

  bool _valorImportacaoParaBool(dynamic valor) {
    if (valor is bool) return valor;
    if (valor is num) return valor != 0;
    final normalizado = (valor ?? '').toString().trim().toLowerCase();
    return normalizado == 'true' ||
        normalizado == '1' ||
        normalizado == 'sim' ||
        normalizado == 'yes' ||
        normalizado == 'verdadeiro';
  }

  int _valorImportacaoParaInt(dynamic valor, {int padrao = 0}) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    final parse = int.tryParse((valor ?? '').toString().trim());
    return parse ?? padrao;
  }

  List<String> _valorImportacaoParaLista(dynamic valor) {
    if (valor == null) return <String>[];

    if (valor is List) {
      return valor
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final bruto = valor.toString().trim();
    if (bruto.isEmpty) return <String>[];

    final separador = bruto.contains(';') ? ';' : ',';
    return bruto
        .split(separador)
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _normalizarLinhaImportacao(
    Map<String, dynamic> linha,
  ) {
    final resultado = <String, dynamic>{};
    final agendaFixa = <String, bool>{};
    final agendaHistorico = <String, dynamic>{};
    final historicoPorDia = <String, String>{};

    for (final entry in linha.entries) {
      final campoNormalizado = _normalizarCabecalhoImportacao(
        entry.key.toString(),
      );
      final campoMapeado = _mapearCampoImportacao(campoNormalizado);
      if (campoMapeado == null) continue;

      final valorTexto = (entry.value ?? '').toString().trim();
      if (campoMapeado.startsWith('agenda_fixa_semana.')) {
        if (valorTexto.isEmpty) continue;
        final dia = campoMapeado.split('.').last;
        agendaFixa[dia] = _valorImportacaoParaBool(entry.value);
        continue;
      }

      if (campoMapeado.startsWith('agenda_historico.')) {
        final subCampo = campoMapeado.substring('agenda_historico.'.length);
        if (subCampo.startsWith('dia_semana.')) {
          if (valorTexto.isEmpty) continue;
          final dia = subCampo.substring('dia_semana.'.length);
          historicoPorDia[dia] = valorTexto;
          continue;
        }

        agendaHistorico[subCampo] = valorTexto;
        continue;
      }

      if (campoMapeado == 'ultimo_dia_semana_agendado') {
        resultado[campoMapeado] = _normalizarDiaSemanaOrdenado(
          (entry.value ?? '').toString(),
        );
      } else {
        resultado[campoMapeado] = entry.value;
      }
    }

    if (historicoPorDia.isNotEmpty) {
      final linhas = historicoPorDia.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(' | ');
      final atual = (agendaHistorico['horarios_recorrentes'] ?? '')
          .toString()
          .trim();
      agendaHistorico['horarios_recorrentes'] =
          atual.isEmpty ? linhas : '$atual | $linhas';
    }

    if (agendaFixa.isNotEmpty) {
      resultado['agenda_fixa_semana'] = agendaFixa;
    }
    if (agendaHistorico.isNotEmpty) {
      resultado['agenda_historico'] = agendaHistorico;
    }

    return resultado;
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

  String _randomMessagesFunctionName() {
    try {
      final valorEnv = (dotenv.env['RANDOM_MESSAGES_FUNCTION_NAME'] ?? '')
          .trim();
      if (valorEnv.isNotEmpty) {
        return valorEnv;
      }
    } catch (_) {
      // dotenv pode nao estar inicializado em alguns contextos de teste.
    }

    final valorDefine = const String.fromEnvironment(
      'RANDOM_MESSAGES_FUNCTION_NAME',
      defaultValue: '',
    ).trim();

    if (valorDefine.isNotEmpty) {
      return valorDefine;
    }

    return 'dispararMensagensAleatoriasClientesManual';
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
    final nome = _nomeExibicaoTenantPadrao(nomeExibicao);

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
      final nomeExibicao = _nomeExibicaoTenantPadrao(valorLegado);

      if (tenantId.isNotEmpty) {
        await _db.collection('configuracoes').doc('geral').set({
          'administradora_padrao_atrelada_id': tenantId,
          'administradora_padrao_atrelada': nomeExibicao,
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

    if (tenantId == _tenantPadraoId) {
      return _tenantPadraoNomeExibicao;
    }

    return adminId;
  }

  DocumentReference<Map<String, dynamic>> _usuarioRefPorEmail(String email) {
    return _db.collection('usuarios').doc(_normalizarEmail(email));
  }

  DocumentReference<Map<String, dynamic>> _logClientesRef() {
    return _db.collection('configuracoes').doc('log_clientes');
  }

  DocumentReference<Map<String, dynamic>> _perfilClienteRefPorUsuarioRef(
    DocumentReference<Map<String, dynamic>> usuarioRef,
  ) {
    return usuarioRef.collection('perfil').doc('cliente');
  }

  Future<DocumentReference<Map<String, dynamic>>?> _perfilClienteRefPorUid(
    String uid,
  ) async {
    final usuarioRef = await _buscarUsuarioRefPorUid(uid);
    if (usuarioRef == null) return null;
    return _perfilClienteRefPorUsuarioRef(usuarioRef);
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

      // Evita consultas amplas que podem ser bloqueadas por regras quando o
      // documento do usuário ainda não existe.
      return null;
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

  Future<String?> _coletarIpPublico() async {
    try {
      final resposta = await http
          .get(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(const Duration(milliseconds: 1800));

      if (resposta.statusCode != 200 || resposta.body.trim().isEmpty) {
        return null;
      }

      final dados = jsonDecode(resposta.body);
      if (dados is Map<String, dynamic>) {
        final ip = (dados['ip'] as String? ?? '').trim();
        if (ip.isNotEmpty) {
          return ip;
        }
      }
    } catch (_) {}

    return null;
  }

  String _plataformaAuditoria() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
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
    final perfilClienteRef = await _perfilClienteRefPorUid(cliente.idCliente);
    if (perfilClienteRef == null) {
      throw StateError('Cadastro base do usuario nao encontrado para o UID informado.');
    }

    // Usa merge para preservar campos administrativos/importados nao expostos na UI.
    await perfilClienteRef.set(cliente.toMap(), SetOptions(merge: true));
  }

  Future<void> sincronizarPerfilClienteNoUsuario(
    String uid,
    Cliente cliente,
  ) async {
    final usuarioRef = await _buscarUsuarioRefPorUid(uid);
    if (usuarioRef == null) return;

    final usuarioSnap = await usuarioRef.get();
    final usuarioData = usuarioSnap.data() ?? const <String, dynamic>{};
    final email = (usuarioData['email'] as String? ?? '').trim();
    final tipo = (usuarioData['tipo'] as String? ?? 'cliente').trim();
    final aprovado = usuarioData['aprovado'] as bool? ?? false;
    final nomeCliente = (cliente.nomeCliente ?? '').trim();

    final updates = <String, dynamic>{
      'nome': nomeCliente,
      'nome_cliente': nomeCliente,
      'nome_cliente_normalizado': _normalizarNomeBusca(nomeCliente),
      'nome_preferido': (cliente.nomePreferidoCliente ?? '').trim(),
      'ddi': (cliente.ddiCliente ?? '55').trim(),
      'whatsapp':
          (cliente.whatsappCliente ?? cliente.telefonePrincipalCliente ?? '')
              .trim(),
      'telefone_principal':
          (cliente.telefonePrincipalCliente ?? cliente.whatsappCliente ?? '')
              .trim(),
      'nome_contato_secundario': (cliente.nomeContatoSecundarioCliente ?? '')
          .trim(),
      'telefone_secundario': (cliente.telefoneSecundarioCliente ?? '').trim(),
      'nome_indicacao': (cliente.nomeIndicacaoCliente ?? '').trim(),
      'telefone_indicacao': (cliente.telefoneIndicacaoCliente ?? '').trim(),
    };

    await usuarioRef.set(updates, SetOptions(merge: true));

    if (email.isNotEmpty) {
      await _sincronizarIndiceHumanoUsuario(
        uid: uid,
        email: email,
        nomeCliente: nomeCliente,
        tipo: tipo,
        aprovado: aprovado,
      );
    }
  }

  Future<Cliente?> getCliente(String uid) async {
    final perfilClienteRef = await _perfilClienteRefPorUid(uid);
    if (perfilClienteRef != null) {
      final doc = await perfilClienteRef.get();
      if (doc.exists && doc.data() != null) {
        return Cliente.fromMap(doc.data()!);
      }
    }

    // Compatibilidade com base legada.
    final docLegado = await _db.collection('clientes').doc(uid).get();
    if (docLegado.exists && docLegado.data() != null) {
      return Cliente.fromMap(docLegado.data()!);
    }

    return null;
  }

  Future<VinculoClienteCadastroStatus> obterStatusVinculoClientePorEmail({
    required String email,
    String? uidFallback,
    String? nomeFallback,
    String? telefoneFallback,
  }) async {
    final emailNormalizado = _normalizarEmail(email);
    final uidFallbackNormalizado = (uidFallback ?? '').trim();
    final nomeFallbackNormalizado = (nomeFallback ?? '').trim();
    final telefoneFallbackNormalizado = _normalizarTelefone(
      telefoneFallback ?? '',
    );

    Map<String, dynamic> usuarioData = const <String, dynamic>{};
    Map<String, dynamic> clienteData = const <String, dynamic>{};

    if (emailNormalizado.isNotEmpty) {
      try {
        final usuarioPorEmail = await _db
            .collection('usuarios')
            .doc(emailNormalizado)
            .get();
        if (usuarioPorEmail.exists && usuarioPorEmail.data() != null) {
          usuarioData = Map<String, dynamic>.from(usuarioPorEmail.data()!);
        }
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') {
          rethrow;
        }
      }
    }

    if (usuarioData.isEmpty && uidFallbackNormalizado.isNotEmpty) {
      final usuarioPorUid = await _buscarUsuarioSnapPorUid(uidFallbackNormalizado);
      if (usuarioPorUid != null && usuarioPorUid.data() != null) {
        usuarioData = Map<String, dynamic>.from(usuarioPorUid.data()!);
      }
    }

    var vinculoIdCliente = _primeiroTextoPreenchido(usuarioData, const ['id']);
    if (vinculoIdCliente.isEmpty) {
      vinculoIdCliente = uidFallbackNormalizado;
    }

    if (vinculoIdCliente.isNotEmpty) {
      try {
        final perfilClienteRef = await _perfilClienteRefPorUid(vinculoIdCliente);
        if (perfilClienteRef != null) {
          final clienteSnap = await perfilClienteRef.get();
          if (clienteSnap.exists && clienteSnap.data() != null) {
            clienteData = Map<String, dynamic>.from(clienteSnap.data()!);
          }
        }

        if (clienteData.isEmpty) {
          final clienteLegadoSnap = await _db
              .collection('clientes')
              .doc(vinculoIdCliente)
              .get();
          if (clienteLegadoSnap.exists && clienteLegadoSnap.data() != null) {
            clienteData = Map<String, dynamic>.from(clienteLegadoSnap.data()!);
          }
        }
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') {
          rethrow;
        }
      }
    }

    final config = await getConfiguracao();
    final camposObrigatoriosPendentes = _resolverCamposObrigatoriosPendentes(
      camposObrigatorios: config.camposObrigatorios,
      usuarioData: usuarioData,
      clienteData: clienteData,
    );

    final nomeCliente = _primeiroTextoPreenchido(
      clienteData,
      const ['nome_preferido', 'cliente_nome', 'nome'],
    );
    final nomeUsuario = _primeiroTextoPreenchido(
      usuarioData,
      const ['nome_preferido', 'nome_cliente', 'nome'],
    );

    final telefoneCliente = _normalizarTelefone(
      _primeiroTextoPreenchido(
        clienteData,
        const ['telefone_principal', 'whatsapp'],
      ),
    );
    final telefoneUsuario = _normalizarTelefone(
      _primeiroTextoPreenchido(
        usuarioData,
        const ['telefone_principal', 'whatsapp'],
      ),
    );

    final nomeSugerido = nomeCliente.isNotEmpty
        ? nomeCliente
        : (nomeUsuario.isNotEmpty ? nomeUsuario : nomeFallbackNormalizado);
    final telefoneSugerido = telefoneCliente.isNotEmpty
        ? telefoneCliente
        : (telefoneUsuario.isNotEmpty
              ? telefoneUsuario
              : telefoneFallbackNormalizado);

    return VinculoClienteCadastroStatus(
      emailNormalizado: emailNormalizado,
      vinculoIdCliente: vinculoIdCliente,
      nomeSugerido: nomeSugerido,
      telefoneSugerido: telefoneSugerido,
      possuiUsuario: usuarioData.isNotEmpty,
      possuiCliente: clienteData.isNotEmpty,
      cadastroCompleto: camposObrigatoriosPendentes.isEmpty,
      camposObrigatoriosPendentes: camposObrigatoriosPendentes,
    );
  }

  Stream<List<Cliente>> getClientesAprovados() async* {
    yield* _streamClientesAprovadosPorUsuarios();
  }

  Stream<List<Cliente>> _streamClientesAprovadosPorUsuarios() {
    return _db
        .collection('usuarios')
        .where('aprovado', isEqualTo: true)
        .where('tipo', isEqualTo: 'cliente')
        .snapshots()
        .map((snapshot) {
          final clientes = snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            final uid = ((data['id'] as String?) ?? '').trim().isNotEmpty
                ? (data['id'] as String).trim()
                : doc.id;
            final nome = ((data['nome_cliente'] as String?) ??
                    (data['nome'] as String?) ??
                    '')
                .trim();
            final telefone = ((data['telefone_principal'] as String?) ??
                    (data['whatsapp'] as String?) ??
                    '')
                .trim();

            return Cliente.fromMap({
              'uid': uid,
              'cliente_nome': nome,
              'nome_preferido': ((data['nome_preferido'] as String?) ?? '')
                  .trim(),
              'ddi': ((data['ddi'] as String?) ?? '55').trim(),
              'whatsapp': telefone,
              'telefone_principal': telefone,
              'saldo_sessoes': data['saldo_sessoes'] ?? 0,
            });
          }).toList();

          clientes.sort(
            (a, b) => _normalizarNomeBusca(a.nomeExibicao).compareTo(
              _normalizarNomeBusca(b.nomeExibicao),
            ),
          );

          return clientes;
        })
        .asBroadcastStream();
  }

  Future<void> adicionarPacote(String uid, int quantidade) async {
    final perfilClienteRef = await _perfilClienteRefPorUid(uid);
    if (perfilClienteRef == null) return;

    await perfilClienteRef.update({
      'saldo_sessoes': FieldValue.increment(quantidade),
    });
  }

  Future<void> toggleFavorito(String uid, String tipo) async {
    final docRef = await _perfilClienteRefPorUid(uid);
    if (docRef == null) return;

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

  Future<ContatoAprovacaoConfig> getContatoAprovacaoConfig() async {
    final docRef = _db.collection('configuracoes').doc('geral');
    final telefoneFallback = _whatsappAdminPadrao();

    String nomeAdmin = _tenantPadraoNomeExibicao;
    String telefone = telefoneFallback;
    String mensagemTemplate = _mensagemContatoAprovacaoTemplatePadrao();

    try {
      final doc = await docRef.get();
      final dados = doc.data() ?? const <String, dynamic>{};

      final nomeConfigurado =
          (dados['nome_admin_exibicao_cliente'] as String? ?? '').trim();
      final nomeLegado =
          (dados['administradora_padrao_atrelada'] as String? ?? '').trim();
      nomeAdmin = _nomeExibicaoTenantPadrao(
        nomeConfigurado.isNotEmpty ? nomeConfigurado : nomeLegado,
      );

      final telefoneConfigurado = _normalizarTelefone(
        dados['whatsapp_admin'] as String? ?? '',
      );
      if (telefoneConfigurado.isNotEmpty) {
        telefone = telefoneConfigurado;
      }

      final templateConfigurado =
          (dados['whatsapp_msg_aprovacao_template'] as String? ?? '').trim();
      if (templateConfigurado.isNotEmpty) {
        mensagemTemplate = templateConfigurado;
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
    }

    return ContatoAprovacaoConfig(
      nomeAdministradoraExibicao: nomeAdmin,
      whatsappRedirecionamento: telefone,
      mensagemTemplate: mensagemTemplate,
    );
  }

  Future<void> salvarContatoAprovacaoConfig({
    required String nomeAdministradoraExibicao,
    required String whatsappRedirecionamento,
    required String mensagemTemplate,
  }) async {
    final nome = _nomeExibicaoTenantPadrao(nomeAdministradoraExibicao);
    final telefone = _normalizarTelefone(whatsappRedirecionamento);
    final template = mensagemTemplate.trim().isEmpty
        ? _mensagemContatoAprovacaoTemplatePadrao()
        : mensagemTemplate.trim();

    await _db.collection('configuracoes').doc('geral').set({
      'nome_admin_exibicao_cliente': nome,
      'whatsapp_admin': telefone,
      'whatsapp_msg_aprovacao_template': template,
    }, SetOptions(merge: true));
  }

  String montarMensagemContatoAprovacao({
    required ContatoAprovacaoConfig config,
    required String clienteNome,
    required String clienteTelefone,
    required String clienteEmail,
    DateTime? dataHora,
  }) {
    final data = dataHora ?? DateTime.now();
    final nomeCliente = clienteNome.trim().isEmpty ? 'Nao informado' : clienteNome.trim();
    final telefoneCliente =
        clienteTelefone.trim().isEmpty ? 'Nao informado' : clienteTelefone.trim();
    final telefoneClienteComMascara =
        clienteTelefone.trim().isEmpty
            ? 'Nao informado'
            : _formatarTelefoneComMascara(clienteTelefone);
    final emailCliente = clienteEmail.trim().isEmpty ? 'Nao informado' : clienteEmail.trim();

    final valores = <String, String>{
      '{admin_nome}': config.nomeAdministradoraExibicao.trim(),
      '{cliente_nome}': nomeCliente,
      '{cliente_telefone}': telefoneCliente,
      '{cliente_telefone_com_mascara}': telefoneClienteComMascara,
      '{cliente_email}': emailCliente,
      '{data_hora}': DateFormat('dd/MM/yyyy HH:mm').format(data),
    };

    var mensagem = config.mensagemTemplate;
    valores.forEach((placeholder, valor) {
      mensagem = mensagem.replaceAll(placeholder, valor);
    });
    return mensagem;
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
    final uidNormalizado = uid.trim();
    if (uidNormalizado.isEmpty) return null;

    final usuarioAtual = FirebaseAuth.instance.currentUser;
    final bool uidEhDoUsuarioLogado =
        usuarioAtual != null && usuarioAtual.uid == uidNormalizado;

    if (uidEhDoUsuarioLogado) {
      final emailAutenticado = _normalizarEmail(usuarioAtual.email ?? '');
      if (emailAutenticado.isNotEmpty) {
        final porEmail = await _db.collection('usuarios').doc(emailAutenticado).get();
        if (porEmail.exists && porEmail.data() != null) {
          return UsuarioModel.fromMap(porEmail.data()!);
        }
      }

      final porUidLegado = await _db.collection('usuarios').doc(uidNormalizado).get();
      if (porUidLegado.exists && porUidLegado.data() != null) {
        return UsuarioModel.fromMap(porUidLegado.data()!);
      }

      return null;
    }

    final doc = await _buscarUsuarioSnapPorUid(uidNormalizado);
    if (doc != null && doc.data() != null) {
      return UsuarioModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<UsuarioModel?> getUsuarioPorEmail(String email) async {
    final emailNormalizado = _normalizarEmail(email);
    if (emailNormalizado.isEmpty) return null;

    try {
      // Tenta buscar por email (chave do documento)
      final docPorEmail = await _db.collection('usuarios').doc(emailNormalizado).get();
      if (docPorEmail.exists && docPorEmail.data() != null) {
        return UsuarioModel.fromMap(docPorEmail.data()!);
      }

      final porEmailCampo = await _db
          .collection('usuarios')
          .where('email_normalizado', isEqualTo: emailNormalizado)
          .limit(1)
          .get();

      if (porEmailCampo.docs.isNotEmpty) {
        return UsuarioModel.fromMap(porEmailCampo.docs.first.data());
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
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
    try {
      final emailDocId = _normalizarEmail(
        usuario.emailNormalizado ?? usuario.email,
      );
      
      // 🔴 CRÍTICO: Regra de Firestore exige userId == email_normalizado
      // Não usar UID como fallback - sempre usar email normalizado como docId
      if (emailDocId.isEmpty) {
        throw StateError(
          '❌ Email normalizado vazio. Não é possível salvar usuário sem email válido. '
          'Email original: ${usuario.email}, Email normalizado: ${usuario.emailNormalizado}'
        );
      }
      
      final docId = emailDocId;

      debugPrint('💾 Salvando usuário: email=$emailDocId, docId=$docId (tipo: ${usuario.tipo})');
      debugPrint('   Email normalizado (esperado): ${usuario.emailNormalizado}');
      debugPrint('   Email original: ${usuario.email}');
      debugPrint('   UID (para validação): ${usuario.id}');
      
      // Salva documento principal
      final usuarioMap = usuario.toMap();
      final usuarioRef = _db.collection('usuarios').doc(docId);
      DocumentSnapshot<Map<String, dynamic>>? usuarioExistente;
      try {
        usuarioExistente = await usuarioRef.get();
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') {
          rethrow;
        }
        debugPrint(
          '⚠️ Aviso: sem permissao para leitura previa de usuarios/$docId. '
          'Tentando escrita direta para concluir cadastro.',
        );
      }

      if (usuarioExistente != null &&
          usuarioExistente.exists &&
          usuarioExistente.data() != null) {
        final existente = usuarioExistente.data()!;
        final idExistente = (existente['id'] as String? ?? '').trim();

        if (idExistente.isNotEmpty && idExistente != usuario.id.trim()) {
          throw StateError(
            'Já existe um cadastro para este e-mail vinculado a outro UID. '
            'UID existente: $idExistente, UID informado: ${usuario.id.trim()}',
          );
        }

        // Em updates, preserva campos imutáveis para evitar bloqueio nas rules.
        if (existente['data_cadastro'] != null) {
          usuarioMap['data_cadastro'] = existente['data_cadastro'];
        }
        if (idExistente.isNotEmpty) {
          usuarioMap['id'] = idExistente;
        }
        if (existente['email'] != null) {
          usuarioMap['email'] = existente['email'];
        }
        if (existente['email_normalizado'] != null) {
          usuarioMap['email_normalizado'] = existente['email_normalizado'];
        }
        if (existente['tipo'] != null) {
          usuarioMap['tipo'] = existente['tipo'];
        }
        if (existente['visualiza_todos'] != null) {
          usuarioMap['visualiza_todos'] = existente['visualiza_todos'];
        }
      }

      bool usuarioPersistidoEmTransacao = false;

      if (usuario.tipo == 'cliente') {
        final precisaGerarOrdem =
            usuarioMap['ordem_criacao'] == null ||
            usuarioMap['ordem_criacao_em'] == null;

        if (precisaGerarOrdem) {
          final logRef = _logClientesRef();
          await _db.runTransaction((transaction) async {
            final logSnap = await transaction.get(logRef);
            final logData = logSnap.data();

            final ultimoSequencial =
                (logData?['sequencial_clientes'] as int?) ?? 0;
            final proximoSequencial = ultimoSequencial + 1;

            final ultimoHorario = logData?['ultimo_horario_cadastro'] as Timestamp?;
            var novoHorario = Timestamp.now();

            if (ultimoHorario != null &&
                novoHorario.toDate().isBefore(ultimoHorario.toDate())) {
              final horarioAjustado = ultimoHorario
                  .toDate()
                  .add(const Duration(milliseconds: 1));
              novoHorario = Timestamp.fromDate(horarioAjustado);
            }

            final ordemCriacao = {
              'ordem_criacao': proximoSequencial,
              'ordem_criacao_em': novoHorario,
            };
            usuarioMap.addAll(ordemCriacao);

            transaction.set(logRef, {
              'sequencial_clientes': proximoSequencial,
              'ultimo_horario_cadastro': novoHorario,
              'atualizado_em': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            transaction.set(usuarioRef, usuarioMap, SetOptions(merge: true));
            usuarioPersistidoEmTransacao = true;

            debugPrint(
              '🔢 Ordem de criação reservada para cliente: ${ordemCriacao['ordem_criacao']} em ${ordemCriacao['ordem_criacao_em']}',
            );
          });

          debugPrint(
            '✅ Usuário salvo com ordem de criação em transação atômica',
          );
        }

        if (!usuarioPersistidoEmTransacao) {
          debugPrint('   Campos no documento: ${usuarioMap.keys.toList()}');
          await usuarioRef.set(usuarioMap, SetOptions(merge: true));
        }
      } else {
        debugPrint('   Campos no documento: ${usuarioMap.keys.toList()}');
        await usuarioRef.set(usuarioMap, SetOptions(merge: true));
      }
      
      debugPrint('✅ Usuário salvo com sucesso em usuarios/$docId');

      // Unifica persistencia entre usuario e cliente para reduzir divergencia.
      if (usuario.tipo == 'cliente') {
        await _sincronizarClienteComUsuario(usuario);
      }

      // Sincroniza índice de busca
      try {
        await _sincronizarIndiceHumanoUsuario(
          uid: usuario.id,
          email: usuario.email,
          nomeCliente: usuario.nomeCliente ?? usuario.nome,
          tipo: usuario.tipo,
          aprovado: usuario.aprovado,
        );
        debugPrint('✅ Índice de busca sincronizado');
      } catch (indiceError) {
        debugPrint('⚠️ Aviso: Erro ao sincronizar índice (não crítico): $indiceError');
        // Não falha o cadastro se o índice falhar - dados principais foram salvos
      }
    } catch (e) {
      debugPrint('❌ ERRO ao salvar usuário: $e (tipo: ${e.runtimeType})');
      debugPrint('   Email: ${usuario.email}');
      debugPrint('   Email normalizado: ${usuario.emailNormalizado}');
      debugPrint('   UID: ${usuario.id}');
      rethrow;
    }
  }

  Future<void> _sincronizarClienteComUsuario(UsuarioModel usuario) async {
    final uidNormalizado = usuario.id.trim();
    if (uidNormalizado.isEmpty) {
      throw StateError('UID obrigatorio para sincronizar cliente.');
    }

    final nomeCliente = (usuario.nomeCliente ?? usuario.nome).trim().isEmpty
        ? 'Cliente'
        : (usuario.nomeCliente ?? usuario.nome).trim();
    final telefoneNormalizado = _normalizarTelefone(
      (usuario.telefonePrincipal ?? usuario.whatsapp ?? '').trim(),
    );

    final usuarioRef = _usuarioRefPorEmail(usuario.emailNormalizado ?? usuario.email);
    final clienteRef = _perfilClienteRefPorUsuarioRef(usuarioRef);
    final dadosSincronizados = _dadosPadraoCliente(
      uid: uidNormalizado,
      nomeCliente: nomeCliente,
      whatsapp: telefoneNormalizado,
    )
      ..addAll({
        'nome': nomeCliente,
        'ddi': (usuario.ddi ?? '55').trim().isEmpty ? '55' : usuario.ddi,
        'whatsapp': telefoneNormalizado,
        'telefone_principal': telefoneNormalizado,
        'nome_contato_secundario': usuario.nomeContatoSecundario ?? '',
        'telefone_secundario': usuario.telefoneSecundario ?? '',
        'nome_indicacao': usuario.nomeIndicacao ?? '',
        'telefone_indicacao': usuario.telefoneIndicacao ?? '',
        'categoria_origem': usuario.categoriaOrigem ?? '',
      });

    // Escrita direta com merge evita leitura prévia, reduzindo bloqueio por rules.
    await clienteRef.set(dadosSincronizados, SetOptions(merge: true));

    debugPrint('✅ Cliente atualizado/sincronizado em usuarios/*/perfil/cliente (uid=$uidNormalizado)');
  }

  Future<void> salvarPerfilInicialClienteGoogle({
    required String uid,
    required String nomeCliente,
    required String whatsapp,
    DateTime? dataNascimento,
  }) async {
    final uidNormalizado = uid.trim();
    if (uidNormalizado.isEmpty) return;

    final nome = nomeCliente.trim().isEmpty ? 'Cliente' : nomeCliente.trim();
    final telefoneNormalizado = _normalizarTelefone(whatsapp);
    final dataNascimentoNormalizada = dataNascimento == null
      ? null
      : DateTime(dataNascimento.year, dataNascimento.month, dataNascimento.day);
    final usuarioAtual = FirebaseAuth.instance.currentUser;
    final emailAutenticado = _normalizarEmail(usuarioAtual?.email ?? '');
    final usuarioRef =
        usuarioAtual != null && usuarioAtual.uid == uidNormalizado && emailAutenticado.isNotEmpty
        ? _usuarioRefPorEmail(emailAutenticado)
        : await _buscarUsuarioRefPorUid(uidNormalizado);
    if (usuarioRef == null) return;

    final clienteRef = _perfilClienteRefPorUsuarioRef(usuarioRef);

    final updates = _dadosPadraoCliente(
      uid: uidNormalizado,
      nomeCliente: nome,
      whatsapp: telefoneNormalizado,
    )
      ..addAll(<String, dynamic>{
        'cliente_nome': nome,
        'nome': nome,
        'ddi': '55',
        'whatsapp': telefoneNormalizado,
        'telefone_principal': telefoneNormalizado,
      });
    if (dataNascimentoNormalizada != null) {
      updates['data_nascimento'] = Timestamp.fromDate(dataNascimentoNormalizada);
    }

    // Escrita direta com merge evita leitura prévia do subdoc em fluxos pendentes.
    await clienteRef.set(updates, SetOptions(merge: true));
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
    String metodoEntrada = 'email_senha',
    String provedorEntrada = 'firebase_auth',
    String? emailAutenticado,
    String? vinculoIdCliente,
    bool? emailValido,
    bool? senhaForte,
  }) async {
    final emailDigitadoNormalizadoInput = emailDigitado.trim();
    final emailNormalizado = _normalizarEmail(emailDigitadoNormalizadoInput);
    final usuarioAtual = FirebaseAuth.instance.currentUser;
    final emailAutenticadoEfetivo =
        (emailAutenticado ?? usuarioAtual?.email ?? '').trim();
    final emailAutenticadoNormalizado = _normalizarEmail(
      emailAutenticadoEfetivo,
    );
    final vinculoIdClienteNormalizado = (vinculoIdCliente ?? '').trim();
    final ipColetado = await _coletarIpPublico();
    final metodoEntradaNormalizado = metodoEntrada.trim().isEmpty
        ? 'nao_informado'
        : metodoEntrada.trim().toLowerCase();
    final provedorEntradaNormalizado = provedorEntrada.trim().isEmpty
        ? 'nao_informado'
        : provedorEntrada.trim().toLowerCase();

    try {
      await _db.collection('auditoria_credenciais').add({
        'origem': origem,
        'metodo_entrada': metodoEntradaNormalizado,
        'provedor_entrada': provedorEntradaNormalizado,
        'email_digitado': emailDigitadoNormalizadoInput,
        'email_normalizado': emailNormalizado,
        'email_autenticado':
            emailAutenticadoEfetivo.isEmpty ? null : emailAutenticadoEfetivo,
        'email_autenticado_normalizado': emailAutenticadoNormalizado.isEmpty
            ? null
            : emailAutenticadoNormalizado,
        'email_corresponde_auth':
            emailAutenticadoNormalizado.isNotEmpty &&
            emailAutenticadoNormalizado == emailNormalizado,
        'nome_cliente_digitado': (nomeClienteDigitado ?? '').trim(),
        'senha_hash': _hashValorSensivel(senhaInformada),
        'senha_tamanho': senhaInformada.length,
        'ip': ipColetado,
        'ip_status': ipColetado == null ? 'indisponivel' : 'coletado',
        'dispositivo_plataforma': _plataformaAuditoria(),
        'motivos': motivos,
        'inconformidade': inconformidade,
        'lgpd_consentido': lgpdConsentido,
        'email_valido': emailValido ?? emailNormalizado.isNotEmpty,
        'senha_forte': senhaForte ?? false,
        'vinculo_id_cliente':
            vinculoIdClienteNormalizado.isEmpty ? null : vinculoIdClienteNormalizado,
        'criado_em': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        debugPrint('Falha ao registrar auditoria de credenciais: $e');
      }
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

    await _db.collection('usuarios').doc(emailNormalizado).set({
      'id': uid,
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
    String origem = 'login_view',
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
      'origem': origem,
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
    if (emailNormalizado.isEmpty) {
      throw StateError('Email obrigatorio para salvar usuario em usuarios/{email}.');
    }
    final tenantPadraoId = await getAdministradoraPadraoAtreladaId();
    final devMaster = emailEhDevMaster(emailNormalizado);
    final tipoPadrao = devMaster ? 'admin' : 'cliente';
    final aprovadoPadrao = devMaster;

    final usuarioRef = _usuarioRefPorEmail(emailNormalizado);
    final clienteRef = _perfilClienteRefPorUsuarioRef(usuarioRef);

    final usuarioSnap = await usuarioRef.get();
    final clienteSnap = await clienteRef.get();
    final usuarioAprovadoAtual =
      usuarioSnap.data()?['aprovado'] as bool? ?? aprovadoPadrao;

    if (!usuarioSnap.exists || usuarioSnap.data() == null) {
      await usuarioRef.set({
        'id': uid,
        'nome': nomePadrao,
        'nome_cliente': nomePadrao,
        'nome_preferido': '',
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
        'ddi': '55',
        'telefone_principal': '',
        'nome_contato_secundario': '',
        'telefone_secundario': '',
        'nome_indicacao': '',
        'telefone_indicacao': '',
        'categoria_origem': '',
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
      if (!usuarioData.containsKey('nome_preferido')) {
        updatesUsuario['nome_preferido'] = '';
      }
      if (!usuarioData.containsKey('ddi')) updatesUsuario['ddi'] = '55';
      if (!usuarioData.containsKey('telefone_principal')) {
        updatesUsuario['telefone_principal'] =
            (usuarioData['whatsapp'] as String? ?? '').trim();
      }
      if (!usuarioData.containsKey('nome_contato_secundario')) {
        updatesUsuario['nome_contato_secundario'] = '';
      }
      if (!usuarioData.containsKey('telefone_secundario')) {
        updatesUsuario['telefone_secundario'] = '';
      }
      if (!usuarioData.containsKey('nome_indicacao')) {
        updatesUsuario['nome_indicacao'] = '';
      }
      if (!usuarioData.containsKey('telefone_indicacao')) {
        updatesUsuario['telefone_indicacao'] = '';
      }
      if (!usuarioData.containsKey('categoria_origem')) {
        updatesUsuario['categoria_origem'] = '';
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
      aprovado: usuarioAprovadoAtual,
    );

    if (!clienteSnap.exists || clienteSnap.data() == null) {
      await clienteRef.set(
        _dadosPadraoCliente(uid: uid, nomeCliente: nomePadrao),
        SetOptions(merge: true),
      );
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
    if (!clienteData.containsKey('nome_preferido')) {
      updatesCliente['nome_preferido'] = '';
    }
    if (!clienteData.containsKey('ddi')) updatesCliente['ddi'] = '55';
    if (!clienteData.containsKey('telefone_principal')) {
      updatesCliente['telefone_principal'] =
          (clienteData['whatsapp'] as String? ?? '').trim();
    }
    if (!clienteData.containsKey('nome_contato_secundario')) {
      updatesCliente['nome_contato_secundario'] = '';
    }
    if (!clienteData.containsKey('telefone_secundario')) {
      updatesCliente['telefone_secundario'] = '';
    }
    if (!clienteData.containsKey('nome_indicacao')) {
      updatesCliente['nome_indicacao'] = '';
    }
    if (!clienteData.containsKey('telefone_indicacao')) {
      updatesCliente['telefone_indicacao'] = '';
    }
    if (!clienteData.containsKey('categoria_origem')) {
      updatesCliente['categoria_origem'] = '';
    }
    if (!clienteData.containsKey('presenca_agenda')) {
      updatesCliente['presenca_agenda'] = false;
    }
    if (!clienteData.containsKey('frequencia_historica_agenda')) {
      updatesCliente['frequencia_historica_agenda'] = 0;
    }
    if (!clienteData.containsKey('ultimo_horario_agendado')) {
      updatesCliente['ultimo_horario_agendado'] = '';
    }
    if (!clienteData.containsKey('ultimo_dia_semana_agendado')) {
      updatesCliente['ultimo_dia_semana_agendado'] = '';
    }
    if (!clienteData.containsKey('sugestao_cliente_fixo')) {
      updatesCliente['sugestao_cliente_fixo'] = false;
    }
    if (!clienteData.containsKey('agenda_fixa_semana') ||
        clienteData['agenda_fixa_semana'] is! Map) {
      updatesCliente['agenda_fixa_semana'] = _agendaFixaSemanaPadrao();
    } else {
      final agendaFixaAtual = Map<String, dynamic>.from(
        clienteData['agenda_fixa_semana'] as Map,
      );
      final agendaNormalizada = _normalizarAgendaFixaSemana(agendaFixaAtual);
      final agendaAtualNormalizada = <String, bool>{};
      for (final dia in _diasSemanaAgenda) {
        agendaAtualNormalizada[dia] =
            _valorImportacaoParaBool(agendaFixaAtual[dia]);
      }

      if (agendaAtualNormalizada.toString() != agendaNormalizada.toString()) {
        updatesCliente['agenda_fixa_semana'] = agendaNormalizada;
      }
    }

    if (!clienteData.containsKey('agenda_historico') ||
        clienteData['agenda_historico'] is! Map) {
      updatesCliente['agenda_historico'] = _agendaHistoricoPadrao();
    } else {
      final agendaHistoricoAtual = Map<String, dynamic>.from(
        clienteData['agenda_historico'] as Map,
      );
      final agendaHistoricoPadrao = _agendaHistoricoPadrao();
      bool agendaHistoricoAlterado = false;

      for (final chave in agendaHistoricoPadrao.keys) {
        if (!agendaHistoricoAtual.containsKey(chave)) {
          agendaHistoricoAtual[chave] = agendaHistoricoPadrao[chave];
          agendaHistoricoAlterado = true;
        }
      }

      if (agendaHistoricoAlterado) {
        updatesCliente['agenda_historico'] = agendaHistoricoAtual;
      }
    }
    if (!clienteData.containsKey('cpf')) updatesCliente['cpf'] = '';
    if (!clienteData.containsKey('cep')) updatesCliente['cep'] = '';
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

    if (!usuarioAprovadoAtual) {
      updatesCliente['agenda_fixa_semana'] = _agendaFixaSemanaPadrao();
      updatesCliente['agenda_historico'] = _agendaHistoricoPadrao();
      updatesCliente['sugestao_cliente_fixo'] = false;
    }

    if (updatesCliente.isNotEmpty) {
      await clienteRef.set(updatesCliente, SetOptions(merge: true));
    }
  }

  Stream<List<UsuarioModel>> getUsuariosPendentes() {
    return _db
        .collection('usuarios')
        .where('tipo', isEqualTo: 'cliente')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = Map<String, dynamic>.from(doc.data());
                final idAtual = (data['id'] as String? ?? '').trim();
                final uidLegado = (data['uid'] as String? ?? '').trim();
                data['id'] = idAtual.isNotEmpty ? idAtual : uidLegado;
                return UsuarioModel.fromMap(data);
              })
              .where((usuario) => !usuario.aprovado && !usuario.reprovado)
              .toList();
        });
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
      'reprovado': false,
      'data_reprovacao': FieldValue.delete(),
      'nome_cliente': nomeCliente,
      'email_normalizado': _normalizarEmail(email),
      'nome_cliente_normalizado': _normalizarNomeBusca(nomeCliente),
      'admin_atrelada_id': adminAtreladaId,
    }, SetOptions(merge: true));

    final clienteRef = _perfilClienteRefPorUsuarioRef(usuarioRef);
    await clienteRef.set(
      _dadosPadraoCliente(
        uid: uid,
        nomeCliente: nomeCliente,
        whatsapp: whatsapp,
      ),
      SetOptions(merge: true),
    );

    await _sincronizarIndiceHumanoUsuario(
      uid: uid,
      email: email,
      nomeCliente: nomeCliente,
      tipo: 'cliente',
      aprovado: true,
    );
  }

  Future<void> reprovarUsuario(String uid) async {
    final usuarioRef = await _buscarUsuarioRefPorUid(uid);
    if (usuarioRef == null) {
      throw StateError('Usuario nao encontrado para reprovacao: $uid');
    }

    final usuarioSnap = await usuarioRef.get();
    final usuarioData = usuarioSnap.data() ?? <String, dynamic>{};
    final email = (usuarioData['email'] as String? ?? '').trim();
    final nomeCliente =
        (usuarioData['nome_cliente'] as String? ??
                usuarioData['nome'] as String? ??
                'Cliente')
            .trim();

    await usuarioRef.set({
      'aprovado': false,
      'reprovado': true,
      'data_reprovacao': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Remove o documento de perfil de cliente se existir
    final clienteRef = _perfilClienteRefPorUsuarioRef(usuarioRef);
    await clienteRef.delete().catchError((_) {
      // Ignore se não existir
    });

    await _sincronizarIndiceHumanoUsuario(
      uid: uid,
      email: email,
      nomeCliente: nomeCliente,
      tipo: 'cliente',
      aprovado: false,
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
    final clienteRef = await _perfilClienteRefPorUid(agendamento.idCliente);
    final clienteDoc = await clienteRef?.get();
    final clienteData = clienteDoc?.data();
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
        final clienteRef = await _perfilClienteRefPorUid(clienteId);
        if (clienteRef != null) {
          final clienteDoc = await transaction.get(clienteRef);

          if (clienteDoc.exists) {
            final saldo = clienteDoc.data()?['saldo_sessoes'] ?? 0;
            if (saldo > 0) {
              transaction.update(clienteRef, {'saldo_sessoes': saldo - 1});
            }
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

  Future<Map<String, dynamic>> dispararMensagensAleatoriasClientes({
    bool dryRun = true,
    int limite = 0,
    int indiceMensagemSelecionada = -1,
  }) async {
    final callable = _functions.httpsCallable(_randomMessagesFunctionName());
    final result = await callable.call(<String, dynamic>{
      'dryRun': dryRun,
      'limite': limite,
      'indiceMensagemSelecionada': indiceMensagemSelecionada,
    });

    final data = result.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return <String, dynamic>{};
  }

  // --- Lista de Espera ---
  Future<int> _contarSolicitacoesListaEsperaAtivas(
    String uid, {
    String? ignorarAgendamentoId,
  }) async {
    final snapshot = await _db
        .collection('agendamentos')
        .where('lista_espera', arrayContains: uid)
        .get();

    int total = 0;
    for (final doc in snapshot.docs) {
      if (ignorarAgendamentoId != null && doc.id == ignorarAgendamentoId) {
        continue;
      }

      final status = (doc.data()['status'] ?? '').toString();
      final encerrado =
          status == 'cancelado' ||
          status == 'cancelado_tardio' ||
          status == 'recusado';

      if (!encerrado) {
        total++;
      }
    }

    return total;
  }

  Future<void> toggleListaEspera(
    String agendamentoId,
    String uid,
    bool entrar,
  ) async {
    if (entrar) {
      final totalSolicitacoesAtivas = await _contarSolicitacoesListaEsperaAtivas(
        uid,
        ignorarAgendamentoId: agendamentoId,
      );

      if (totalSolicitacoesAtivas >= _limiteSolicitacoesListaEsperaPorCliente) {
        throw StateError(
          AppStrings.limiteSolicitacoesListaEspera(
            _limiteSolicitacoesListaEsperaPorCliente,
          ),
        );
      }
    }

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

  Stream<List<TransacaoFinanceira>> getTransacoesDoCliente(String clienteUid) {
    final uidNormalizado = clienteUid.trim();
    if (uidNormalizado.isEmpty) {
      return Stream<List<TransacaoFinanceira>>.value(<TransacaoFinanceira>[]);
    }

    return _db
        .collection('transacoes')
        .where('cliente_uid', isEqualTo: uidNormalizado)
        .snapshots()
        .map((snapshot) {
          final transacoes = snapshot.docs
              .map((doc) => TransacaoFinanceira.fromMap(doc.data(), id: doc.id))
              .toList();

          transacoes.sort(
            (a, b) => b.dataPagamento.compareTo(a.dataPagamento),
          );

          return transacoes;
        });
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
    final clienteRef = await _perfilClienteRefPorUid(uid);
    if (clienteRef != null) {
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
    }

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

    // Exporta perfis de cliente a partir da coleção unificada de usuarios.
    final usuariosClientes = await _db
        .collection('usuarios')
        .where('tipo', isEqualTo: 'cliente')
        .get();
    final clientes = <Map<String, dynamic>>[];
    for (final usuarioDoc in usuariosClientes.docs) {
      final perfilSnap = await _perfilClienteRefPorUsuarioRef(usuarioDoc.reference).get();
      if (perfilSnap.exists && perfilSnap.data() != null) {
        final item = Map<String, dynamic>.from(perfilSnap.data()!);
        item['id'] = usuarioDoc.data()['id'] ?? '';
        clientes.add(item);
      }
    }

    dados['clientes'] = clientes;
    dados['agendamentos'] = await getFullCollection('agendamentos');
    dados['estoque'] = await getFullCollection('estoque');
    dados['configuracoes'] = await getFullCollection('configuracoes');

    return jsonEncode(dados);
  }

  Future<void> restaurarBackupJson(String jsonString) async {
    final dados = jsonDecode(jsonString) as Map<String, dynamic>;

    if (dados.containsKey('clientes')) {
      final clientes = List<Map<String, dynamic>>.from(dados['clientes']);
      for (final cliente in clientes) {
        final uid = (cliente['uid'] ?? cliente['id'] ?? '').toString().trim();
        if (uid.isEmpty) continue;
        final ref = await _perfilClienteRefPorUid(uid);
        if (ref == null) continue;

        final payload = Map<String, dynamic>.from(cliente)..remove('id');
        await ref.set(payload, SetOptions(merge: true));
      }
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

  // ---------------------------------------------------------------------------
  // Importação de planilha de clientes (XLSX / CSV)
  // ---------------------------------------------------------------------------

  /// Recebe as linhas da planilha como lista de mapas com os cabeçalhos
  /// originais como chave, normaliza e persiste na coleção `clientes` (legado).
  ///
  /// Observação: o modelo principal atual de cliente fica em
  /// `usuarios/{email_normalizado}/perfil/cliente`.
  ///
  /// Retorna um mapa com as contagens: `importados`, `ignorados`, `erros`.
  Future<Map<String, int>> importarPlanilhaClientes(
    List<Map<String, dynamic>> linhas,
  ) async {
    int importados = 0;
    int ignorados = 0;
    int erros = 0;

    final clientesParaSalvar = <Map<String, dynamic>>[];

    for (final linhaOriginal in linhas) {
      try {
        final linha = _normalizarLinhaImportacao(linhaOriginal);

        // Extrai e normaliza o telefone principal
        final telRaw =
            (linha['telefone_principal'] ??
                    linha['whatsapp'] ??
                    '')
                .toString()
                .trim();
        final telDigits = telRaw.replaceAll(RegExp(r'\D'), '');

        // Remove DDI 55 se o número tem mais de 11 dígitos
        final telLocal = telDigits.length > 11 && telDigits.startsWith('55')
            ? telDigits.substring(2)
            : telDigits;

        if (telLocal.isEmpty || telLocal.length < 8) {
          ignorados++;
          continue;
        }

        final uidInformado = (linha['uid'] ?? '').toString().trim();
        final docId = uidInformado.isNotEmpty ? uidInformado : 'import_$telLocal';
        final nomeImportado = (linha['cliente_nome'] ?? '').toString().trim();
        final nomeCliente = nomeImportado.isNotEmpty ? nomeImportado : 'Cliente';

        final agendaFixaSemana = _agendaFixaSemanaPadrao();
        final agendaFixaImportada = linha['agenda_fixa_semana'];
        if (agendaFixaImportada is Map) {
          for (final dia in _diasSemanaAgenda) {
            if (agendaFixaImportada.containsKey(dia)) {
              agendaFixaSemana[dia] = _valorImportacaoParaBool(
                agendaFixaImportada[dia],
              );
            }
          }
        }

        final agendaHistorico = _agendaHistoricoPadrao();
        final agendaHistoricoImportado = linha['agenda_historico'];
        if (agendaHistoricoImportado is Map) {
          for (final chave in agendaHistorico.keys) {
            if (agendaHistoricoImportado.containsKey(chave)) {
              agendaHistorico[chave] =
                  (agendaHistoricoImportado[chave] ?? '').toString().trim();
            }
          }
        }

        // Prepara mapa normalizado
        final mapaProcessado = _dadosPadraoCliente(
          uid: docId,
          nomeCliente: nomeCliente,
          whatsapp: telLocal,
        );
        mapaProcessado.addAll(linha);
        mapaProcessado['uid'] = docId;
        mapaProcessado['cliente_nome'] = nomeCliente;
        mapaProcessado['whatsapp'] = telLocal;
        mapaProcessado['telefone_principal'] = telLocal;
        final ddiInformado = (linha['ddi'] ?? '').toString().trim();
        mapaProcessado['ddi'] = ddiInformado.isEmpty ? '55' : ddiInformado;
        mapaProcessado['agenda_fixa_semana'] = agendaFixaSemana;
        mapaProcessado['agenda_historico'] = agendaHistorico;
        mapaProcessado['saldo_sessoes'] = _valorImportacaoParaInt(
          linha['saldo_sessoes'],
          padrao: 0,
        );
        mapaProcessado['favoritos'] = _valorImportacaoParaLista(
          linha['favoritos'],
        );

        final cliente = Cliente.fromMap(mapaProcessado);
        final dadosSalvar = cliente.toMap();
        // Usado pelo importarColecao para definir o ID do documento
        dadosSalvar['id'] = docId;
        clientesParaSalvar.add(dadosSalvar);
      } catch (e, stackTrace) {
        debugPrint('[FirestoreService] Erro ao importar linha de cliente: $e');
        debugPrintStack(stackTrace: stackTrace);
        erros++;
      }
    }

    // Escreve em lotes de 400 (limite do Firestore é 500)
    const batchSize = 400;
    for (int i = 0; i < clientesParaSalvar.length; i += batchSize) {
      final fim = (i + batchSize) < clientesParaSalvar.length
          ? i + batchSize
          : clientesParaSalvar.length;
      await importarColecao('clientes', clientesParaSalvar.sublist(i, fim));
      importados += fim - i;
    }

    return {'importados': importados, 'ignorados': ignorados, 'erros': erros};
  }
}
