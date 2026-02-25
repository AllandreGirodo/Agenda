import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controller/firestore_service.dart';
import '../controller/log_model.dart';
import '../controller/changelog_model.dart';

class AdminLogsView extends StatefulWidget {
  const AdminLogsView({super.key});

  @override
  State<AdminLogsView> createState() => _AdminLogsViewState();
}

class _AdminLogsViewState extends State<AdminLogsView> {
  final FirestoreService _firestoreService = FirestoreService();
  final List<String> _filtros = ['todos', 'cancelamento', 'aprovacao', 'sistema', 'espera'];
  String _filtroSelecionado = 'todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs do Sistema'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: _filtros.map((filtro) {
                final isSelected = _filtroSelecionado == filtro;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(filtro.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _filtroSelecionado = filtro);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<LogModel>>(
              stream: _firestoreService.getLogs(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var logs = snapshot.data!;
                
                if (_filtroSelecionado != 'todos') {
                  logs = logs.where((l) => l.tipo == _filtroSelecionado).toList();
                }

                if (logs.isEmpty) return const Center(child: Text('Nenhum log encontrado.'));

                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: Icon(_getIconForType(log.tipo), size: 20),
                        title: Text(log.mensagem, style: const TextStyle(fontSize: 14)),
                        subtitle: Text('${DateFormat('dd/MM/yyyy HH:mm:ss').format(log.dataHora)}\nUsuário: ${log.usuarioId ?? "Sistema"}'),
                        isThreeLine: true,
                        dense: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String tipo) {
    if (tipo == 'cancelamento') return Icons.cancel_outlined;
    if (tipo == 'aprovacao') return Icons.check_circle_outline;
    if (tipo == 'espera') return Icons.hourglass_empty;
    return Icons.info_outline;
  }
}