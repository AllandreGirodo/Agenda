import 'package:cloud_firestore/cloud_firestore.dart';

class Cliente {
  final String idCliente;
  final String? nomeCliente;
  final String? nomePreferidoCliente;
  final String? ddiCliente;
  final String? whatsappCliente;
  final String? telefonePrincipalCliente;
  final String? nomeContatoSecundarioCliente;
  final String? telefoneSecundarioCliente;
  final String? nomeIndicacaoCliente;
  final String? telefoneIndicacaoCliente;
  final String? categoriaOrigemCliente;
  final bool? presencaAgendaCliente;
  final int? frequenciaHistoricaAgendaCliente;
  final DateTime? ultimaDataAgendadaCliente;
  final String? ultimoHorarioAgendadoCliente;
  final String? ultimoDiaSemanaAgendadoCliente;
  final bool? sugestaoClienteFixo;
  final String? cpfCliente;
  final String? cepCliente;
  final int? saldoSessoesCliente;
  final DateTime? dataNascimentoCliente;
  final List<String>? favoritosCliente;
  final String? enderecoCliente;
  final String? historicoMedicoCliente;
  final String? alergiasCliente;
  final String? medicamentosCliente;
  final String? cirurgiasCliente;
  final bool? anamneseOkCliente;
  final Map<String, bool>? agendaFixaSemanaCliente;
  final Map<String, dynamic>? agendaHistoricoCliente;

  // Getters de compatibilidade para telas legadas
  String get uid => idCliente;
  String get nome => nomeCliente ?? '';
  String get nomeExibicao {
    final nomePreferido = (nomePreferidoCliente ?? '').trim();
    if (nomePreferido.isNotEmpty) return nomePreferido;
    return nome;
  }
  String get ddi => ddiCliente ?? '55';
  String get whatsapp => whatsappCliente ?? '';
  String get telefonePrincipal => telefonePrincipalCliente ?? whatsapp;
  String get nomeContatoSecundario => nomeContatoSecundarioCliente ?? '';
  String get telefoneSecundario => telefoneSecundarioCliente ?? '';
  String get nomeIndicacao => nomeIndicacaoCliente ?? '';
  String get telefoneIndicacao => telefoneIndicacaoCliente ?? '';
  String get categoriaOrigem => categoriaOrigemCliente ?? '';
  bool get presencaAgenda => presencaAgendaCliente ?? false;
  int get frequenciaHistoricaAgenda => frequenciaHistoricaAgendaCliente ?? 0;
  String get ultimoHorarioAgendado => ultimoHorarioAgendadoCliente ?? '';
  String get ultimoDiaSemanaAgendado => ultimoDiaSemanaAgendadoCliente ?? '';
  bool get sugestaoClienteFixoAgenda => sugestaoClienteFixo ?? false;
  String get cpf => cpfCliente ?? '';
  String get cep => cepCliente ?? '';
  String get endereco => enderecoCliente ?? '';
  String get historicoMedico => historicoMedicoCliente ?? '';
  String get alergias => alergiasCliente ?? '';
  String get medicamentos => medicamentosCliente ?? '';
  String get cirurgias => cirurgiasCliente ?? '';
  DateTime? get dataNascimento => dataNascimentoCliente;
  List<String> get favoritos => favoritosCliente ?? const [];
  int get saldoSessoes => saldoSessoesCliente ?? 0;
  Map<String, bool> get agendaFixaSemana =>
      agendaFixaSemanaCliente ?? const <String, bool>{};
  Map<String, dynamic> get agendaHistorico =>
      agendaHistoricoCliente ?? const <String, dynamic>{};

  Cliente({
    required this.idCliente,
    this.nomeCliente,
    this.nomePreferidoCliente,
    this.ddiCliente,
    this.whatsappCliente,
    this.telefonePrincipalCliente,
    this.nomeContatoSecundarioCliente,
    this.telefoneSecundarioCliente,
    this.nomeIndicacaoCliente,
    this.telefoneIndicacaoCliente,
    this.categoriaOrigemCliente,
    this.presencaAgendaCliente,
    this.frequenciaHistoricaAgendaCliente,
    this.ultimaDataAgendadaCliente,
    this.ultimoHorarioAgendadoCliente,
    this.ultimoDiaSemanaAgendadoCliente,
    this.sugestaoClienteFixo,
    this.cpfCliente,
    this.cepCliente,
    this.dataNascimentoCliente,
    this.saldoSessoesCliente,
    this.favoritosCliente,
    this.enderecoCliente,
    this.historicoMedicoCliente,
    this.alergiasCliente,
    this.medicamentosCliente,
    this.cirurgiasCliente,
    this.anamneseOkCliente,
    this.agendaFixaSemanaCliente,
    this.agendaHistoricoCliente,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': idCliente,
      'cliente_nome': nomeCliente,
      'nome_preferido': nomePreferidoCliente,
      'ddi': ddiCliente ?? '55',
      'whatsapp': whatsappCliente ?? telefonePrincipalCliente,
      'telefone_principal': telefonePrincipalCliente ?? whatsappCliente,
      'nome_contato_secundario': nomeContatoSecundarioCliente,
      'telefone_secundario': telefoneSecundarioCliente,
      'nome_indicacao': nomeIndicacaoCliente,
      'telefone_indicacao': telefoneIndicacaoCliente,
      'categoria_origem': categoriaOrigemCliente,
      'presenca_agenda': presencaAgendaCliente,
      'frequencia_historica_agenda': frequenciaHistoricaAgendaCliente,
      'ultima_data_agendada':
          ultimaDataAgendadaCliente != null
              ? Timestamp.fromDate(ultimaDataAgendadaCliente!)
              : null,
      'ultimo_horario_agendado': ultimoHorarioAgendadoCliente,
      'ultimo_dia_semana_agendado': ultimoDiaSemanaAgendadoCliente,
      'sugestao_cliente_fixo': sugestaoClienteFixo,
      'cpf': cpfCliente,
      'cep': cepCliente,
      'data_nascimento':
          dataNascimentoCliente != null ? Timestamp.fromDate(dataNascimentoCliente!) : null,
      'saldo_sessoes': saldoSessoesCliente,
      'favoritos': favoritosCliente,
      'endereco': enderecoCliente,
      'historico_medico': historicoMedicoCliente,
      'alergias': alergiasCliente,
      'medicamentos': medicamentosCliente,
      'cirurgias': cirurgiasCliente,
      'anamnese_ok': anamneseOkCliente,
      'agenda_fixa_semana': agendaFixaSemanaCliente,
      'agenda_historico': agendaHistoricoCliente,
    };

    map.removeWhere((key, value) => value == null);
    return map;
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      idCliente: (map['uid'] ?? map['id'] ?? '').toString(),
      nomeCliente: map['cliente_nome'] ?? map['nome'] ?? map['Nome Principal'],
      nomePreferidoCliente: map['nome_preferido'] as String?,
      ddiCliente: map['ddi'] as String?,
      whatsappCliente: map['whatsapp'] ?? map['Telefone Principal'],
      telefonePrincipalCliente:
          map['telefone_principal'] as String? ??
          map['whatsapp'] as String? ??
          map['Telefone Principal'] as String?,
      nomeContatoSecundarioCliente:
          map['nome_contato_secundario'] as String? ??
          map['nome_secundario'] as String?,
      // alias: coluna "nome secundario" (sem acento) da planilha
      telefoneSecundarioCliente: map['telefone_secundario'] as String?,
      nomeIndicacaoCliente:
          map['nome_indicacao'] as String? ?? map['nome indicado'] as String?,
      telefoneIndicacaoCliente:
          map['telefone_indicacao'] as String? ??
          map['telefone indicado'] as String?,
      categoriaOrigemCliente:
          map['categoria_origem'] as String? ?? map['Categoria'] as String?,
      presencaAgendaCliente: _asBool(
        map['presenca_agenda'] ?? map['Presença na Agenda'],
      ),
      frequenciaHistoricaAgendaCliente:
          _asInt(map['frequencia_historica_agenda']) ??
          _asInt(map['Frequência Histórica (Agenda)']),
      ultimaDataAgendadaCliente: _asDateTime(
        map['ultima_data_agendada'] ?? map['Última Data Agendada'],
      ),
      ultimoHorarioAgendadoCliente:
          map['ultimo_horario_agendado'] as String? ??
          map['Último Horário Agendado'] as String?,
      ultimoDiaSemanaAgendadoCliente:
          map['ultimo_dia_semana_agendado'] as String? ??
          map['Último Dia da Semana'] as String?,
      sugestaoClienteFixo: _asBool(
        map['sugestao_cliente_fixo'] ?? map['Sugestão Cliente Fixo'],
      ),
      cpfCliente: map['cpf'] as String?,
      cepCliente: map['cep'] as String?,
      dataNascimentoCliente: _asDateTime(
        map['data_nascimento'] ??
            map['Data Nascimento'] ??
            map['Data de Nascimento'],
      ),
      saldoSessoesCliente:
          _asInt(map['saldo_sessoes']) ?? _asInt(map['Saldo Sessões']),
      favoritosCliente: _asStringList(map['favoritos']),
      enderecoCliente: map['endereco'],
      historicoMedicoCliente: map['historico_medico'],
      alergiasCliente: map['alergias'],
      medicamentosCliente: map['medicamentos'],
      cirurgiasCliente: map['cirurgias'],
      anamneseOkCliente: map['anamnese_ok'],
      agendaFixaSemanaCliente: _asStringBoolMap(map['agenda_fixa_semana']),
      agendaHistoricoCliente: map['agenda_historico'] != null
          ? Map<String, dynamic>.from(map['agenda_historico'] as Map)
          : null,
    );
  }

  static bool? _asBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (
          normalized == 'sim' ||
          normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'verdadeiro') {
        return true;
      }
      if (
          normalized == 'não' ||
          normalized == 'nao' ||
          normalized == 'false' ||
          normalized == '0' ||
          normalized == 'no' ||
          normalized == 'falso') {
        return false;
      }
    }
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    final str = value.toString().trim();
    if (str.isEmpty || str == 'None' || str == 'null') return null;
    final semEspacos = str.replaceAll(RegExp(r'\s+'), '');
    // Tenta formato ISO primeiro
    final iso = DateTime.tryParse(semEspacos);
    if (iso != null) return iso;
    // Tenta DD/MM/YYYY ou DD-MM-YYYY (formato da planilha)
    final m = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(
      semEspacos,
    );
    if (m != null) {
      final dia = m.group(1)!.padLeft(2, '0');
      final mes = m.group(2)!.padLeft(2, '0');
      final ano = m.group(3)!;
      return DateTime.tryParse('$ano-$mes-$dia');
    }
    return null;
  }

  static List<String>? _asStringList(dynamic value) {
    if (value == null) return null;

    if (value is List) {
      final lista = value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
      return lista;
    }

    final bruto = value.toString().trim();
    if (bruto.isEmpty) return <String>[];

    final separador = bruto.contains(';') ? ';' : ',';
    return bruto
        .split(separador)
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static Map<String, bool>? _asStringBoolMap(dynamic value) {
    if (value == null || value is! Map) return null;

    final result = <String, bool>{};
    for (final entry in value.entries) {
      final parsed = _asBool(entry.value);
      if (parsed != null) {
        result[entry.key.toString()] = parsed;
      }
    }
    return result.isEmpty ? null : result;
  }
}
