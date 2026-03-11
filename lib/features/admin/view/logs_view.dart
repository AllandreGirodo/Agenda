import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:agenda/core/services/firestore_service.dart';
import 'package:agenda/core/models/log_model.dart';
import 'package:agenda/core/utils/app_strings.dart';

class AdminLogsView extends StatefulWidget {
  const AdminLogsView({super.key});

  @override
  State<AdminLogsView> createState() => _AdminLogsViewState();
}

class _AdminLogsViewState extends State<AdminLogsView> {
  final FirestoreService _firestoreService = FirestoreService();
  final List<String> _filtros = ['todos', 'cancelamento', 'aprovacao', 'sistema', 'espera', 'seguranca_auth'];
  String _filtroSelecionado = 'todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.logsSistema),
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
                    label: Text(_labelFiltro(filtro)),
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

                if (logs.isEmpty) return Center(child: Text(AppStrings.nenhumLogEncontrado));

                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final ehSegurancaAuth = log.tipo == 'seguranca_auth';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ehSegurancaAuth
                          ? _buildSecurityLogTile(log)
                          : ListTile(
                              leading: Icon(_getIconForType(log.tipo), size: 20),
                              title: Text(log.mensagem, style: const TextStyle(fontSize: 14)),
                              subtitle: Text('${DateFormat('dd/MM/yyyy HH:mm:ss').format(log.dataHora)}\n${AppStrings.usuarioLog(log.usuarioId ?? AppStrings.sistema)}'),
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

  Widget _buildSecurityLogTile(LogModel log) {
    final parsed = _parseSecurityMessage(log.mensagem);
    final email = parsed['email'] ?? AppStrings.naoInformado;
    final action = AppStrings.acaoSegurancaLabel(parsed['action'] ?? AppStrings.naoInformado);
    final attempts = parsed['attempts'] ?? AppStrings.naoInformado;
    final reason = parsed['reason'] ?? AppStrings.naoInformado;
    final retryAtRaw = parsed['retry_at'];

    String retryAtLabel = AppStrings.naoInformado;
    if (retryAtRaw != null && retryAtRaw.isNotEmpty) {
      final parsedDate = DateTime.tryParse(retryAtRaw);
      if (parsedDate != null) {
        retryAtLabel = DateFormat('dd/MM/yyyy HH:mm:ss').format(parsedDate.toLocal());
      } else {
        retryAtLabel = retryAtRaw;
      }
    }

    return ListTile(
      leading: Icon(_getIconForType(log.tipo), size: 20),
      title: Text(AppStrings.segurancaAuth, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          Text('${AppStrings.emailCampo}: $email'),
          Text('${AppStrings.acaoCampo}: $action'),
          Text('${AppStrings.tentativasCampo}: $attempts'),
          Text('${AppStrings.motivoCampo}: $reason'),
          Text('${AppStrings.desbloqueioCampo}: $retryAtLabel'),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd/MM/yyyy HH:mm:ss').format(log.dataHora),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
      isThreeLine: true,
      dense: true,
    );
  }

  String _labelFiltro(String filtro) {
    switch (filtro) {
      case 'todos':
        return AppStrings.filtroTodos;
      case 'cancelamento':
        return AppStrings.filtroCancelamento;
      case 'aprovacao':
        return AppStrings.filtroAprovacao;
      case 'espera':
        return AppStrings.filtroEspera;
      case 'sistema':
        return AppStrings.filtroSistema;
      case 'seguranca_auth':
        return AppStrings.segurancaAuth;
      default:
        return filtro;
    }
  }

  Map<String, String> _parseSecurityMessage(String message) {
    final result = <String, String>{};
    final parts = message.split('|').map((part) => part.trim()).toList();

    for (final part in parts) {
      if (part.contains('limite excedido para')) {
        result['action'] = part.split('limite excedido para').last.trim();
        continue;
      }

      final separatorIndex = part.indexOf('=');
      if (separatorIndex == -1) continue;

      final key = part.substring(0, separatorIndex).trim();
      final value = part.substring(separatorIndex + 1).trim();

      if (key == 'email') result['email'] = value;
      if (key == 'tentativas') result['attempts'] = value;
      if (key == 'motivo') result['reason'] = value;
      if (key == 'retry_at') result['retry_at'] = value;
    }

    return result;
  }

  IconData _getIconForType(String tipo) {
    if (tipo == 'cancelamento') return Icons.cancel_outlined;
    if (tipo == 'aprovacao') return Icons.check_circle_outline;
    if (tipo == 'espera') return Icons.hourglass_empty;
    if (tipo == 'seguranca_auth') return Icons.security;
    return Icons.info_outline;
  }
}