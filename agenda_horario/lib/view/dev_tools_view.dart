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

class DevToolsView extends StatefulWidget {
  const DevToolsView({super.key});

  @override
  State<DevToolsView> createState() => _DevToolsViewState();
}

class _DevToolsViewState extends State<DevToolsView> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _senhaBanco = "admin123"; // Senha simulada para o TCC
  bool _autenticado = false;
  final TextEditingController _senhaController = TextEditingController();

  // Lista de Collections do sistema
  final List<String> _collections = [
    'usuarios',
    'clientes',
    'agendamentos',
    'estoque',
    'configuracoes',
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
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sem script de seed para $collection')),
        );
        return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tabela $collection populada (Merge/Ignore se existe).')),
    );
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

      String conteudo = '';
      String extensao = '';

      // 2. Serializa
      if (formato == 'json') {
        const encoder = JsonEncoder.withIndent('  ');
        conteudo = encoder.convert(data);
        extensao = 'json';
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
      await file.writeAsString(conteudo);

      // 4. Compartilha (Share Sheet do OS)
      await Share.shareXFiles([XFile(file.path)], text: 'Exportação da tabela $collection');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao exportar: $e')));
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
                      onSelected: (format) => _exportarCollection(collection, format),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'json',
                          child: Row(children: [Icon(Icons.code, size: 18), SizedBox(width: 8), Text('JSON')]),
                        ),
                        const PopupMenuItem(
                          value: 'csv',
                          child: Row(children: [Icon(Icons.table_view, size: 18), SizedBox(width: 8), Text('CSV')]),
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