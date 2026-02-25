import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../controller/firestore_service.dart';
import '../controller/agendamento_model.dart';
import '../usuario_model.dart';
import '../controller/cliente_model.dart';
import 'login_view.dart';
import 'admin_config_view.dart';
import 'admin_estoque_view.dart';
import 'admin_relatorios_view.dart';
import 'admin_logs_view.dart';
import 'admin_lgpd_logs_view.dart';
import 'dev_tools_view.dart';

class AdminAgendamentosView extends StatefulWidget {
  const AdminAgendamentosView({super.key});

  @override
  State<AdminAgendamentosView> createState() => _AdminAgendamentosViewState();
}

class _AdminAgendamentosViewState extends State<AdminAgendamentosView> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _dataDashboard = DateTime.now();
  double _precoSessao = 100.00;
  final TextEditingController _searchController = TextEditingController();
  String _filtroNome = '';

  @override
  void initState() {
    super.initState();
    _carregarConfig();
  }

  Future<void> _carregarConfig() async {
    final config = await _firestoreService.getConfiguracao();
    if (mounted) {
      setState(() {
        _precoSessao = config.precoSessao;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Administração'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.analytics),
              tooltip: 'Relatórios',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminRelatoriosView()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: 'Logs',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminLogsView()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.privacy_tip),
              tooltip: 'Auditoria LGPD',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminLgpdLogsView()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.inventory_2),
              tooltip: 'Estoque',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminEstoqueView()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Configurações',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminConfigView()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.developer_mode),
              tooltip: 'Dev Tools (DB)',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DevToolsView()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.exit_to_app),
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
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Dash'),
              Tab(icon: Icon(Icons.calendar_today), text: 'Agenda'),
              Tab(icon: Icon(Icons.people), text: 'Clientes'),
              Tab(icon: Icon(Icons.person_add), text: 'Pendentes'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            _buildDashboardTab(),
            _buildAgendamentosTab(),
            _buildClientesTab(),
            _buildUsuariosTab(),
          ],
        ),
      ),
    );
  }

  // --- DASHBOARD TAB ---
  Widget _buildDashboardTab() {
    return StreamBuilder<List<Agendamento>>(
      stream: _firestoreService.getAgendamentos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final todosAgendamentos = snapshot.data!;
        
        // Filtros de Data
        final diaInicio = DateTime(_dataDashboard.year, _dataDashboard.month, _dataDashboard.day);
        final diaFim = diaInicio.add(const Duration(days: 1));
        
        // Semana (Domingo a Sábado)
        final inicioSemana = diaInicio.subtract(Duration(days: diaInicio.weekday % 7));
        final fimSemana = inicioSemana.add(const Duration(days: 7));

        // Mês
        final inicioMes = DateTime(_dataDashboard.year, _dataDashboard.month, 1);
        final fimMes = DateTime(_dataDashboard.year, _dataDashboard.month + 1, 1);

        // Cálculos
        final agendamentosMes = todosAgendamentos.where((a) => a.dataHora.isAfter(inicioMes) && a.dataHora.isBefore(fimMes)).toList();
        final agendamentosDia = todosAgendamentos.where((a) => a.dataHora.isAfter(diaInicio) && a.dataHora.isBefore(diaFim)).toList();
        
        // Receita Estimada (Aprovados no Mês)
        final aprovadosMes = agendamentosMes.where((a) => a.status == 'aprovado').length;
        final receitaEstimada = aprovadosMes * _precoSessao;

        // Status do Dia
        final pendentesDia = agendamentosDia.where((a) => a.status == 'pendente').length;
        final aprovadosDia = agendamentosDia.where((a) => a.status == 'aprovado').length;
        final canceladosDia = agendamentosDia.where((a) => a.status.contains('cancelado') || a.status == 'recusado').length;

        // Taxas de Cancelamento
        double calcularTaxa(DateTime inicio, DateTime fim) {
          final lista = todosAgendamentos.where((a) => a.dataHora.isAfter(inicio) && a.dataHora.isBefore(fim)).toList();
          if (lista.isEmpty) return 0.0;
          final cancelados = lista.where((a) => a.status.contains('cancelado') || a.status == 'recusado').length;
          return (cancelados / lista.length) * 100;
        }

        final taxaDia = calcularTaxa(diaInicio, diaFim);
        final taxaSemana = calcularTaxa(inicioSemana, fimSemana);
        final taxaMes = calcularTaxa(inicioMes, fimMes);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Navegação de Data
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _dataDashboard = _dataDashboard.subtract(const Duration(days: 1)))),
                  Text(DateFormat('dd/MM/yyyy').format(_dataDashboard), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _dataDashboard = _dataDashboard.add(const Duration(days: 1)))),
                  IconButton(icon: const Icon(Icons.today), onPressed: () => setState(() => _dataDashboard = DateTime.now())),
                ],
              ),
              const SizedBox(height: 20),

              // Cards Principais
              Row(
                children: [
                  Expanded(child: _buildStatCard('Agendamentos (Dia)', '${agendamentosDia.length}', Colors.blue)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatCard('Receita Est. (Mês)', 'R\$ ${receitaEstimada.toStringAsFixed(2)}', Colors.green)),
                ],
              ),
              const SizedBox(height: 20),

              const Text('Status do Dia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildBarraStatus('Pendentes', pendentesDia, Colors.orange),
                  _buildBarraStatus('Aprovados', aprovadosDia, Colors.green),
                  _buildBarraStatus('Cancel/Rec', canceladosDia, Colors.red),
                ],
              ),
              const SizedBox(height: 20),

              const Text('Taxa de Cancelamento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTaxaIndicator('Hoje', taxaDia),
                      _buildTaxaIndicator('Semana', taxaSemana),
                      _buildTaxaIndicator('Mês', taxaMes),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraStatus(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(height: 10, color: color, margin: const EdgeInsets.symmetric(horizontal: 2)),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTaxaIndicator(String label, double taxa) {
    return Column(
      children: [
        Text('${taxa.toStringAsFixed(1)}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: taxa > 20 ? Colors.red : Colors.green)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildAgendamentosTab() {
    return StreamBuilder<List<Agendamento>>(
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
                      if (agendamento.listaEspera.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12)),
                          child: Text('Espera: ${agendamento.listaEspera.length}', 
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _atualizarStatus(agendamento, 'aprovado', clienteId: agendamento.clienteId),
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
    );
  }

  // --- CLIENTES TAB (PACOTES) ---
  Widget _buildClientesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Pesquisar Cliente',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _filtroNome = value.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Cliente>>(
            stream: _firestoreService.getClientesAprovados(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final todosClientes = snapshot.data!;
              
              final clientes = _filtroNome.isEmpty 
                  ? todosClientes 
                  : todosClientes.where((c) => c.nome.toLowerCase().contains(_filtroNome)).toList();

              if (clientes.isEmpty) return const Center(child: Text('Nenhum cliente encontrado.'));

              return ListView.builder(
                itemCount: clientes.length,
                itemBuilder: (context, index) {
                  final cliente = clientes[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Text(cliente.nome.isNotEmpty ? cliente.nome[0].toUpperCase() : '?'),
                      ),
                      title: Text(cliente.nome),
                      subtitle: Text('Saldo de Sessões: ${cliente.saldoSessoes}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StreamBuilder<UsuarioModel?>(
                            stream: _firestoreService.getUsuarioStream(cliente.uid),
                            builder: (context, snapshot) {
                              final usuario = snapshot.data;
                              final podeVerTudo = usuario?.visualizaTodos ?? false;
                              return IconButton(
                                icon: Icon(podeVerTudo ? Icons.visibility : Icons.visibility_off),
                                color: podeVerTudo ? Colors.blue : Colors.grey,
                                tooltip: 'Permitir ver todos os horários',
                                onPressed: () => _firestoreService.atualizarPermissaoVisualizacao(cliente.uid, !podeVerTudo),
                              );
                            },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_circle, size: 16),
                            label: const Text('Pacote'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade50),
                            onPressed: () => _adicionarPacoteDialog(cliente),
                          ),
                        ],
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
  }

  Future<void> _adicionarPacoteDialog(Cliente cliente) async {
    await _firestoreService.adicionarPacote(cliente.uid, 10);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pacote de 10 sessões adicionado para ${cliente.nome}!')),
      );
    }
  }

  // --- USUARIOS PENDENTES TAB ---
  Widget _buildUsuariosTab() {
    return StreamBuilder<List<UsuarioModel>>(
      stream: _firestoreService.getUsuariosPendentes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final usuarios = snapshot.data ?? [];

        if (usuarios.isEmpty) {
          return const Center(child: Text('Nenhum usuário pendente.'));
        }

        return ListView.builder(
          itemCount: usuarios.length,
          itemBuilder: (context, index) {
            final usuario = usuarios[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.orange),
                title: Text(usuario.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Email: ${usuario.email}\nCadastrado em: ${usuario.dataCadastro != null ? DateFormat('dd/MM/yyyy HH:mm').format(usuario.dataCadastro!) : '-'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => _aprovarUsuario(usuario),
                  tooltip: 'Aprovar Cadastro',
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _atualizarStatus(Agendamento agendamento, String novoStatus, {String? clienteId}) async {
    if (agendamento.id == null) return;
    
    await _firestoreService.atualizarStatusAgendamento(agendamento.id!, novoStatus, clienteId: clienteId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agendamento $novoStatus com sucesso!')),
      );
    }
  }

  Future<void> _aprovarUsuario(UsuarioModel usuario) async {
    await _firestoreService.aprovarUsuario(usuario.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuário ${usuario.nome} aprovado com sucesso!')),
      );
    }
  }
}