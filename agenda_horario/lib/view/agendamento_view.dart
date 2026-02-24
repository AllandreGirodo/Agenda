import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../controller/firestore_service.dart';
import '../controller/agendamento_model.dart';
import '../controller/scheduling_service.dart';

class AgendamentoView extends StatefulWidget {
  const AgendamentoView({super.key});

  @override
  State<AgendamentoView> createState() => _AgendamentoViewState();
}

class _AgendamentoViewState extends State<AgendamentoView> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _dataSelecionada = DateTime.now();
  String? _horarioSelecionado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamentos'),
        backgroundColor: Colors.teal,
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

          final agendamentos = snapshot.data ?? [];

          if (agendamentos.isEmpty) {
            return const Center(child: Text('Nenhum agendamento encontrado.'));
          }

          return ListView.builder(
            itemCount: agendamentos.length,
            itemBuilder: (context, index) {
              final agendamento = agendamentos[index];

              IconData statusIcon;
              Color statusColor;
              switch (agendamento.status) {
                case 'aprovado':
                  statusIcon = Icons.check_circle;
                  statusColor = Colors.green;
                  break;
                case 'recusado':
                  statusIcon = Icons.cancel;
                  statusColor = Colors.red;
                  break;
                default:
                  statusIcon = Icons.hourglass_empty;
                  statusColor = Colors.orange;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.teal),
                  title: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(agendamento.dataHora),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Cliente ID: ${agendamento.clienteId}\nTipo: ${agendamento.tipo}\nStatus: ${agendamento.status}'),
                  isThreeLine: true,
                  trailing: Icon(statusIcon, color: statusColor),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNovoAgendamento,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _mostrarDialogoNovoAgendamento() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Novo Agendamento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text("Data: ${DateFormat('dd/MM/yyyy').format(_dataSelecionada)}"),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dataSelecionada,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setStateDialog(() {
                          _dataSelecionada = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    hint: const Text("Selecione um horário"),
                    value: _horarioSelecionado,
                    isExpanded: true,
                    items: SchedulingService.getSlotsDisponiveis().map((slot) {
                      return DropdownMenuItem(
                        value: slot,
                        child: Text(slot),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        _horarioSelecionado = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_horarioSelecionado != null) {
                      await _salvarAgendamento();
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Agendar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _salvarAgendamento() async {
    if (_horarioSelecionado == null) return;

    final horasMinutos = _horarioSelecionado!.split(':');
    final dataHoraFinal = DateTime(
      _dataSelecionada.year,
      _dataSelecionada.month,
      _dataSelecionada.day,
      int.parse(horasMinutos[0]),
      int.parse(horasMinutos[1]),
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não autenticado.')),
      );
      return;
    }

    final novoAgendamento = Agendamento(
      clienteId: user.uid,
      dataHora: dataHoraFinal,
      tipo: 'Fixa', // Tipo padrão para o MVP
    );

    await _firestoreService.salvarAgendamento(novoAgendamento);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento realizado com sucesso!')),
      );
    }
  }
}