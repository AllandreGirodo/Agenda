import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../controller/firestore_service.dart';
import '../controller/agendamento_model.dart';
import '../controller/scheduling_service.dart';
import 'login_view.dart';
import 'perfil_view.dart';
import '../controller/config_model.dart';
import '../usuario_model.dart';
import '../app_localizations.dart';
import '../widgets/language_selector.dart';

class AgendamentoView extends StatefulWidget {
  const AgendamentoView({super.key});

  @override
  State<AgendamentoView> createState() => _AgendamentoViewState();
}

class _AgendamentoViewState extends State<AgendamentoView> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _dataSelecionada = DateTime.now();
  String? _horarioSelecionado;
  ConfigModel? _config;
  bool _mostrarTodos = false;
  late final Stream<DateTime> _clockStream;

  @override
  void initState() {
    super.initState();
    _carregarConfig();
    _clockStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  }

  Future<void> _carregarConfig() async {
    _config = await _firestoreService.getConfiguracao();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<UsuarioModel?>(
      stream: currentUser != null ? _firestoreService.getUsuarioStream(currentUser.uid) : Stream.value(null),
      builder: (context, userSnapshot) {
        final usuario = userSnapshot.data;
        final temPermissao = usuario?.visualizaTodos ?? false;

        return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appointmentsTitle),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          const LanguageSelector(),
          if (temPermissao)
            IconButton(
              icon: Icon(_mostrarTodos ? Icons.groups : Icons.person),
              tooltip: _mostrarTodos ? AppLocalizations.of(context)!.viewingAll : AppLocalizations.of(context)!.viewingMine,
              onPressed: () {
                setState(() {
                  _mostrarTodos = !_mostrarTodos;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: AppLocalizations.of(context)!.myProfileTooltip,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PerfilView()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: AppLocalizations.of(context)!.logoutTooltip,
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginView()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Agendamento>>(
        stream: _firestoreService.getAgendamentos(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var agendamentos = snapshot.data ?? [];

          // Filtro: Se não estiver mostrando todos (ou não tiver permissão), filtra pelos do usuário
          if (!(_mostrarTodos && temPermissao) && currentUser != null) {
             agendamentos = agendamentos.where((a) => a.clienteId == currentUser.uid).toList();
          }

          if (agendamentos.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noAppointmentsFound));
          }

          return ListView.builder(
            itemCount: agendamentos.length,
            itemBuilder: (context, index) {
              final agendamento = agendamentos[index];
              final isMyAppointment = currentUser != null && agendamento.clienteId == currentUser.uid;

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
              
              // Define se pode mostrar botão de cancelar (apenas se não estiver recusado ou já cancelado)
              final bool podeCancelar = agendamento.status != 'recusado' && 
                                        agendamento.status != 'cancelado' && 
                                        agendamento.status != 'cancelado_tardio';

              final bool isCancelado = agendamento.status == 'cancelado' || agendamento.status == 'cancelado_tardio';
              final String motivoTexto = isCancelado && agendamento.motivoCancelamento != null 
                  ? '\nMotivo: ${agendamento.motivoCancelamento}' : '';

              // Lógica da Lista de Espera
              final bool isOccupied = agendamento.status == 'aprovado';
              final bool isInWaitList = currentUser != null && agendamento.listaEspera.contains(currentUser.uid);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.teal),
                  title: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(agendamento.dataHora),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Tipo: ${agendamento.tipo}\nStatus: ${agendamento.status}$motivoTexto'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botão de Lista de Espera (Apenas para agendamentos ocupados de terceiros)
                      if (!isMyAppointment && isOccupied && currentUser != null)
                        IconButton(
                          icon: Icon(
                            isInWaitList ? Icons.notifications_active : Icons.notifications_none,
                            color: isInWaitList ? Colors.amber : Colors.grey,
                          ),
                          tooltip: isInWaitList ? 'Sair da Lista de Espera' : 'Avise-me se vagar',
                          onPressed: () => _toggleListaEspera(agendamento, currentUser.uid, !isInWaitList),
                        ),
                      
                      // Botão de Cancelar ou Ícone de Status
                      if (isMyAppointment && podeCancelar)
                        IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          onPressed: () => _iniciarCancelamento(agendamento),
                          tooltip: 'Cancelar Agendamento',
                        )
                      else if (!(!isMyAppointment && isOccupied)) // Evita duplicar ícone se tiver botão de espera
                        Icon(statusIcon, color: statusColor),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
          ),
          StreamBuilder<DateTime>(
            stream: _clockStream,
            builder: (context, snapshot) {
              final now = snapshot.data ?? DateTime.now();
              return Container(
                width: double.infinity,
                color: Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  'Registro de Tela: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(now)}\nID: ${currentUser?.uid ?? "N/A"}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNovoAgendamento,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
      }
    );
  }

  void _mostrarDialogoNovoAgendamento() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.newAppointmentTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text("${AppLocalizations.of(context)!.dateLabel}: ${DateFormat('dd/MM/yyyy').format(_dataSelecionada)}"),
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
                    hint: Text(AppLocalizations.of(context)!.selectTimeHint),
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
                  child: Text(AppLocalizations.of(context)!.cancelButton),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_horarioSelecionado != null) {
                      await _salvarAgendamento();
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.scheduleButton),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.appointmentSuccess)),
      );
    }
  }

  Future<void> _toggleListaEspera(Agendamento agendamento, String uid, bool entrar) async {
    await _firestoreService.toggleListaEspera(agendamento.id!, uid, entrar);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(entrar 
          ? 'Você será notificado se este horário vagar.' 
          : 'Você saiu da lista de espera.')),
      );
    }
  }

  // Lógica de Cancelamento
  Future<void> _iniciarCancelamento(Agendamento agendamento) async {
    if (_config == null) await _carregarConfig();
    
    final agora = DateTime.now();
    final dataAgendamento = agendamento.dataHora;

    if (dataAgendamento.isBefore(agora)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não é possível cancelar agendamentos passados.')),
        );
      }
      return;
    }

    // Cálculo de horas válidas (descontando sono)
    int minutosValidos = 0;
    DateTime cursor = agora;
    
    // Itera minuto a minuto (simples e eficaz para intervalos curtos de dias)
    while (cursor.isBefore(dataAgendamento)) {
      final hora = cursor.hour;
      bool dormindo = false;

      if (_config!.inicioSono < _config!.fimSono) {
        // Ex: 22h as 23h (mesmo dia) - raro para sono, mas possível
        dormindo = hora >= _config!.inicioSono && hora < _config!.fimSono;
      } else {
        // Ex: 22h as 06h (cruza meia noite)
        dormindo = hora >= _config!.inicioSono || hora < _config!.fimSono;
      }

      if (!dormindo) {
        minutosValidos++;
      }
      cursor = cursor.add(const Duration(minutes: 1));
    }

    final horasValidas = minutosValidos / 60.0;
    final horasNecessarias = _config!.horasAntecedenciaCancelamento;
    
    bool foraDoPrazo = horasValidas < horasNecessarias;

    if (!mounted) return;

    // Exibir diálogo
    final motivoController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(foraDoPrazo ? 'Cancelamento Tardio' : 'Cancelar Agendamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (foraDoPrazo)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade50,
                  child: Text(
                    'Atenção: Você está cancelando com menos de $horasNecessarias horas úteis de antecedência (considerando o horário de descanso da administradora).\n\nTempo útil restante: ${horasValidas.toStringAsFixed(1)}h.',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 10),
              const Text('Por favor, informe o motivo do cancelamento:'),
              TextField(
                controller: motivoController,
                decoration: const InputDecoration(hintText: 'Ex: Imprevisto de saúde'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Voltar')),
            ElevatedButton(
              onPressed: () async {
                if (motivoController.text.isEmpty) return;
                
                final status = foraDoPrazo ? 'cancelado_tardio' : 'cancelado';
                final motivoFinal = foraDoPrazo ? '[FORA DO PRAZO] ${motivoController.text}' : motivoController.text;

                await _firestoreService.cancelarAgendamento(agendamento.id!, motivoFinal, status);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Confirmar Cancelamento'),
            ),
          ],
        );
      },
    );
  }
}