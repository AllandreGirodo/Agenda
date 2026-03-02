import 'package:flutter/material.dart';
import 'dart:ui'; // Necessário para ImageFilter (Glassmorphism)
import 'dart:math'; // Para Random
import 'package:flutter/services.dart'; // Import necessário para HapticFeedback
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:agenda/controller/firestore_service.dart';
import 'package:agenda/controller/agendamento_model.dart';
import 'package:agenda/controller/scheduling_service.dart';
import 'package:agenda/view/login_view.dart';
import 'package:agenda/view/perfil_view.dart';
import 'package:agenda/controller/config_model.dart';
import 'package:agenda/usuario_model.dart';
import 'package:agenda/app_localizations.dart';
import 'package:agenda/widgets/language_selector.dart';
import 'package:agenda/controller/cupom_model.dart';

class AgendamentoView extends StatefulWidget {
  const AgendamentoView({super.key});

  @override
  State<AgendamentoView> createState() => _AgendamentoViewState();
}

class _AgendamentoViewState extends State<AgendamentoView> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _dataSelecionada = DateTime.now();
  String? _horarioSelecionado;
  String? _tipoSelecionado;
  
  // Variáveis para o Cupom no Dialog
  CupomModel? _cupomAplicado;
  double _valorFinalSessao = 0.0;
  
  ConfigModel? _config;
  bool _mostrarTodos = false;
  late final Stream<DateTime> _clockStream;
  
  // Dicas do Dia
  String? _dicaDoDia;
  final List<String> _dicas = [
    "Beba bastante água após a massagem para ajudar a eliminar toxinas.",
    "Evite refeições pesadas pelo menos 1 hora antes da sua sessão.",
    "Chegue 5 minutos antes para relaxar e aproveitar melhor seu tempo.",
    "Alongamentos leves diários ajudam a prolongar os efeitos da massagem.",
    "Informe sempre se houver alguma dor nova ou desconforto recente."
  ];
  
  // Filtros
  DateTime? _filtroData;
  final TextEditingController _searchController = TextEditingController();
  String _filtroTexto = '';

  @override
  void initState() {
    super.initState();
    _carregarConfig();
    _clockStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
    _dicaDoDia = _dicas[Random().nextInt(_dicas.length)];
  }

  Future<void> _carregarConfig() async {
    _config = await _firestoreService.getConfiguracao();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          // Dica do Dia
          if (_dicaDoDia != null)
            Container(
              width: double.infinity,
              color: Colors.teal.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_dicaDoDia!, style: TextStyle(color: Colors.teal.shade900, fontSize: 13, fontStyle: FontStyle.italic)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                    onPressed: () => setState(() => _dicaDoDia = null),
                  )
                ],
              ),
            ),
            
          // Barra de Filtros
          _buildFilters(context),

          Expanded(
            child: StreamBuilder<List<Agendamento>>(
        stream: _firestoreService.getAgendamentos(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Efeito Shimmer enquanto carrega
            return ListView.builder(
              itemCount: 5,
              padding: const EdgeInsets.only(top: 8),
              itemBuilder: (context, index) => const _ShimmerLoadingCard(),
            );
          }

          var agendamentos = snapshot.data ?? [];

          // Filtro: Se não estiver mostrando todos (ou não tiver permissão), filtra pelos do usuário
          if (!(_mostrarTodos && temPermissao) && currentUser != null) {
             agendamentos = agendamentos.where((a) => a.clienteId == currentUser.uid).toList();
          }

          // Filtro por Data
          if (_filtroData != null) {
            agendamentos = agendamentos.where((a) => 
              a.dataHora.year == _filtroData!.year &&
              a.dataHora.month == _filtroData!.month &&
              a.dataHora.day == _filtroData!.day
            ).toList();
          }

          // Filtro por Texto (Tipo)
          if (_filtroTexto.isNotEmpty) {
            agendamentos = agendamentos.where((a) => 
              a.tipo.toLowerCase().contains(_filtroTexto.toLowerCase())
            ).toList();
          }

          if (agendamentos.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noAppointmentsFound, style: const TextStyle(color: Colors.grey)));
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Simula um refresh (Firestore é realtime, mas recarregamos configs)
              await Future.delayed(const Duration(seconds: 1));
              await _carregarConfig();
              if (mounted) setState(() {});
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(), // Garante que o pull-to-refresh funcione mesmo com lista pequena
              itemCount: agendamentos.length,
              itemBuilder: (context, index) {
                final agendamento = agendamentos[index];
                
                return _AgendamentoCard(
                  agendamento: agendamento,
                  currentUser: currentUser, // Passamos o User do Firebase diretamente ou adaptamos
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AgendamentoDetalhesView(agendamento: agendamento))),
                  onToggleWaitList: (entrar) => _toggleListaEspera(agendamento, currentUser!.uid, entrar),
                  onCancel: () => _iniciarCancelamento(agendamento),
                  onRate: () => _mostrarDialogoAvaliacao(agendamento),
                );
              },
            ),
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
        onPressed: () {
          HapticFeedback.selectionClick(); // Vibração leve ao clicar
          _mostrarDialogoNovoAgendamento();
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
      }
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Theme.of(context).cardColor.withValues(alpha: 0.5),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por tipo...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.7),
              ),
              onChanged: (val) => setState(() => _filtroTexto = val),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () async {
              if (_filtroData != null) {
                setState(() => _filtroData = null);
              } else {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _filtroData = picked);
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _filtroData != null ? Colors.teal : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _filtroData != null ? Icons.event_available : Icons.calendar_today,
                color: _filtroData != null ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoNovoAgendamento() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Resetar variáveis do cupom ao abrir o diálogo
    _cupomAplicado = null;
    final TextEditingController cupomController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.newAppointmentTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  // Seletor de Tipo de Massagem com Favoritos
                  FutureBuilder<List<dynamic>>(
                    future: Future.wait([
                      _firestoreService.getTiposMassagem(),
                      _firestoreService.getCliente(user.uid),
                    ]),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const LinearProgressIndicator();
                      final tipos = snapshot.data![0] as List<String>;
                      final cliente = snapshot.data![1] as dynamic; 
                      final favoritos = cliente != null ? (cliente.favoritos as List<String>) : <String>[];

                      // Verifica se o tipo selecionado é favorito
                      final isFavorite = _tipoSelecionado != null && favoritos.contains(_tipoSelecionado);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Chips de Favoritos para acesso rápido
                          if (favoritos.isNotEmpty) ...[
                            const Text('Favoritos:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Wrap(
                              spacing: 8,
                              children: favoritos.map((fav) => ActionChip(
                                label: Text(fav),
                                avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                                onPressed: () => setStateDialog(() => _tipoSelecionado = fav),
                                backgroundColor: _tipoSelecionado == fav ? Colors.teal.shade100 : null,
                              )).toList(),
                            ),
                            const SizedBox(height: 8),
                          ],
                          
                          // Dropdown com todos os tipos
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButton<String>(
                                  hint: const Text('Selecione o Tipo'),
                                  value: _tipoSelecionado,
                                  isExpanded: true,
                                  items: tipos.map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo))).toList(),
                                  onChanged: (val) => setStateDialog(() => _tipoSelecionado = val),
                                ),
                              ),
                              if (_tipoSelecionado != null)
                                IconButton(
                                  icon: Icon(isFavorite ? Icons.star : Icons.star_border, color: isFavorite ? Colors.amber : Colors.grey),
                                  tooltip: isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
                                  onPressed: () async {
                                    await _firestoreService.toggleFavorito(user.uid, _tipoSelecionado!);
                                    setStateDialog(() {}); // Atualiza UI
                                  },
                                ),
                            ],
                          ),
                        ],
                      );
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
                  const SizedBox(height: 16),
                  const Divider(),
                  // Área de Cupom
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cupomController,
                          decoration: const InputDecoration(
                            labelText: 'Cupom de Desconto',
                            isDense: true,
                            prefixIcon: Icon(Icons.local_offer, size: 18),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (cupomController.text.isEmpty) return;
                          final messenger = ScaffoldMessenger.of(context);
                          final cupom = await _firestoreService.validarCupom(cupomController.text);
                          if (!context.mounted) return;
                          setStateDialog(() {
                            if (cupom != null) {
                              _cupomAplicado = cupom;
                              messenger.showSnackBar(const SnackBar(content: Text('Cupom aplicado!')));
                            } else {
                              _cupomAplicado = null;
                              messenger.showSnackBar(const SnackBar(content: Text('Cupom inválido ou expirado.')));
                            }
                          });
                        },
                        child: const Text('Aplicar'),
                      ),
                    ],
                  ),
                  if (_cupomAplicado != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Desconto: ${_cupomAplicado!.tipo == 'porcentagem' ? '${_cupomAplicado!.valor.toStringAsFixed(0)}%' : 'R\$ ${_cupomAplicado!.valor.toStringAsFixed(2)}'}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 10),
                  // Exibição do Preço
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildPriceDisplay(),
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
                    if (_horarioSelecionado != null && _tipoSelecionado != null) {
                      final nav = Navigator.of(context);
                      await _salvarAgendamento();
                      if (context.mounted) nav.pop();
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

  Widget _buildPriceDisplay() {
    double precoBase = _config?.precoSessao ?? 0.0;
    double desconto = 0.0;

    if (_cupomAplicado != null) {
      if (_cupomAplicado!.tipo == 'porcentagem') {
        desconto = precoBase * (_cupomAplicado!.valor / 100);
      } else {
        desconto = _cupomAplicado!.valor;
      }
    }
    _valorFinalSessao = max(0, precoBase - desconto);

    return Text(
      'Total: R\$ ${_valorFinalSessao.toStringAsFixed(2)}',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
    );
  }

  void _mostrarDialogoAvaliacao(Agendamento agendamento) {
    int notaSelecionada = 5;
    final comentarioController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Avaliar Sessão'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Como foi sua experiência?'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < notaSelecionada ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 30,
                        ),
                        onPressed: () => setStateDialog(() => notaSelecionada = index + 1),
                      );
                    }),
                  ),
                  TextField(
                    controller: comentarioController,
                    decoration: const InputDecoration(hintText: 'Deixe um comentário (opcional)'),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    await _firestoreService.avaliarAgendamento(agendamento.id!, notaSelecionada, comentarioController.text);
                    if (mounted) {
                      nav.pop();
                      messenger.showSnackBar(const SnackBar(content: Text('Obrigado pela avaliação!')));
                    }
                  },
                  child: const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _salvarAgendamento() async {
    if (_horarioSelecionado == null || _tipoSelecionado == null) return;

    final horasMinutos = _horarioSelecionado!.split(':');
    final dataHoraFinal = DateTime(
      _dataSelecionada.year,
      _dataSelecionada.month,
      _dataSelecionada.day,
      int.parse(horasMinutos[0]),
      int.parse(horasMinutos[1]),
    );

    final user = FirebaseAuth.instance.currentUser;
    final messenger = ScaffoldMessenger.of(context);
    final appointmentSuccessMessage = AppLocalizations.of(context)!.appointmentSuccess;

    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não autenticado.')),
      );
      return;
    }

    // Recalcula para garantir (caso o UI não tenha atualizado)
    _buildPriceDisplay(); 

    final novoAgendamento = Agendamento(
      clienteId: user.uid,
      dataHora: dataHoraFinal,
      tipo: _tipoSelecionado!,
      cupomAplicado: _cupomAplicado?.codigo,
      valorOriginal: _config?.precoSessao,
      valorFinal: _valorFinalSessao,
    );

    await _firestoreService.salvarAgendamento(novoAgendamento);
    
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(appointmentSuccessMessage)),
      );
    }
  }

  Future<void> _toggleListaEspera(Agendamento agendamento, String uid, bool entrar) async {
    final messenger = ScaffoldMessenger.of(context);
    await _firestoreService.toggleListaEspera(agendamento.id!, uid, entrar);
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(entrar 
          ? 'Você será notificado se este horário vagar.' 
          : 'Você saiu da lista de espera.')),
      );
    }
  }

  // Lógica de Cancelamento
  Future<void> _iniciarCancelamento(Agendamento agendamento) async {
    final messenger = ScaffoldMessenger.of(context);
    if (_config == null) await _carregarConfig();
    
    final agora = DateTime.now();
    final dataAgendamento = agendamento.dataHora;

    if (dataAgendamento.isBefore(agora)) {
      if (mounted) {
        messenger.showSnackBar(
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
                final nav = Navigator.of(context);
                if (motivoController.text.isEmpty) return;
                
                final status = foraDoPrazo ? 'cancelado_tardio' : 'cancelado';
                final motivoFinal = foraDoPrazo ? '[FORA DO PRAZO] ${motivoController.text}' : motivoController.text;

                await _firestoreService.cancelarAgendamento(agendamento.id!, motivoFinal, status);
                if (context.mounted) nav.pop();
              },
              child: const Text('Confirmar Cancelamento'),
            ),
          ],
        );
      },
    );
  }
}

class AgendamentoDetalhesView extends StatelessWidget {
  final Agendamento agendamento;

  const AgendamentoDetalhesView({super.key, required this.agendamento});

  @override
  Widget build(BuildContext context) {
    // Formatação de data e hora
    final dateStr = DateFormat('dd/MM/yyyy').format(agendamento.dataHora);
    final timeStr = DateFormat('HH:mm').format(agendamento.dataHora);

    return Scaffold(
      // AppBar transparente para manter o fundo visível
      appBar: AppBar(
        title: const Text('Detalhes do Agendamento'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Hero(
            tag: 'agendamento_${agendamento.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5)],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.spa, size: 60, color: Colors.teal),
                        const SizedBox(height: 20),
                        Text(agendamento.tipo, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 10),
                        Text('Data: $dateStr', style: const TextStyle(fontSize: 18)),
                        Text('Horário: $timeStr', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                        if (agendamento.valorFinal != null)
                          Text('Valor: R\$ ${agendamento.valorFinal!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.green)),
                        if (agendamento.cupomAplicado != null)
                          Text('Cupom: ${agendamento.cupomAplicado}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(agendamento.status).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _getStatusColor(agendamento.status)),
                          ),
                          child: Text(
                            agendamento.status.toUpperCase(),
                            style: TextStyle(color: _getStatusColor(agendamento.status), fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (agendamento.motivoCancelamento != null) ...[
                          const SizedBox(height: 20),
                          const Text('Motivo do Cancelamento:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          Text(agendamento.motivoCancelamento!, textAlign: TextAlign.center),
                        ],
                        const SizedBox(height: 30),
                        if (agendamento.listaEspera.isNotEmpty)
                          Text('${agendamento.listaEspera.length} pessoas na fila de espera', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        if (agendamento.avaliacao != null) ...[
                          const SizedBox(height: 20),
                          const Divider(),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => Icon(i < agendamento.avaliacao! ? Icons.star : Icons.star_border, color: Colors.amber))),
                          if (agendamento.comentarioAvaliacao != null && agendamento.comentarioAvaliacao!.isNotEmpty)
                            Text('"${agendamento.comentarioAvaliacao}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'aprovado': return Colors.green;
      case 'recusado': return Colors.red;
      case 'cancelado': return Colors.red;
      case 'cancelado_tardio': return Colors.deepOrange;
      default: return Colors.orange;
    }
  }
}

// --- Widget de Card com Animação de Check-in ---
class _AgendamentoCard extends StatefulWidget {
  final Agendamento agendamento;
  final User? currentUser;
  final VoidCallback onTap;
  final Function(bool) onToggleWaitList;
  final VoidCallback onCancel;
  final VoidCallback onRate;

  const _AgendamentoCard({
    required this.agendamento,
    required this.currentUser,
    required this.onTap,
    required this.onToggleWaitList,
    required this.onCancel,
    required this.onRate,
  });

  @override
  State<_AgendamentoCard> createState() => _AgendamentoCardState();
}

class _AgendamentoCardState extends State<_AgendamentoCard> with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)),
    );

    _checkController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _checkController.reverse();
        });
      }
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  void _handleCheckIn() {
    HapticFeedback.mediumImpact();
    _checkController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final agendamento = widget.agendamento;
    final currentUser = widget.currentUser;
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

    final bool podeCancelar = agendamento.status != 'recusado' && 
                              agendamento.status != 'cancelado' && 
                              agendamento.status != 'cancelado_tardio';

    final bool isCancelado = agendamento.status == 'cancelado' || agendamento.status == 'cancelado_tardio';
    final String motivoTexto = isCancelado && agendamento.motivoCancelamento != null 
        ? '\nMotivo: ${agendamento.motivoCancelamento}' : '';

    final bool isOccupied = agendamento.status == 'aprovado';
    final bool isInWaitList = currentUser != null && agendamento.listaEspera.contains(currentUser.uid);

    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Hero(
              tag: 'agendamento_${agendamento.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 0)
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
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
                            // Botão de Check-in (Novo)
                            if (isMyAppointment && agendamento.status == 'aprovado')
                              IconButton(
                                icon: const Icon(Icons.verified_user, color: Colors.blue),
                                tooltip: 'Fazer Check-in',
                                onPressed: _handleCheckIn,
                              ),
                            
                            // Botão de Avaliar (Se aprovado e ainda não avaliado)
                            if (isMyAppointment && agendamento.status == 'aprovado' && agendamento.avaliacao == null)
                              IconButton(
                                icon: const Icon(Icons.star_rate, color: Colors.amber),
                                tooltip: 'Avaliar Atendimento',
                                onPressed: widget.onRate,
                              ),

                            if (!isMyAppointment && isOccupied && currentUser != null)
                              IconButton(
                                icon: Icon(isInWaitList ? Icons.notifications_active : Icons.notifications_none, color: isInWaitList ? Colors.amber : Colors.grey),
                                onPressed: () => widget.onToggleWaitList(!isInWaitList),
                              ),
                            if (isMyAppointment && podeCancelar)
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                onPressed: widget.onCancel,
                              )
                            else if (!(!isMyAppointment && isOccupied) && !(isMyAppointment && agendamento.status == 'aprovado'))
                              Icon(statusIcon, color: statusColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Overlay de Animação de Check-in
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _checkController,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 15)],
                    ),
                    child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- Widget de Shimmer Loading ---
class _ShimmerLoadingCard extends StatefulWidget {
  const _ShimmerLoadingCard();

  @override
  State<_ShimmerLoadingCard> createState() => _ShimmerLoadingCardState();
}

class _ShimmerLoadingCardState extends State<_ShimmerLoadingCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.4), Colors.white.withValues(alpha: 0.1)],
                stops: const [0.1, 0.5, 0.9],
                begin: Alignment(-1.0 + (_controller.value * 2.5), -0.3),
                end: Alignment(1.0 + (_controller.value * 2.5), 0.3),
                tileMode: TileMode.clamp,
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
          );
        },
      ),
    );
  }
}