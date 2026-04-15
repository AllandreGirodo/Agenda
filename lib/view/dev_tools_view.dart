import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agenda/core/services/firestore_service.dart';
import 'package:agenda/core/utils/app_strings.dart';
import 'package:agenda/features/admin/view/admin_ferramentas_senha_setup_view.dart';
import 'db_seeder.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/models/log_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'import_preview_dialog.dart';

class DevToolsView extends StatefulWidget {
  const DevToolsView({super.key});

  @override
  State<DevToolsView> createState() => _DevToolsViewState();

  static bool isCompactLayoutForWidth(double largura, {bool modoCompacto = false}) =>
      modoCompacto || largura < 800;
}

class _DevToolsViewState extends State<DevToolsView> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  late final String _senhaDev = _carregarSenhaDev();
  bool _autenticado = false;
  bool _devicePreviewEnabled = false;
  bool _valorTesteBooleanoBanco = false;
  bool _senhaConfigurada = true; // Assume configurada até verificar

  // Lista de Collections do sistema
  final List<String> _collections = [
    'usuarios',
    'clientes',
    'agendamentos',
    'estoque',
    'configuracoes',
    'cupons',
    'logs',
    'lgpd_logs',
    'changelogs',
    'app_software',
    'app_changelog',
  ];

  @override
  void initState() {
    super.initState();
    // Verifica se a senha está configurada
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final permitido = await _usuarioPodeAcessarDevTools();
      if (!permitido) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppStrings.acessoNegado)));
        }
        await _fecharTelaSemAutenticacao();
        return;
      }

      final existe = await _firestoreService
          .verificaSenhaAdminFerramentasConfigurada();
      if (!mounted) return;
      setState(() => _senhaConfigurada = existe);

      // Se configurada, pede a senha para autenticar
      if (existe && !_autenticado) {
        _pedirSenha();
      }
    });
    _carregarPrefs();
  }

  Future<bool> _usuarioPodeAcessarDevTools() async {
    final usuarioAuth = FirebaseAuth.instance.currentUser;
    if (usuarioAuth == null) return false;

    final usuario = await _firestoreService.getUsuario(usuarioAuth.uid);
    return _firestoreService.podeAcessarPainelDev(usuario);
  }

  String _carregarSenhaDev() {
    try {
      return (dotenv.env['DB_ADMIN_PASSWORD'] ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  String _envTrim(String key) => (dotenv.env[key] ?? '').trim();

  String? _textoNaoVazio(Object? valor) {
    if (valor == null) {
      return null;
    }

    final texto = valor.toString().trim();
    return texto.isEmpty ? null : texto;
  }

  Map<String, dynamic> _mapaDinamico(dynamic valor) {
    if (valor is Map<String, dynamic>) {
      return valor;
    }
    if (valor is Map) {
      return valor.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  String _detectarSeparadorCsv(String conteudo) {
    final primeiraLinha = conteudo
        .split(RegExp(r'\r?\n'))
        .map((linha) => linha.trim())
        .firstWhere((linha) => linha.isNotEmpty, orElse: () => '');

    if (primeiraLinha.isEmpty) {
      return ',';
    }

    final qtdPontoVirgula = ';'.allMatches(primeiraLinha).length;
    final qtdVirgula = ','.allMatches(primeiraLinha).length;
    final qtdTab = '\t'.allMatches(primeiraLinha).length;

    if (qtdPontoVirgula >= qtdVirgula &&
        qtdPontoVirgula >= qtdTab &&
        qtdPontoVirgula > 0) {
      return ';';
    }

    if (qtdTab >= qtdVirgula && qtdTab > 0) {
      return '\t';
    }

    return ',';
  }

  Map<String, dynamic> _normalizarRespostaExportacao(dynamic valor) {
    final mapaBase = _mapaDinamico(valor);
    final payload = mapaBase['result'] is Map
        ? _mapaDinamico(mapaBase['result'])
        : mapaBase['data'] is Map
        ? _mapaDinamico(mapaBase['data'])
        : mapaBase;
    final metadata = _mapaDinamico(payload['metadata']);
    final binId =
        _textoNaoVazio(payload['binId']) ??
        _textoNaoVazio(payload['id']) ??
        _textoNaoVazio(metadata['id']);
    final urlDireta =
        _textoNaoVazio(payload['url']) ??
        _textoNaoVazio(payload['apiUrl']) ??
        _textoNaoVazio(payload['binUrl']);
    final baseUrl = _envTrim('EXPORT_JSONBIN_URL');
    final url =
        urlDireta ??
        (binId != null && baseUrl.isNotEmpty ? '$baseUrl/$binId' : null);

    if (binId == null || url == null) {
      throw Exception(AppStrings.exportacaoBackendRespostaInvalida);
    }

    return {'binId': binId, 'url': url};
  }

  Future<Map<String, dynamic>> _exportarColecaoViaBackend(
    String collection,
    List<Map<String, dynamic>> data,
  ) async {
    final functionName = _envTrim('EXPORT_JSONBIN_FUNCTION_NAME');
    final proxyUrl = _envTrim('EXPORT_JSONBIN_PROXY_URL');
    final nomeConfigurado = _envTrim('EXPORT_JSONBIN_BIN_NAME');
    final descricaoConfigurada = _envTrim('EXPORT_JSONBIN_BIN_DESCRIPTION');
    final binIdConfigurado = _envTrim('EXPORT_JSONBIN_BIN_ID');
    final payload = <String, dynamic>{
      'collection': collection,
      'data': data,
      'binName': nomeConfigurado.isNotEmpty
          ? nomeConfigurado
          : '${collection}_export_${DateTime.now().millisecondsSinceEpoch}',
      if (descricaoConfigurada.isNotEmpty)
        'binDescription': descricaoConfigurada,
      if (binIdConfigurado.isNotEmpty) 'binId': binIdConfigurado,
    };

    if (functionName.isNotEmpty) {
      final callable = _functions.httpsCallable(functionName);
      final result = await callable.call(payload);
      return _normalizarRespostaExportacao(result.data);
    }

    if (proxyUrl.isNotEmpty) {
      final response = await http.post(
        Uri.parse(proxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          AppStrings.erroExportacaoBackendStatus(response.statusCode.toString()),
        );
      }

      return _normalizarRespostaExportacao(jsonDecode(response.body));
    }

    throw Exception(AppStrings.exportacaoBackendNaoConfigurada);
  }

  Future<void> _carregarPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _devicePreviewEnabled = prefs.getBool('enable_device_preview') ?? false;
    });
  }

  Future<void> _toggleDevicePreview(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_device_preview', value);
    setState(() => _devicePreviewEnabled = value);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppStrings.reinicieApp)));
  }

  Future<void> _alternarTesteBooleanoNoBanco() async {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final usuarioAtual = FirebaseAuth.instance.currentUser;

    try {
      final valorAtual = await _firestoreService.alternarTesteBooleanoLoginView(
        emailDigitado: (usuarioAtual?.email ?? '').trim(),
        valorAtual: _valorTesteBooleanoBanco,
        uid: usuarioAtual?.uid,
        origem: 'dev_tools_view',
      );

      if (!mounted) return;
      setState(() => _valorTesteBooleanoBanco = valorAtual);
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.testeBooleanoBancoSucesso(valorAtual))),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.testeBooleanoBancoErro(e.toString()))),
      );
    }
  }

  Future<String?> _solicitarSenha({
    required String titulo,
    required String descricao,
    required String labelCampo,
  }) async {
    final controller = TextEditingController();
    final senha = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(descricao),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: labelCampo,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.cancelButton),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(AppStrings.confirmar),
          ),
        ],
      ),
    );
    controller.dispose();
    return senha;
  }

  Future<void> _fecharTelaSemAutenticacao() async {
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _operacaoAposConfigure() async {
    if (!mounted) return;
    setState(() => _senhaConfigurada = true);
    // Pede a senha para autenticar após configurar
    _pedirSenha();
  }

  Future<void> _pedirSenha() async {
    final senhaColecao = await _solicitarSenha(
      titulo: 'Acesso ao Banco de Dados',
      descricao:
          'Etapa 1/2: informe a senha de administrador salva no Firestore.',
      labelCampo: 'Senha da Collection (Admin)',
    );

    if (senhaColecao == null || senhaColecao.isEmpty) {
      await _fecharTelaSemAutenticacao();
      return;
    }

    bool senhaColecaoValida = false;
    try {
      senhaColecaoValida = await _firestoreService.validarSenhaAdminFerramentas(
        senhaColecao,
      );
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
      await _fecharTelaSemAutenticacao();
      return;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.naoValidarSenhaCollection)),
        );
      }
      await _fecharTelaSemAutenticacao();
      return;
    }

    if (!senhaColecaoValida) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.senhaCollectionIncorreta)),
        );
      }
      await _fecharTelaSemAutenticacao();
      return;
    }

    if (_senhaDev.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.senhaDevNaoConfigurada)),
        );
      }
      await _fecharTelaSemAutenticacao();
      return;
    }

    final senhaDev = await _solicitarSenha(
      titulo: 'Confirmacao de Desenvolvedor',
      descricao: 'Etapa 2/2: confirme com a senha de desenvolvimento (.env).',
      labelCampo: 'Senha Dev (.env)',
    );

    if (senhaDev == null || senhaDev.isEmpty) {
      await _fecharTelaSemAutenticacao();
      return;
    }

    if (senhaDev != _senhaDev) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.senhaDevIncorreta)));
      }
      await _fecharTelaSemAutenticacao();
      return;
    }

    if (!mounted) return;
    setState(() => _autenticado = true);
  }

  Future<int> _contarDocumentos(String collection) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(collection)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<void> _popularCollection(String collection) async {
    setState(() {}); // Loading visual se necessário
    switch (collection) {
      case 'clientes':
      case 'usuarios':
        await DbSeeder.seedClientes();
        break;
      case 'agendamentos':
        await DbSeeder.seedAgendamentos();
        break;
      case 'estoque':
        await DbSeeder.seedEstoque();
        break;
      case 'configuracoes':
        await DbSeeder.seedConfiguracoes();
        break;
      case 'cupons':
        await DbSeeder.seedCupons();
        break;
      case 'changelogs':
        await _firestoreService.inicializarChangeLog();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.semScriptSeed(collection))),
        );
        return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.tabelaPopulada(collection))),
    );
    setState(() {}); // Atualiza contadores
  }

  Future<void> _limparCollection(String collection) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.truncateTable(collection)),
        content: Text(AppStrings.truncateConfirmacao(collection)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancelButton),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.apagarTudo),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.limparColecao(collection);
      if (!mounted) return;
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.collectionLimpa(collection))),
        );
      }
    }
  }

  // --- Exportação (JSON / CSV) ---
  Future<void> _exportarCollection(String collection, String formato) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.gerandoArquivo)));

      // 1. Busca dados
      final data = await _firestoreService.getFullCollection(collection);
      if (!mounted) return;
      if (data.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.colecaoVazia)));
        return;
      }

      dynamic conteudo;
      String extensao = '';
      bool isBinary = false;

      // 2. Serializa
      if (formato == 'json') {
        const encoder = JsonEncoder.withIndent('  ');
        conteudo = encoder.convert(data);
        extensao = 'json';
      } else if (formato == 'excel') {
        if (collection != 'agendamentos') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.excelApenasAgendamentos)),
          );
          return;
        }
        conteudo = await _firestoreService.gerarRelatorioAgendamentosExcel();
        extensao = 'xlsx';
        isBinary = true;
      } else {
        // Lógica CSV: Pega todas as chaves possíveis de todos os documentos
        final allKeys = data.expand((map) => map.keys).toSet().toList();
        List<List<dynamic>> rows = [];
        rows.add(allKeys); // Cabeçalho

        for (var map in data) {
          rows.add(allKeys.map((key) => map[key]?.toString() ?? '').toList());
        }

        conteudo = const CsvEncoder().convert(rows);
        extensao = 'csv';
      }

      // 3. Salva em arquivo temporário
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${collection}_export.$extensao');
      if (isBinary && conteudo is Uint8List) {
        await file.writeAsBytes(conteudo);
      } else {
        await file.writeAsString(conteudo.toString());
      }

      // 4. Compartilha (Share Sheet do OS)
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Exportação da tabela $collection',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.erroExportar(e.toString()))),
        );
      }
    }
  }

  // --- Exportação Web (JSONBin.io) ---
  Future<void> _exportarParaWeb(String collection) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.enviandoParaJsonBin)));

      if (!mounted) return;
      // 1. Busca dados
      final data = await _firestoreService.getFullCollection(collection);
      if (!mounted) return;
      if (data.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.colecaoVazia)));
        return;
      }

      // 2. Delegar a exportacao para backend/Cloud Functions.
      final exportacao = await _exportarColecaoViaBackend(collection, data);
      final binId = exportacao['binId'] as String;
      final url = exportacao['url'] as String;

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppStrings.exportacaoConcluida),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.dadosSalvosNuvem),
                const SizedBox(height: 10),
                SelectableText(
                  'Bin ID: $binId',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(AppStrings.urlApi),
                SelectableText(
                  url,
                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.copy),
                label: Text(AppStrings.copiarUrl),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppStrings.urlCopiada)),
                  );
                },
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.fechar),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.erroExportarWeb(e.toString()))),
        );
      }
    }
  }

  // --- Importação (JSON) ---
  Future<void> _importarCollection(String collection) async {
    try {
      // 1. Selecionar Arquivo
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (!mounted) return;

      if (result != null) {
        File file = File(result.files.single.path!);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.lendoArquivo)));

        // 2. Ler e Parsear JSON
        String conteudo = await file.readAsString();
        List<dynamic> jsonList = jsonDecode(conteudo);

        // Converter para List<Map<String, dynamic>>
        List<Map<String, dynamic>> dados = jsonList
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        // 3. Enviar para Firestore
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.importandoRegistros(dados.length)),
            ),
          );
        }
        await _firestoreService.importarColecao(collection, dados);

        if (!mounted) return;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.importacaoConcluida)),
          );
          setState(() {}); // Atualiza contadores
        }
      } else {
        // Usuário cancelou
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.erroImportar(e.toString()))),
      );
    }
  }

  // --- Importacao de Planilha de Clientes (CSV / XLSX) ---
  Future<void> _importarPlanilhaClientes() async {
    try {
      final pickerResult = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true,
      );

      if (pickerResult == null || pickerResult.files.isEmpty) return;
      if (!mounted) return;

      final pickedFile = pickerResult.files.single;
      final ext = (pickedFile.extension ?? '').toLowerCase();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.lendoPlanilha)),
      );

      List<Map<String, dynamic>> linhas = [];
      List<String> headers = [];

      // 1. Parse do arquivo
      if (ext == 'csv') {
        final bytes =
            pickedFile.bytes ??
            (pickedFile.path != null
                ? await File(pickedFile.path!).readAsBytes()
                : null);

        if (bytes == null || bytes.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.formatoNaoSuportado)),
          );
          return;
        }

        final conteudo = utf8.decode(bytes, allowMalformed: true);
        final separador = _detectarSeparadorCsv(conteudo);
        final rows = CsvDecoder(
          fieldDelimiter: separador,
          dynamicTyping: false,
          parseHeaders: false,
        ).convert(conteudo);
        if (rows.isEmpty) return;

        headers = rows.first.map((e) => e.toString().trim()).toList();
        if (headers.isNotEmpty) {
          headers[0] = headers[0].replaceFirst('\ufeff', '').trim();
        }

        for (final row in rows.skip(1)) {
          if (row.every((v) => v.toString().trim().isEmpty)) continue;
          final map = <String, dynamic>{};
          for (int i = 0; i < headers.length; i++) {
            map[headers[i]] = i < row.length ? row[i] : null;
          }
          linhas.add(map);
        }
      } else if (ext == 'xlsx' || ext == 'xls') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.formatoExtensaoNaoSuportado(ext))),
        );
        return;
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.formatoNaoSuportado)),
        );
        return;
      }

      if (!mounted) return;

      // 2. Validar cabecalho
      final validacao = ImportPreviewHelper.validarCabecalho(headers);
      if (!validacao['valido']) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppStrings.erroValidacao),
            content: Text(validacao['erro'] ?? 'Erro desconhecido'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppStrings.fechar),
              ),
            ],
          ),
        );
        return;
      }

      // 3. Mostrar preview
      if (!mounted) return;
      final confirmado = await ImportPreviewHelper.mostrarPreview(
        context,
        headers: headers,
        linhas: linhas,
      );

      if (!confirmado || !mounted) return;

      // 4. Importar para o Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.importandoPlanilhaClientes(linhas.length))),
      );

      final resultado = await _firestoreService.importarPlanilhaClientes(linhas);

      if (!mounted) return;
      final imp = resultado['importados'] ?? 0;
      final ign = resultado['ignorados'] ?? 0;
      final err = resultado['erros'] ?? 0;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppStrings.importarPlanilhaTitle),
          content: Text(AppStrings.resultadoImportacaoPlanilha(imp, ign, err)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.fechar),
            ),
          ],
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.erroImportar(e.toString()))),
      );
    }
  }

  // --- Visualizador JSON ---
  void _abrirVisualizadorJson(String collection) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          // Usamos StatefulBuilder para gerenciar o estado do filtro de busca dentro do Modal
          String filtroBusca = '';

          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateModal) {
              return Scaffold(
                appBar: AppBar(
                  title: TextField(
                    decoration: InputDecoration(
                      hintText: AppStrings.buscarPorIdNomeEmail,
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.white),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setStateModal(() {
                        filtroBusca = value.toLowerCase();
                      });
                    },
                  ),
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                ),
                body: StreamBuilder<QuerySnapshot>(
                  // Aumentei o limite para permitir busca em mais itens,
                  // mas em produção o ideal seria busca no backend (.where)
                  stream: FirebaseFirestore.instance
                      .collection(collection)
                      .limit(100)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var docs = snapshot.data!.docs;

                    // Filtro Local
                    if (filtroBusca.isNotEmpty) {
                      docs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final id = doc.id.toLowerCase();
                        final nome =
                            (data['cliente_nome'] ?? data['nome'] ?? '')
                                .toString()
                                .toLowerCase();
                        final email = (data['email'] ?? '')
                            .toString()
                            .toLowerCase();
                        return id.contains(filtroBusca) ||
                            nome.contains(filtroBusca) ||
                            email.contains(filtroBusca);
                      }).toList();
                    }

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(AppStrings.nenhumDocumentoEncontrado),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: docs.length,
                      separatorBuilder: (c, i) => const Divider(),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        // Prioriza o novo campo de cliente e mantem compatibilidade com legado.
                        final titulo =
                            data['cliente_nome'] ??
                            data['nome'] ??
                            data['email'] ??
                            doc.id;

                        return ListTile(
                          title: Text(
                            titulo.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(AppStrings.uidLabel(doc.id)),
                          trailing: const Icon(
                            Icons.data_object,
                            color: Colors.teal,
                          ),
                          onTap: () => _mostrarDetalhesJson(doc.id, data),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _mostrarDetalhesJson(String id, Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(data);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.documentoDetalhesTitulo(id)),
        content: SingleChildScrollView(
          child: SelectableText(
            jsonString,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.fechar),
          ),
        ],
      ),
    );
  }

  // --- Console de Logs em Tempo Real ---
  void _abrirConsoleLogs() {
    // Variável local para controlar o filtro dentro do Modal
    String filtroSelecionado = 'todos';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          // StatefulBuilder permite atualizar apenas o conteúdo do modal ao mudar o filtro
          return StatefulBuilder(
            builder: (context, setStateModal) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.systemLogsRealtime,
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            // Filtro
                            DropdownButton<String>(
                              dropdownColor: Colors.grey[900],
                              value: filtroSelecionado,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              underline: Container(), // Remove a linha padrão
                              icon: const Icon(
                                Icons.filter_list,
                                color: Colors.greenAccent,
                                size: 16,
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'todos',
                                  child: Text(AppStrings.filtroTodos),
                                ),
                                DropdownMenuItem(
                                  value: 'erro',
                                  child: Text(AppStrings.filtroErros),
                                ),
                                DropdownMenuItem(
                                  value: 'aviso',
                                  child: Text(AppStrings.filtroAvisos),
                                ),
                                DropdownMenuItem(
                                  value: 'info',
                                  child: Text(AppStrings.filtroInfo),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setStateModal(
                                    () => filtroSelecionado = value,
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.terminal,
                              color: Colors.greenAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<LogModel>>(
                      stream: _firestoreService.getLogs(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              AppStrings.erroGenerico(
                                snapshot.error.toString(),
                              ),
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.greenAccent,
                            ),
                          );
                        }

                        var logs = snapshot.data!;
                        // Aplica o filtro localmente
                        if (filtroSelecionado != 'todos') {
                          logs = logs
                              .where((l) => l.tipo == filtroSelecionado)
                              .toList();
                        }

                        if (logs.isEmpty) {
                          return Center(
                            child: Text(
                              AppStrings.semLogsRegistrados,
                              style: const TextStyle(color: Colors.white54),
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          itemCount: logs.length,
                          separatorBuilder: (c, i) =>
                              const Divider(color: Colors.white12, height: 1),
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            Color color = Colors.white;
                            if (log.tipo == 'erro' ||
                                log.tipo == 'cancelamento') {
                              color = Colors.redAccent;
                            } else if (log.tipo == 'aviso') {
                              color = Colors.orangeAccent;
                            }

                            return ListTile(
                              dense: true,
                              leading: Text(
                                DateFormat('HH:mm:ss').format(log.dataHora),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              title: Text(
                                '[${log.tipo.toUpperCase()}]',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              subtitle: Text(
                                log.mensagem,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Se a senha não está configurada, mostra a tela de setup
    if (!_senhaConfigurada) {
      return AdminFerramentasSenhaSetupView(
        onConfirmed: () => _operacaoAposConfigure(),
      );
    }

    // Se não autenticado, mostra loading
    if (!_autenticado) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.devToolsDbManager),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.greenAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.terminal),
            tooltip: AppStrings.tooltipConsoleLogs,
            onPressed: _abrirConsoleLogs,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(AppStrings.ativarDevicePreview),
            subtitle: Text(AppStrings.requerReinicioApp),
            value: _devicePreviewEnabled,
            onChanged: _toggleDevicePreview,
            secondary: const Icon(
              Icons.devices_other,
              color: Colors.purpleAccent,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _alternarTesteBooleanoNoBanco,
                icon: const Icon(Icons.toggle_on_outlined),
                label: Text(AppStrings.testeBooleanoBancoBtn),
              ),
            ),
          ),
          const Divider(thickness: 2),
          ...List.generate(_collections.length * 2 - 1, (i) {
            if (i.isOdd) return const Divider();
            final index = i ~/ 2;
            final collection = _collections[index];
            return FutureBuilder<int>(
              future: _contarDocumentos(collection),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return ListTile(
                  leading: const Icon(Icons.table_chart),
                  title: Text(
                    collection,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(AppStrings.registros(count)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botão Visualizar JSON
                      IconButton(
                        icon: const Icon(
                          Icons.visibility,
                          color: Colors.purple,
                        ),
                        tooltip: AppStrings.tooltipVisualizarJson,
                        onPressed: () => _abrirVisualizadorJson(collection),
                      ),
                      // Botao Importar Planilha (so para clientes)
                      if (collection == 'clientes')
                        IconButton(
                          icon: const Icon(
                            Icons.upload_file,
                            color: Colors.teal,
                          ),
                          tooltip: AppStrings.tooltipImportarPlanilha,
                          onPressed: () => _importarPlanilhaClientes(),
                        ),
                      // Menu Exportar
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.download, color: Colors.orange),
                        tooltip: AppStrings.tooltipExportarDados,
                        onSelected: (format) {
                          if (format == 'web') {
                            _exportarParaWeb(collection);
                          } else {
                            _exportarCollection(collection, format);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'json',
                            child: Row(
                              children: [
                                const Icon(Icons.code, size: 18),
                                const SizedBox(width: 8),
                                Text(AppStrings.exportFormatoJson),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'csv',
                            child: Row(
                              children: [
                                const Icon(Icons.table_view, size: 18),
                                const SizedBox(width: 8),
                                Text(AppStrings.exportFormatoCsv),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'excel',
                            child: Row(
                              children: [
                                const Icon(Icons.grid_on, size: 18),
                                const SizedBox(width: 8),
                                Text(AppStrings.exportFormatoExcel),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'web',
                            child: Row(
                              children: [
                                const Icon(Icons.cloud_upload, size: 18),
                                const SizedBox(width: 8),
                                Text(AppStrings.exportFormatoWeb),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Botão Importar
                      IconButton(
                        icon: const Icon(
                          Icons.upload_file,
                          color: Colors.green,
                        ),
                        tooltip: AppStrings.tooltipImportarJson,
                        onPressed: () => _importarCollection(collection),
                      ),
                      // Botões Existentes
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.blue,
                        ),
                        onPressed: () => _popularCollection(collection),
                        tooltip: AppStrings.tooltipPopularSeed,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        onPressed: () => _limparCollection(collection),
                        tooltip: AppStrings.tooltipLimparTruncate,
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
