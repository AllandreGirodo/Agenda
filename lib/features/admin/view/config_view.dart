import 'package:flutter/material.dart';
import 'package:agenda/core/services/firestore_service.dart';
import 'package:agenda/core/models/config_model.dart';
import 'package:agenda/core/utils/app_strings.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';

class AdminConfigView extends StatefulWidget {
  const AdminConfigView({super.key});

  static bool isCompactLayoutForWidth(double largura) => largura < 640;

  @override
  State<AdminConfigView> createState() => _AdminConfigViewState();
}

class _AdminConfigViewState extends State<AdminConfigView> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, bool> _campos = {};
  int _horasAntecedencia = 24;
  int _inicioSono = 22;
  int _fimSono = 6;
  double _precoSessao = 100.0;
  int _statusCampoCupom = 1;
  bool _isLoading = true;
  bool _biometriaAtiva = true;
  bool _chatAtivo = true;
  bool _reciboLeitura = true;
  String _senhaAdminFerramentas = '';
  bool _mensagensAleatoriasAtivas = false;
  bool _processandoDisparoMensagens = false;
  int _intervaloMensagensDias = 7;
  bool _usarNomePreferidoNasMensagens = true;
  bool _enviarMensagensSemAgendamento = false;
  int _indiceMensagemSelecionadaClientes = -1;
  List<String> _mensagensAleatoriasClientes = List<String>.from(
    AppStrings.configMensagensAleatoriasPadrao,
  );

  // Campos que não podem ser desmarcados pelo admin (Regra de Negócio/Segurança)
  final List<String> _camposCriticos = [
    'whatsapp',
    'data_nascimento',
    'termos_uso',
  ];

  // Mapa de nomes amigáveis para exibição
  final Map<String, String> _labels = AppStrings.labelsConfig;

  @override
  void initState() {
    super.initState();
    _carregarConfig();
  }

  Future<void> _carregarConfig() async {
    final config = await _firestoreService.getConfiguracao();

    // Busca senha admin atual
    final senhaAtual = await _firestoreService
        .buscarSenhaAdminFerramentasAtual();

    setState(() {
      _campos = Map.from(config.camposObrigatorios);

      // Garante que campos críticos estejam marcados como TRUE, mesmo que venham false do banco
      for (var critico in _camposCriticos) {
        _campos[critico] = true;
      }

      _horasAntecedencia = config.horasAntecedenciaCancelamento.toInt();
      _inicioSono = config.inicioSono;
      _fimSono = config.fimSono;
      _precoSessao = config.precoSessao;
      _statusCampoCupom = config.statusCampoCupom;
      _biometriaAtiva = config.biometriaAtiva;
      _chatAtivo = config.chatAtivo;
      _reciboLeitura = config.reciboLeitura;
      _mensagensAleatoriasAtivas = config.mensagensAleatoriasAtivas;
      _intervaloMensagensDias = config.intervaloMensagensDias;
      _usarNomePreferidoNasMensagens = config.usarNomePreferidoNasMensagens;
      _enviarMensagensSemAgendamento = config.enviarMensagensSemAgendamento;
        _indiceMensagemSelecionadaClientes =
          config.indiceMensagemSelecionadaClientes;
      _mensagensAleatoriasClientes = config.mensagensAleatoriasClientes
          .map((mensagem) => mensagem.trim())
          .where((mensagem) => mensagem.isNotEmpty)
          .toList();
      if (_mensagensAleatoriasClientes.isEmpty) {
        _mensagensAleatoriasClientes = List<String>.from(
          AppStrings.configMensagensAleatoriasPadrao,
        );
      }
      if (_indiceMensagemSelecionadaClientes >=
          _mensagensAleatoriasClientes.length) {
        _indiceMensagemSelecionadaClientes = -1;
      }
      _senhaAdminFerramentas = senhaAtual ?? '';
      _isLoading = false;
    });

    // Se algum valor estava vazio/padrão e veio do código, salva no banco
    await _garantirValoresPadrao(config);
  }

  Future<void> _garantirValoresPadrao(ConfigModel config) async {
    // Se a configuração estava vazia ou com valores default, força salvamento
    bool precisaSalvar = false;

    if (config.horasAntecedenciaCancelamento == 24 &&
        config.inicioSono == 22 &&
        config.fimSono == 6) {
      precisaSalvar = true;
    }

    if (precisaSalvar) {
      await _firestoreService.salvarConfiguracao(config);
    }
  }

  Future<void> _salvar() async {
    await _firestoreService.salvarConfiguracao(
      ConfigModel(
        camposObrigatorios: _campos,
        horasAntecedenciaCancelamento: _horasAntecedencia.toDouble(),
        inicioSono: _inicioSono,
        fimSono: _fimSono,
        precoSessao: _precoSessao,
        statusCampoCupom: _statusCampoCupom,
        biometriaAtiva: _biometriaAtiva,
        chatAtivo: _chatAtivo,
        reciboLeitura: _reciboLeitura,
        mensagensAleatoriasAtivas: _mensagensAleatoriasAtivas,
        intervaloMensagensDias: _intervaloMensagensDias,
        usarNomePreferidoNasMensagens: _usarNomePreferidoNasMensagens,
        enviarMensagensSemAgendamento: _enviarMensagensSemAgendamento,
        indiceMensagemSelecionadaClientes: _indiceMensagemSelecionadaClientes,
        mensagensAleatoriasClientes: _mensagensAleatoriasClientes,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.configSalvaSucesso)));
    }
  }

  Future<String> _gerarCsvColecao(String collectionPath) async {
    final data = await _firestoreService.getFullCollection(collectionPath);
    if (data.isEmpty) {
      return '';
    }

    final allKeys = data.expand((map) => map.keys).toSet().toList()..sort();
    final rows = <List<dynamic>>[allKeys];

    for (final map in data) {
      rows.add(allKeys.map((key) => map[key]?.toString() ?? '').toList());
    }

    return const CsvEncoder().convert(rows);
  }

  Future<void> _exportarBackupCsv() async {
    setState(() => _isLoading = true);
    try {
      const collections = <String>[
        'clientes',
        'agendamentos',
        'estoque',
        'configuracoes',
      ];

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final arquivos = <XFile>[];

      for (final collection in collections) {
        final csv = await _gerarCsvColecao(collection);
        if (csv.trim().isEmpty) {
          continue;
        }

        final file = File('${directory.path}/backup_${collection}_$timestamp.csv');
        await file.writeAsString(csv);
        arquivos.add(XFile(file.path));
      }

      if (!mounted) return;

      if (arquivos.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.colecaoVazia)));
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [...arquivos],
          text: AppStrings.backupAgendaMassoterapia,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.erroExportar('$e'))));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _layoutCompacto(BuildContext context) {
    return AdminConfigView.isCompactLayoutForWidth(
      MediaQuery.of(context).size.width,
    );
  }

  List<String> _mensagensValidas() {
    return _mensagensAleatoriasClientes
        .map((mensagem) => mensagem.trim())
        .where((mensagem) => mensagem.isNotEmpty)
        .toList();
  }

  String? _sortearMensagemAleatoria() {
    final mensagens = _mensagensValidas();
    if (mensagens.isEmpty) {
      return null;
    }
    final random = Random();
    return mensagens[random.nextInt(mensagens.length)];
  }

  String? _mensagemSelecionadaAtual() {
    if (_indiceMensagemSelecionadaClientes < 0) {
      return null;
    }

    if (_indiceMensagemSelecionadaClientes >=
        _mensagensAleatoriasClientes.length) {
      return null;
    }

    final mensagem =
        _mensagensAleatoriasClientes[_indiceMensagemSelecionadaClientes].trim();
    if (mensagem.isEmpty) {
      return null;
    }

    return mensagem;
  }

  Future<void> _mostrarPreviewMensagemAleatoria() async {
    final mensagem = _mensagemSelecionadaAtual() ?? _sortearMensagemAleatoria();
    if (mensagem == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.configMensagensNenhumaCadastrada)),
      );
      return;
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.configMensagensPreviewTitulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.fechar),
          ),
        ],
      ),
    );
  }

  Future<void> _executarDisparoMensagensAleatorias({
    required bool simulacao,
  }) async {
    if (_processandoDisparoMensagens) {
      return;
    }

    setState(() => _processandoDisparoMensagens = true);
    try {
      final resultado = await _firestoreService
          .dispararMensagensAleatoriasClientes(
            dryRun: simulacao,
            indiceMensagemSelecionada: _indiceMensagemSelecionadaClientes,
          );

      if (!mounted) return;

      final totalClientes = (resultado['totalClientes'] as num?)?.toInt() ?? 0;
      final elegiveis = (resultado['elegiveis'] as num?)?.toInt() ?? 0;
      final enviados = (resultado['enviados'] as num?)?.toInt() ?? 0;
      final simulados = (resultado['simulados'] as num?)?.toInt() ?? 0;
      final erros = (resultado['erros'] as num?)?.toInt() ?? 0;

      final textoRetorno = simulacao
          ? AppStrings.configMensagensResultadoSimulacao(
              totalClientes,
              elegiveis,
              simulados,
              erros,
            )
          : AppStrings.configMensagensResultadoDisparo(
              totalClientes,
              elegiveis,
              enviados,
              erros,
            );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(textoRetorno),
          backgroundColor: erros > 0 ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.configMensagensErroDisparo('$e')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processandoDisparoMensagens = false);
      }
    }
  }

  Future<void> _adicionarOuEditarMensagemAleatoria({int? index}) async {
    final controller = TextEditingController(
      text: index != null ? _mensagensAleatoriasClientes[index] : '',
    );
    final formKey = GlobalKey<FormState>();

    final resultado = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          index == null
              ? AppStrings.configMensagensAdicionar
              : AppStrings.configMensagensEditar,
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: AppStrings.configMensagensTextoLabel,
              hintText: AppStrings.configMensagensTextoHint,
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppStrings.configMensagensTextoObrigatorio;
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: Text(AppStrings.salvar),
          ),
        ],
      ),
    );

    controller.dispose();

    if (resultado == null) {
      return;
    }

    setState(() {
      if (index == null) {
        _mensagensAleatoriasClientes.add(resultado);
      } else {
        _mensagensAleatoriasClientes[index] = resultado;
      }
    });
  }

  Future<void> _removerMensagemAleatoria(int index) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.configMensagensRemoverTitulo),
        content: Text(AppStrings.configMensagensRemoverDescricao),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppStrings.cancelButton),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppStrings.apagarTudo),
          ),
        ],
      ),
    );

    if (confirmar != true) {
      return;
    }

    setState(() {
      _mensagensAleatoriasClientes.removeAt(index);
      if (_indiceMensagemSelecionadaClientes == index) {
        _indiceMensagemSelecionadaClientes = -1;
      } else if (_indiceMensagemSelecionadaClientes > index) {
        _indiceMensagemSelecionadaClientes -= 1;
      }
    });
  }

  Future<void> _configurarSenhaAdmin() async {
    final senhaController = TextEditingController();
    final confirmaSenhaController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _senhaAdminFerramentas.isEmpty
              ? AppStrings.configurarSenhaAdmin
              : AppStrings.alterarSenhaAdmin,
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: senhaController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppStrings.novaSenha,
                  hintText: AppStrings.minimoSeisCaracteres,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.senhaObrigatoria;
                  }
                  if (value.trim().length < 6) {
                    return AppStrings.minimoSeisCaracteres;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmaSenhaController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppStrings.confirmeSenha,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != senhaController.text) {
                    return AppStrings.senhasNaoCoincidem;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.cancelButton),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  await _firestoreService.salvarSenhaAdminFerramentas(
                    senhaController.text.trim(),
                  );
                  setState(
                    () => _senhaAdminFerramentas = senhaController.text.trim(),
                  );
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.senhaSalvaSucesso),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.erroSalvarSenha('$e')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(AppStrings.salvar),
          ),
        ],
      ),
    );

    senhaController.dispose();
    confirmaSenhaController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compacto = _layoutCompacto(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.configTitulo),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _salvar)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  AppStrings.configFinanceiro,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      initialValue: _precoSessao.toString(),
                      decoration: InputDecoration(
                        labelText: AppStrings.configPrecoSessao,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (val) => setState(
                        () => _precoSessao = double.tryParse(val) ?? 0.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.configRegrasCancelamento,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppStrings.configAntecedencia}: $_horasAntecedencia ${AppStrings.horasUnidade}',
                        ),
                        Slider(
                          value: _horasAntecedencia.toDouble(),
                          min: 0,
                          max: 72,
                          divisions: 72,
                          label:
                              '$_horasAntecedencia ${AppStrings.horasUnidade}',
                          onChanged: (val) =>
                              setState(() => _horasAntecedencia = val.toInt()),
                        ),
                        const Divider(),
                        Text(
                          AppStrings.configHorarioSono,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          AppStrings.configHorarioSonoDesc,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        compacto
                            ? Column(
                                children: [
                                  DropdownButtonFormField<int>(
                                    initialValue: _inicioSono,
                                    decoration: InputDecoration(
                                      labelText: AppStrings.configDormeAs,
                                    ),
                                    items: List.generate(
                                      24,
                                      (i) => DropdownMenuItem(
                                        value: i,
                                        child: Text(AppStrings.horaDoDiaLabel(i)),
                                      ),
                                    ),
                                    onChanged: (v) =>
                                        setState(() => _inicioSono = v!),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<int>(
                                    initialValue: _fimSono,
                                    decoration: InputDecoration(
                                      labelText: AppStrings.configAcordaAs,
                                    ),
                                    items: List.generate(
                                      24,
                                      (i) => DropdownMenuItem(
                                        value: i,
                                        child: Text(AppStrings.horaDoDiaLabel(i)),
                                      ),
                                    ),
                                    onChanged: (v) =>
                                        setState(() => _fimSono = v!),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      initialValue: _inicioSono,
                                      decoration: InputDecoration(
                                        labelText: AppStrings.configDormeAs,
                                      ),
                                      items: List.generate(
                                        24,
                                        (i) => DropdownMenuItem(
                                          value: i,
                                          child: Text(AppStrings.horaDoDiaLabel(i)),
                                        ),
                                      ),
                                      onChanged: (v) =>
                                          setState(() => _inicioSono = v!),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      initialValue: _fimSono,
                                      decoration: InputDecoration(
                                        labelText: AppStrings.configAcordaAs,
                                      ),
                                      items: List.generate(
                                        24,
                                        (i) => DropdownMenuItem(
                                          value: i,
                                          child: Text(AppStrings.horaDoDiaLabel(i)),
                                        ),
                                      ),
                                      onChanged: (v) =>
                                          setState(() => _fimSono = v!),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.configCupons,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DropdownButtonFormField<int>(
                      initialValue: _statusCampoCupom,
                      decoration: InputDecoration(
                        labelText: AppStrings.configEstadoCampoCupom,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<int>(
                          value: 1,
                          child: Text(AppStrings.configCupomAtivo),
                        ),
                        DropdownMenuItem<int>(
                          value: 2,
                          child: Text(AppStrings.configCupomOculto),
                        ),
                        DropdownMenuItem<int>(
                          value: 3,
                          child: Text(
                            '${AppStrings.configCupomOpaco} - ${AppStrings.configCupomOpacoDesc}',
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _statusCampoCupom = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.segurancaSenhaAdmin,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.senhaAcessoDevTools,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.senhaProtegeDevTools,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        compacto
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _senhaAdminFerramentas.isEmpty
                                        ? AppStrings.naoConfigurada
                                        : '••••••••',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _senhaAdminFerramentas.isEmpty
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: Icon(
                                        _senhaAdminFerramentas.isEmpty
                                            ? Icons.add_circle
                                            : Icons.edit,
                                      ),
                                      label: Text(
                                        _senhaAdminFerramentas.isEmpty
                                            ? AppStrings.configurar
                                            : AppStrings.alterarSenha,
                                      ),
                                      onPressed: _configurarSenhaAdmin,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _senhaAdminFerramentas.isEmpty
                                          ? AppStrings.naoConfigurada
                                          : '••••••••',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _senhaAdminFerramentas.isEmpty
                                            ? Colors.red
                                            : Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    icon: Icon(
                                      _senhaAdminFerramentas.isEmpty
                                          ? Icons.add_circle
                                          : Icons.edit,
                                    ),
                                    label: Text(
                                      _senhaAdminFerramentas.isEmpty
                                          ? AppStrings.configurar
                                          : AppStrings.alterarSenha,
                                    ),
                                    onPressed: _configurarSenhaAdmin,
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.configBiometria,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                SwitchListTile(
                  title: Text(AppStrings.ativarBiometria),
                  subtitle: Text(AppStrings.configBiometriaDesc),
                  value: _biometriaAtiva,
                  onChanged: (val) => setState(() => _biometriaAtiva = val),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.configChat,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                SwitchListTile(
                  title: Text(AppStrings.configChatAtivo),
                  subtitle: Text(AppStrings.configChatDesc),
                  value: _chatAtivo,
                  onChanged: (val) => setState(() => _chatAtivo = val),
                ),
                SwitchListTile(
                  title: Text(AppStrings.configReciboLeitura),
                  subtitle: Text(AppStrings.exibirIconesLido),
                  value: _reciboLeitura,
                  onChanged: (val) => setState(() => _reciboLeitura = val),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.configMensagensAleatoriasTitulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            AppStrings.configMensagensAleatoriasAtivar,
                          ),
                          subtitle: Text(
                            AppStrings.configMensagensAleatoriasDescricao,
                          ),
                          value: _mensagensAleatoriasAtivas,
                          onChanged: (val) =>
                              setState(() => _mensagensAleatoriasAtivas = val),
                        ),
                        if (_mensagensAleatoriasAtivas) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${AppStrings.configMensagensIntervalo}: $_intervaloMensagensDias ${AppStrings.diasUnidade}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Slider(
                            value: _intervaloMensagensDias.toDouble(),
                            min: 1,
                            max: 30,
                            divisions: 29,
                            label:
                                '$_intervaloMensagensDias ${AppStrings.diasUnidade}',
                            onChanged: (val) => setState(
                              () => _intervaloMensagensDias = val.toInt(),
                            ),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              AppStrings.configMensagensUsarNomePreferido,
                            ),
                            subtitle: Text(
                              AppStrings
                                  .configMensagensUsarNomePreferidoDescricao,
                            ),
                            value: _usarNomePreferidoNasMensagens,
                            onChanged: (val) => setState(
                              () => _usarNomePreferidoNasMensagens = val,
                            ),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              AppStrings.configMensagensSemAgendamento,
                            ),
                            subtitle: Text(
                              AppStrings.configMensagensSemAgendamentoDescricao,
                            ),
                            value: _enviarMensagensSemAgendamento,
                            onChanged: (val) => setState(
                              () => _enviarMensagensSemAgendamento = val,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.configMensagensSelecaoTitulo,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.configMensagensSelecaoDescricao,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue:
                                (_indiceMensagemSelecionadaClientes >= 0 &&
                                    _indiceMensagemSelecionadaClientes <
                                        _mensagensAleatoriasClientes.length)
                                ? _indiceMensagemSelecionadaClientes
                                : -1,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem<int>(
                                value: -1,
                                child: Text(
                                  AppStrings.configMensagensSelecaoAleatoria,
                                ),
                              ),
                              ...List.generate(
                                _mensagensAleatoriasClientes.length,
                                (index) {
                                  final mensagem =
                                      _mensagensAleatoriasClientes[index]
                                          .trim();
                                  final resumo = mensagem.length > 64
                                      ? '${mensagem.substring(0, 64)}...'
                                      : mensagem;
                                  return DropdownMenuItem<int>(
                                    value: index,
                                    child: Text(
                                      '${AppStrings.configMensagensOpcaoNumero(index + 1)} - $resumo',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(
                                () => _indiceMensagemSelecionadaClientes =
                                    value,
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _mostrarPreviewMensagemAleatoria,
                                icon: const Icon(Icons.auto_fix_high),
                                label: Text(
                                  AppStrings.configMensagensPreviewBotao,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _adicionarOuEditarMensagemAleatoria(),
                                icon: const Icon(Icons.add),
                                label: Text(
                                  AppStrings.configMensagensAdicionar,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _mensagensAleatoriasClientes =
                                        List<String>.from(
                                          AppStrings
                                              .configMensagensAleatoriasPadrao,
                                        );
                                    if (_indiceMensagemSelecionadaClientes >=
                                        _mensagensAleatoriasClientes.length) {
                                      _indiceMensagemSelecionadaClientes = -1;
                                    }
                                  });
                                },
                                icon: const Icon(Icons.restore),
                                label: Text(
                                  AppStrings.configMensagensRestaurarPadrao,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _processandoDisparoMensagens
                                    ? null
                                    : () => _executarDisparoMensagensAleatorias(
                                        simulacao: true,
                                      ),
                                icon: _processandoDisparoMensagens
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.science_outlined),
                                label: Text(
                                  AppStrings.configMensagensSimularDisparo,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _processandoDisparoMensagens
                                    ? null
                                    : () => _executarDisparoMensagensAleatorias(
                                        simulacao: false,
                                      ),
                                icon: _processandoDisparoMensagens
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.campaign),
                                label: Text(
                                  AppStrings.configMensagensDispararAgora,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_mensagensAleatoriasClientes.isEmpty)
                            Text(
                              AppStrings.configMensagensNenhumaCadastrada,
                              style: const TextStyle(color: Colors.grey),
                            )
                          else
                            ...List.generate(
                              _mensagensAleatoriasClientes.length,
                              (index) {
                                final mensagem =
                                    _mensagensAleatoriasClientes[index].trim();
                                if (mensagem.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Card(
                                  elevation: 0,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      radius: 14,
                                      child: Text(AppStrings.indiceListaLabel(index + 1)),
                                    ),
                                    title: Text(mensagem),
                                    subtitle:
                                        _indiceMensagemSelecionadaClientes ==
                                            index
                                        ? Text(
                                            AppStrings
                                                .configMensagensSelecionadaBadge,
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )
                                        : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          tooltip:
                                              AppStrings.configMensagensEditar,
                                          onPressed: () =>
                                              _adicionarOuEditarMensagemAleatoria(
                                                index: index,
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          tooltip: AppStrings
                                              .configMensagensRemoverTitulo,
                                          onPressed: () =>
                                              _removerMensagemAleatoria(index),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.backupTitulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppStrings.backupSomenteCsv,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final larguraBotao = constraints.maxWidth;

                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: larguraBotao,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.download),
                            label: Text(AppStrings.backupExportarCsv),
                            onPressed: _exportarBackupCsv,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.configCamposObrigatorios,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._labels.keys.map((key) {
                  final isCritico = _camposCriticos.contains(key);
                  return SwitchListTile(
                    title: Text(_labels[key]!),
                    subtitle: isCritico
                        ? Text(
                            AppStrings.configCampoCritico,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    value: _campos[key] ?? false,
                    onChanged: isCritico
                        ? null
                        : (val) => setState(() => _campos[key] = val),
                  );
                }),
              ],
            ),
    );
  }
}
