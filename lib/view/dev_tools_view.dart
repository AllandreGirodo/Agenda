import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controller/firestore_service.dart';
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
import 'dart:typed_data';
import 'package:intl/intl.dart';
import '../controller/log_model.dart';

class DevToolsView extends StatefulWidget {
  const DevToolsView({super.key});

  @override
  State<DevToolsView> createState() => _DevToolsViewState();
}

class _DevToolsViewState extends State<DevToolsView> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _senhaBanco = dotenv.env['DB_ADMIN_PASSWORD'] ?? "admin123"; // Senha simulada para o TCC
  bool _autenticado = false;
  final TextEditingController _senhaController = TextEditingController();

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
    'changelogs'
  ];

  @override
  void initState() {
    super.initState();
    // Força o pedido de senha ao abrir
    WidgetsBinding.instance.addPostFrameCallback((_) => _pedirSenha());
  }

  Future<void> _pedirSenha() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Acesso ao Banco de Dados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Esta área permite manipulação direta dos dados (SQL-like).'),
            const SizedBox(height: 10),
            TextField(
              controller: _senhaController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha do Banco (DB Admin)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fecha dialog
              Navigator.pop(context); // Fecha tela (volta pro admin)
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_senhaController.text == _senhaBanco) {
                setState(() => _autenticado = true);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Senha incorreta!')),
                );
              }
            },
            child: const Text('Acessar'),
          ),
        ],
      ),
    );
  }

  Future<int> _contarDocumentos(String collection) async {
    final snapshot = await FirebaseFirestore.instance.collection(collection).count().get();
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
          SnackBar(content: Text('Sem script de seed para $collection')),
        );
        return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tabela $collection populada (Merge/Ignore se existe).')),
    );
    if (!mounted) return;
    setState(() {}); // Atualiza contadores
  }

  Future<void> _limparCollection(String collection) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('TRUNCATE TABLE $collection?'),
        content: Text('Tem certeza que deseja apagar TODOS os dados de $collection? Esta ação é irreversível.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('APAGAR TUDO'),
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
          SnackBar(content: Text('Collection $collection limpa com sucesso.')),
        );
      }
    }
  }

  // --- Exportação (JSON / CSV) ---
  Future<void> _exportarCollection(String collection, String formato) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gerando arquivo...')));
      
      // 1. Busca dados
      final data = await _firestoreService.getFullCollection(collection);
      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coleção vazia.')));
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel disponível apenas para Agendamentos.')));
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
        
        conteudo = const ListToCsvConverter().convert(rows);
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
      await Share.shareXFiles([XFile(file.path)], text: 'Exportação da tabela $collection');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao exportar: $e')));
    }
  }

  // --- Exportação Web (JSONBin.io) ---
  Future<void> _exportarParaWeb(String collection) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enviando para JSONBin...')));

      if (!mounted) return;
      // 1. Busca dados
      final data = await _firestoreService.getFullCollection(collection);
      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coleção vazia.')));
        return;
      }

      // 2. Prepara JSON e Headers
      final jsonBody = jsonEncode(data);
      final apiKey = dotenv.env['X_ACCESS_API_KEY'] ?? dotenv.env['X_MASTER_API_KEY'];
      
      if (apiKey == null) throw Exception('API Key do JSONBin não configurada no .env');

      // 3. Envia Request (POST)
      final response = await http.post(
        Uri.parse('https://api.jsonbin.io/v3/b'),
        headers: {
          'Content-Type': 'application/json',
          'X-Access-Key': apiKey,
          'X-Bin-Private': 'false', // Define como público para facilitar leitura (cuidado com dados reais)
          'X-Bin-Name': '${collection}_export_${DateTime.now().millisecondsSinceEpoch}',
        },
        body: jsonBody,
      );

      // 4. Processa Resposta
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final binId = responseData['metadata']['id'];
        final url = 'https://api.jsonbin.io/v3/b/$binId';

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Exportação Concluída ☁️'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dados salvos na nuvem com sucesso!'),
                  const SizedBox(height: 10),
                  SelectableText('Bin ID: $binId', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text('URL API:'),
                  SelectableText(url, style: const TextStyle(color: Colors.blue, fontSize: 12)),
                ],
              ),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar URL'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL copiada!')));
                  },
                ),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
              ],
            ),
          );
        }
      } else {
        throw Exception('Erro API (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao exportar para web: $e')));
      }
    }
  }

  // --- Importação (JSON) ---
  Future<void> _importarCollection(String collection) async {
    try {
      // 1. Selecionar Arquivo
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lendo arquivo...')));

        // 2. Ler e Parsear JSON
        String conteudo = await file.readAsString();
        List<dynamic> jsonList = jsonDecode(conteudo);
        
        // Converter para List<Map<String, dynamic>>
        List<Map<String, dynamic>> dados = jsonList.map((e) => Map<String, dynamic>.from(e)).toList();

        // 3. Enviar para Firestore
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Importando ${dados.length} registros...')));
        await _firestoreService.importarColecao(collection, dados);

        if (!mounted) return;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Importação concluída com sucesso!')),
          );
          setState(() {}); // Atualiza contadores
        }
      } else {
        // Usuário cancelou
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao importar: $e')));
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
                    decoration: const InputDecoration(
                      hintText: 'Buscar por ID, Nome ou Email...',
                      hintStyle: TextStyle(color: Colors.white70),
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
                  stream: FirebaseFirestore.instance.collection(collection).limit(100).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    
                    var docs = snapshot.data!.docs;

                    // Filtro Local
                    if (filtroBusca.isNotEmpty) {
                      docs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final id = doc.id.toLowerCase();
                        final nome = (data['nome'] ?? '').toString().toLowerCase();
                        final email = (data['email'] ?? '').toString().toLowerCase();
                        return id.contains(filtroBusca) || nome.contains(filtroBusca) || email.contains(filtroBusca);
                      }).toList();
                    }

                    if (docs.isEmpty) return const Center(child: Text('Nenhum documento encontrado.'));

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: docs.length,
                      separatorBuilder: (c, i) => const Divider(),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        
                        // Tenta achar um campo "nome" ou usa o ID para o título
                        final titulo = data['nome'] ?? data['email'] ?? doc.id;

                        return ListTile(
                          title: Text(titulo.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('ID: ${doc.id}'),
                          trailing: const Icon(Icons.data_object, color: Colors.teal),
                          onTap: () => _mostrarDetalhesJson(doc.id, data),
                        );
                      },
                    );
                  },
                ),
              );
            }
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
        title: Text('Doc: $id'),
        content: SingleChildScrollView(
          child: SelectableText(
            jsonString,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
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
                        const Text('System Logs (Real-time)', style: TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            // Filtro
                            DropdownButton<String>(
                              dropdownColor: Colors.grey[900],
                              value: filtroSelecionado,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              underline: Container(), // Remove a linha padrão
                              icon: const Icon(Icons.filter_list, color: Colors.greenAccent, size: 16),
                              items: const [
                                DropdownMenuItem(value: 'todos', child: Text('Todos')),
                                DropdownMenuItem(value: 'erro', child: Text('Erros')),
                                DropdownMenuItem(value: 'aviso', child: Text('Avisos')),
                                DropdownMenuItem(value: 'info', child: Text('Info')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setStateModal(() => filtroSelecionado = value);
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.terminal, color: Colors.greenAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<LogModel>>(
                  stream: _firestoreService.getLogs(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));

                    var logs = snapshot.data!;
                    // Aplica o filtro localmente
                    if (filtroSelecionado != 'todos') {
                      logs = logs.where((l) => l.tipo == filtroSelecionado).toList();
                    }

                    if (logs.isEmpty) return const Center(child: Text('Sem logs registrados.', style: TextStyle(color: Colors.white54)));

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: logs.length,
                      separatorBuilder: (c, i) => const Divider(color: Colors.white12, height: 1),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        Color color = Colors.white;
                        if (log.tipo == 'erro' || log.tipo == 'cancelamento') {
                          color = Colors.redAccent;
                        } else if (log.tipo == 'aviso') color = Colors.orangeAccent;
                        
                        return ListTile(
                          dense: true,
                          leading: Text(DateFormat('HH:mm:ss').format(log.dataHora), style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace')),
                          title: Text('[${log.tipo.toUpperCase()}]', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace')),
                          subtitle: Text(log.mensagem, style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12)),
                        );
                      },
                    );
                  },
                ),
                  ),
                ],
              );
            }
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_autenticado) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('DevTools - DB Manager'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.greenAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.terminal),
            tooltip: 'Console de Logs',
            onPressed: _abrirConsoleLogs,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          )
        ],
      ),
      body: ListView.separated(
        itemCount: _collections.length,
        separatorBuilder: (c, i) => const Divider(),
        itemBuilder: (context, index) {
          final collection = _collections[index];
          return FutureBuilder<int>(
            future: _contarDocumentos(collection),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return ListTile(
                leading: const Icon(Icons.table_chart),
                title: Text(collection, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Registros: $count'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botão Visualizar JSON
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.purple),
                      tooltip: 'Visualizar Dados (JSON)',
                      onPressed: () => _abrirVisualizadorJson(collection),
                    ),
                    // Menu Exportar
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.download, color: Colors.orange),
                      tooltip: 'Exportar',
                      onSelected: (format) {
                        if (format == 'web') {
                          _exportarParaWeb(collection);
                        } else {
                          _exportarCollection(collection, format);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'json',
                          child: Row(children: [Icon(Icons.code, size: 18), SizedBox(width: 8), Text('JSON')]),
                        ),
                        const PopupMenuItem(
                          value: 'csv',
                          child: Row(children: [Icon(Icons.table_view, size: 18), SizedBox(width: 8), Text('CSV')]),
                        ),
                        const PopupMenuItem(
                          value: 'excel',
                          child: Row(children: [Icon(Icons.grid_on, size: 18), SizedBox(width: 8), Text('Excel (XLSX)')]),
                        ),
                        const PopupMenuItem(
                          value: 'web',
                          child: Row(children: [Icon(Icons.cloud_upload, size: 18), SizedBox(width: 8), Text('Web (JSONBin)')]),
                        ),
                      ],
                    ),
                    // Botão Importar
                    IconButton(
                      icon: const Icon(Icons.upload_file, color: Colors.green),
                      tooltip: 'Importar JSON (Restore)',
                      onPressed: () => _importarCollection(collection),
                    ),
                    // Botões Existentes
                    IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.blue), onPressed: () => _popularCollection(collection), tooltip: 'Popular (Seed)'),
                    IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => _limparCollection(collection), tooltip: 'Limpar (Truncate)'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}