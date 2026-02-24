import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controller/firestore_service.dart';
import '../controller/agendamento_model.dart';

class AdminAgendamentosView extends StatefulWidget {
  const AdminAgendamentosView({super.key});

  @override
  State<AdminAgendamentosView> createState() => _AdminAgendamentosViewState();
}

class _AdminAgendamentosViewState extends State<AdminAgendamentosView> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administração de Agenda'),
        backgroundColor: Colors.orange, // Cor diferente para diferenciar do app cliente
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Agendamento>>(
        stream: _firestoreService.getAgendamentos(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filtrar apenas os pendentes
          final agendamentos = snapshot.data
                  ?.where((a) => a.status == 'pendente')
                  .toList() ??
              [];

          if (agendamentos.isEmpty) {
            return const Center(child: Text('Nenhum agendamento pendente.'));
          }

          return ListView.builder(
            itemCount: agendamentos.length,
            itemBuilder: (context, index) {
              final agendamento = agendamentos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(agendamento.dataHora),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Cliente: ${agendamento.clienteId}\nTipo: ${agendamento.tipo}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _atualizarStatus(agendamento, 'aprovado'),
                        tooltip: 'Aprovar',
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _atualizarStatus(agendamento, 'recusado'),
                        tooltip: 'Recusar',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _atualizarStatus(Agendamento agendamento, String novoStatus) async {
    if (agendamento.id == null) return;
    
    await _firestoreService.atualizarStatusAgendamento(agendamento.id!, novoStatus);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agendamento $novoStatus com sucesso!')),
      );
    }
  }
}