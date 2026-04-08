import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import necessário para HapticFeedback
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:agenda/core/services/app_governance_service.dart';
import 'package:agenda/core/services/firestore_service.dart';
import 'package:agenda/core/models/agendamento_model.dart';
import 'package:agenda/core/models/usuario_model.dart';
import 'package:agenda/core/models/cliente_model.dart';
import 'package:agenda/core/models/transacao_model.dart';
import 'package:agenda/features/auth/view/login_view.dart';
import 'package:agenda/features/admin/view/config_view.dart';
import 'package:agenda/features/estoque/view/admin_estoque_view.dart';
import 'package:agenda/features/admin/view/relatorios_view.dart';
import 'package:agenda/features/admin/view/logs_view.dart';
import 'package:agenda/features/admin/view/lgpd_logs_view.dart';
import 'package:agenda/view/dev_tools_view.dart';
import 'package:agenda/features/financeiro/view/admin_financeiro_view.dart';
import 'package:agenda/core/widgets/language_selector.dart';
import 'package:agenda/core/widgets/theme_selector.dart';
import 'package:agenda/core/utils/custom_theme_data.dart';
import 'package:agenda/core/utils/app_strings.dart';
import 'package:agenda/core/widgets/app_governance_dialogs.dart';
import 'package:agenda/app_localizations.dart';
import 'package:agenda/core/utils/massage_type_catalog.dart';

class AdminAgendamentosView extends StatefulWidget {
  const AdminAgendamentosView({super.key});

  static bool isCompactLayoutForWidth(double largura) => largura < 980;

  @override
  State<AdminAgendamentosView> createState() => _AdminAgendamentosViewState();
}

class _AdminAgendamentosViewState extends State<AdminAgendamentosView> {
  final FirestoreService _firestoreService = FirestoreService();
  final AppGovernanceService _appGovernanceService = AppGovernanceService();
  static const double _fonteResumoCliente = 10.0;
  DateTime _dataDashboard = DateTime.now();
  double _precoSessao = 100.00;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _filtroNome = '';
  int _clientesRefreshNonce = 0;
  bool _devGravarMetricas = false; // Flag para ativar gravação de histórico
  bool _podeAcessarPainelDev = false;
  bool _governancaVersionadaVerificada = false;
  String? _usuarioAprovandoId;
  bool _focarBuscaClientesAoAbrir = false;

  void _resetPesquisarClientes() {
    setState(() {
      _searchController.clear();
      _filtroNome = '';
      _clientesRefreshNonce++;
    });
  }

  void _prepararFocoBuscaClientes() {
    _focarBuscaClientesAoAbrir = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focarBuscaClientesAoAbrir) return;
      _focarBuscaClientesAoAbrir = false;
      _searchFocusNode.requestFocus();
      final texto = _searchController.text;
      _searchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: texto.length,
      );
    });
  }

  String _normalizarTextoBusca(String texto) {
    return texto
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _clienteCorrespondeFiltro(Cliente cliente, String filtroNormalizado) {
    if (filtroNormalizado.isEmpty) return true;

    final camposBusca = <String>[
      cliente.nomeExibicao,
      cliente.nome,
      cliente.nomePreferidoCliente ?? '',
      cliente.whatsapp,
      cliente.telefonePrincipal,
      cliente.uid,
    ];

    return camposBusca.any(
      (campo) => _normalizarTextoBusca(campo).contains(filtroNormalizado),
    );
  }

  String _formatarDataResumo(DateTime? data) {
    if (data == null) return AppStrings.naoDisponivelCurto;
    return DateFormat('dd/MM/yyyy').format(data);
  }

  String _formatarDataHoraResumo(DateTime? data) {
    if (data == null) return AppStrings.naoDisponivelCurto;
    return DateFormat('dd/MM/yyyy HH:mm').format(data);
  }

  String _formatarValorResumo(double? valor) {
    if (valor == null) return AppStrings.naoDisponivelCurto;
    return 'R\$ ${valor.toStringAsFixed(2)}';
  }

  String _formatarListaHorariosResumo(List<Agendamento> agendamentos) {
    if (agendamentos.isEmpty) return AppStrings.naoDisponivelCurto;

    return agendamentos
        .map((agendamento) => DateFormat('dd/MM HH:mm').format(agendamento.dataHora))
        .join(' | ');
  }

  String _extrairRotuloResumo(String linhaComValor) {
    final linha = linhaComValor.trim();
    if (!linha.endsWith(':')) return linha;
    return linha.substring(0, linha.length - 1).trim();
  }

  Widget _buildResumoClienteDetalhado(Cliente cliente) {
    return StreamBuilder<List<Agendamento>>(
      stream: _firestoreService.getAgendamentosDoCliente(cliente.uid),
      builder: (context, agendamentosSnapshot) {
        final agendamentos = agendamentosSnapshot.data ?? const <Agendamento>[];
        final agora = DateTime.now();

        final atendimentosConcluidos = agendamentos
            .where(
              (agendamento) =>
                  agendamento.status == 'aprovado' &&
                  !agendamento.dataHora.isAfter(agora),
            )
            .toList()
          ..sort((a, b) => b.dataHora.compareTo(a.dataHora));

        final ultimos3Atendimentos = atendimentosConcluidos.take(3).toList();

        final proximosAtendimentos = agendamentos
            .where(
              (agendamento) =>
                  agendamento.dataHora.isAfter(agora) &&
                  agendamento.status != 'cancelado' &&
                  agendamento.status != 'cancelado_tardio' &&
                  agendamento.status != 'recusado',
            )
            .toList()
          ..sort((a, b) => a.dataHora.compareTo(b.dataHora));

        final proximos5Atendimentos = proximosAtendimentos.take(5).toList();
        final recorrente =
            atendimentosConcluidos.length >= 3 || cliente.sugestaoClienteFixoAgenda;
        final pacoteVaiAte =
            proximosAtendimentos.isNotEmpty ? proximosAtendimentos.last.dataHora : null;

        return StreamBuilder<List<TransacaoFinanceira>>(
          stream: _firestoreService.getTransacoesDoCliente(cliente.uid),
          builder: (context, transacoesSnapshot) {
            final transacoes =
                transacoesSnapshot.data ?? const <TransacaoFinanceira>[];

            final transacoesPagas = transacoes
                .where(
                  (transacao) =>
                      transacao.statusPagamento.toLowerCase() == 'pago',
                )
                .toList()
              ..sort((a, b) => b.dataPagamento.compareTo(a.dataPagamento));

            final ultimaTransacaoPaga =
                transacoesPagas.isNotEmpty ? transacoesPagas.first : null;

            final linhasResumo = <String>[
              AppStrings.saldoSessoesLabel(cliente.saldoSessoes),
              AppStrings.clienteResumoValorUltimoPagamento(
                _formatarValorResumo(ultimaTransacaoPaga?.valorLiquido),
              ),
              AppStrings.clienteResumoRecorrente(recorrente),
              AppStrings.clienteResumoUltimosAtendimentos(
                _formatarListaHorariosResumo(ultimos3Atendimentos),
              ),
              AppStrings.clienteResumoProximosAtendimentos(
                _formatarListaHorariosResumo(proximos5Atendimentos),
              ),
            ];

            final linhasTabelaDatas = <MapEntry<String, String>>[
              MapEntry(
                _extrairRotuloResumo(
                  AppStrings.clienteResumoUltimoDiaFinanceiroPago(''),
                ),
                _formatarDataResumo(ultimaTransacaoPaga?.dataPagamento),
              ),
              MapEntry(
                _extrairRotuloResumo(
                  AppStrings.clienteResumoDataRegistroFinanceiro(''),
                ),
                _formatarDataHoraResumo(
                  ultimaTransacaoPaga?.dataCriacao ??
                      ultimaTransacaoPaga?.dataPagamento,
                ),
              ),
              MapEntry(
                _extrairRotuloResumo(
                  AppStrings.clienteResumoPacoteVaiAte(''),
                ),
                _formatarDataResumo(pacoteVaiAte),
              ),
              MapEntry(
                _extrairRotuloResumo(
                  AppStrings.clienteResumoPacoteExpiraEm(''),
                ),
                AppStrings.naoDisponivelCurto,
              ),
            ];

            final estiloResumo = const TextStyle(
              fontSize: _fonteResumoCliente,
              height: 1.2,
            );

            final blocoResumo = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: linhasResumo
                  .map(
                    (linha) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(linha, style: estiloResumo),
                    ),
                  )
                  .toList(),
            );

            final tabelaDatas = Table(
              columnWidths: const {
                0: FlexColumnWidth(2.8),
                1: FlexColumnWidth(1.8),
              },
              border: TableBorder.all(
                color: Colors.grey,
                width: 0.4,
              ),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: linhasTabelaDatas
                  .map(
                    (linha) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            linha.key,
                            style: estiloResumo.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            linha.value,
                            style: estiloResumo,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            );

            return LayoutBuilder(
              builder: (context, constraints) {
                final exibirTabelaAoLado = constraints.maxWidth >= 520;

                if (exibirTabelaAoLado) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: blocoResumo),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: tabelaDatas),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    blocoResumo,
                    const SizedBox(height: 6),
                    tabelaDatas,
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _carregarConfig();
    _carregarPermissoesPainelDev();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executarGovernancaPosLogin();
    });
  }

  Future<void> _carregarPermissoesPainelDev() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final usuario = await _firestoreService.getUsuario(uid);
    if (!mounted) return;

    setState(() {
      _podeAcessarPainelDev = _firestoreService.podeAcessarPainelDev(usuario);
    });
  }

  Future<void> _carregarConfig() async {
    final config = await _firestoreService.getConfiguracao();
    if (mounted) {
      setState(() {
        _precoSessao = config.precoSessao;
      });
    }
  }

  Future<void> _abrirSwaggerYaml() async {
    try {
      final conteudo = await rootBundle.loadString('lib/documents/swagger.yaml');
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: Text(AppStrings.swaggerYamlTitulo),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                conteudo,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.erroAbrirSwagger('$e'))),
      );
    }
  }

  Future<void> _abrirConfiguracaoContatoAprovacao() async {
    final messenger = ScaffoldMessenger.of(context);

    final nomeController = TextEditingController();
    final whatsappController = TextEditingController();
    final mensagemController = TextEditingController();

    try {
      final config = await _firestoreService.getContatoAprovacaoConfig();
      nomeController.text = config.nomeAdministradoraExibicao;
      whatsappController.text = config.whatsappRedirecionamento;
      mensagemController.text = config.mensagemTemplate;

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppStrings.configContatoAprovacaoTitulo),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.configContatoAprovacaoDescricao,
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: AppStrings.configContatoAprovacaoNomeAdminLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: whatsappController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText:
                        AppStrings.configContatoAprovacaoWhatsappLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mensagemController,
                  minLines: 6,
                  maxLines: 12,
                  decoration: InputDecoration(
                    labelText:
                        AppStrings.configContatoAprovacaoMensagemLabel,
                    hintText: AppStrings.configContatoAprovacaoMensagemHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.configContatoAprovacaoPlaceholdersHint,
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppStrings.cancelarButton),
            ),
            ElevatedButton(
              onPressed: () async {
                final nome = nomeController.text.trim();
                final whatsapp = whatsappController.text.trim();
                final mensagem = mensagemController.text.trim();

                if (nome.isEmpty || whatsapp.isEmpty || mensagem.isEmpty) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(AppStrings.requiredField)),
                  );
                  return;
                }

                try {
                  await _firestoreService.salvarContatoAprovacaoConfig(
                    nomeAdministradoraExibicao: nome,
                    whatsappRedirecionamento: whatsapp,
                    mensagemTemplate: mensagem,
                  );
                  if (!mounted) return;

                  Navigator.of(dialogContext).pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        AppStrings.configContatoAprovacaoSalvaSucesso,
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        AppStrings.erroSalvarConfigContatoAprovacao('$e'),
                      ),
                    ),
                  );
                }
              },
              child: Text(AppStrings.salvar),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStrings.erroCarregarConfigContatoAprovacao('$e')),
        ),
      );
    } finally {
      nomeController.dispose();
      whatsappController.dispose();
      mensagemController.dispose();
    }
  }

  Future<void> _executarGovernancaPosLogin() async {
    if (_governancaVersionadaVerificada || !mounted) return;
    _governancaVersionadaVerificada = true;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final usuario = await _firestoreService.getUsuario(uid);
    if (!mounted || usuario == null) return;

    final resultado = await _appGovernanceService.verificarPosLogin(usuario);
    if (!mounted) return;

    await AppGovernanceDialogs.processarResultadoGovernanca(
      context,
      resultado: resultado,
      usuario: usuario,
      governanceService: _appGovernanceService,
      uid: uid,
      loginViewBuilder: (_) => const LoginView(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layoutCompacto = AdminAgendamentosView.isCompactLayoutForWidth(
      MediaQuery.of(context).size.width,
    );

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        drawer: _podeAcessarPainelDev
            ? Drawer(
                child: SafeArea(
                  child: ListView(
                    children: [
                      DrawerHeader(
                        decoration: BoxDecoration(color: Colors.orange),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            AppStrings.sistema,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.developer_mode),
                        title: Text(AppStrings.devToolsDb),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DevToolsView(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(AppStrings.swaggerYamlTitulo),
                        onTap: () {
                          Navigator.pop(context);
                          _abrirSwaggerYaml();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings_phone_outlined),
                        title: Text(
                          AppStrings.configContatoAprovacaoAvancadaMenu,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _abrirConfiguracaoContatoAprovacao();
                        },
                      ),
                    ],
                  ),
                ),
              )
            : null,
        appBar: AppBar(
          title: Text(AppStrings.administracao),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          actions: [
            if (layoutCompacto)
              PopupMenuButton<String>(
                tooltip: AppStrings.menuAcoesAdmin,
                onSelected: (acao) {
                  switch (acao) {
                    case 'relatorios':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminRelatoriosView(),
                        ),
                      );
                      break;
                    case 'financeiro':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminFinanceiroView(),
                        ),
                      );
                      break;
                    case 'logs':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminLogsView(),
                        ),
                      );
                      break;
                    case 'lgpd':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminLgpdLogsView(),
                        ),
                      );
                      break;
                    case 'estoque':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminEstoqueView(),
                        ),
                      );
                      break;
                    case 'config':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminConfigView(),
                        ),
                      );
                      break;
                    case 'devtools':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DevToolsView(),
                        ),
                      );
                      break;
                    default:
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'relatorios',
                    child: Text(AppStrings.relatorios),
                  ),
                  PopupMenuItem(
                    value: 'financeiro',
                    child: Text(AppStrings.financeiroAnualTitulo),
                  ),
                  PopupMenuItem(
                    value: 'logs',
                    child: Text(AppStrings.logsSistema),
                  ),
                  PopupMenuItem(
                    value: 'lgpd',
                    child: Text(AppStrings.auditoriaLgpd),
                  ),
                  PopupMenuItem(
                    value: 'estoque',
                    child: Text(AppStrings.estoqueControle),
                  ),
                  PopupMenuItem(
                    value: 'config',
                    child: Text(AppStrings.configuracoes),
                  ),
                  if (_podeAcessarPainelDev)
                    PopupMenuItem(
                      value: 'devtools',
                      child: Text(AppStrings.devToolsDb),
                    ),
                ],
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.analytics),
                tooltip: AppStrings.relatorios,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminRelatoriosView(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.attach_money),
                tooltip: AppStrings.financeiroAnualTitulo,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminFinanceiroView(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.list_alt),
                tooltip: AppStrings.logsSistema,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminLogsView(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.privacy_tip),
                tooltip: AppStrings.auditoriaLgpd,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminLgpdLogsView(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.inventory_2),
                tooltip: AppStrings.estoqueControle,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminEstoqueView(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: AppStrings.configuracoes,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminConfigView(),
                    ),
                  );
                },
              ),
              if (_podeAcessarPainelDev)
                IconButton(
                  icon: const Icon(Icons.developer_mode),
                  tooltip: AppStrings.devToolsDb,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DevToolsView(),
                      ),
                    );
                  },
                ),
            ],
            const ThemeSelector(),
            const LanguageSelector(),
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  navigator.pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginView()),
                  );
                }
              },
            ),
          ],
          bottom: TabBar(
            isScrollable: layoutCompacto,
            onTap: (index) {
              HapticFeedback.mediumImpact(); // Vibração ao trocar de aba
              if (index == 2) {
                _prepararFocoBuscaClientes();
              }
            },
            tabs: [
              Tab(icon: const Icon(Icons.dashboard), text: AppStrings.dash),
              Tab(
                icon: const Icon(Icons.calendar_today),
                text: AppStrings.agenda,
              ),
              Tab(icon: const Icon(Icons.people), text: AppStrings.clientes),
              Tab(
                icon: const Icon(Icons.person_add),
                text: AppStrings.pendentes,
              ),
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final todosAgendamentos = snapshot.data!;

        // Filtros de Data
        final diaInicio = DateTime(
          _dataDashboard.year,
          _dataDashboard.month,
          _dataDashboard.day,
        );
        final diaFim = diaInicio.add(const Duration(days: 1));

        // Semana (Domingo a Sábado)
        final inicioSemana = diaInicio.subtract(
          Duration(days: diaInicio.weekday % 7),
        );
        final fimSemana = inicioSemana.add(const Duration(days: 7));

        // Mês
        final inicioMes = DateTime(
          _dataDashboard.year,
          _dataDashboard.month,
          1,
        );
        final fimMes = DateTime(
          _dataDashboard.year,
          _dataDashboard.month + 1,
          1,
        );

        // Cálculos
        final agendamentosMes = todosAgendamentos
            .where(
              (a) =>
                  a.dataHora.isAfter(inicioMes) && a.dataHora.isBefore(fimMes),
            )
            .toList();
        final agendamentosDia = todosAgendamentos
            .where(
              (a) =>
                  a.dataHora.isAfter(diaInicio) && a.dataHora.isBefore(diaFim),
            )
            .toList();

        // Receita Estimada (Aprovados no Mês)
        final aprovadosMes = agendamentosMes
            .where((a) => a.status == 'aprovado')
            .length;
        final receitaEstimada = aprovadosMes * _precoSessao;

        // Status do Dia
        final pendentesDia = agendamentosDia
            .where((a) => a.status == 'pendente')
            .length;
        final aprovadosDia = agendamentosDia
            .where((a) => a.status == 'aprovado')
            .length;
        final canceladosDia = agendamentosDia
            .where(
              (a) => a.status.contains('cancelado') || a.status == 'recusado',
            )
            .length;

        // Taxas de Cancelamento
        double calcularTaxa(DateTime inicio, DateTime fim) {
          final lista = todosAgendamentos
              .where(
                (a) => a.dataHora.isAfter(inicio) && a.dataHora.isBefore(fim),
              )
              .toList();
          if (lista.isEmpty) return 0.0;
          final cancelados = lista
              .where(
                (a) => a.status.contains('cancelado') || a.status == 'recusado',
              )
              .length;
          return (cancelados / lista.length) * 100;
        }

        final taxaDia = calcularTaxa(diaInicio, diaFim);
        final taxaSemana = calcularTaxa(inicioSemana, fimSemana);
        final taxaMes = calcularTaxa(inicioMes, fimMes);

        // Distribuição de Tipos (Para o Gráfico)
        final Map<String, int> distribuicaoTipos = {};
        for (var a in agendamentosMes) {
          final tipoId = MassageTypeCatalog.normalizeId(a.tipo);
          distribuicaoTipos[tipoId] = (distribuicaoTipos[tipoId] ?? 0) + 1;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Navegação de Data
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(
                      () => _dataDashboard = _dataDashboard.subtract(
                        const Duration(days: 1),
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_dataDashboard),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(
                      () => _dataDashboard = _dataDashboard.add(
                        const Duration(days: 1),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.today),
                    onPressed: () =>
                        setState(() => _dataDashboard = DateTime.now()),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Cards Principais
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      AppStrings.agendamentosDia,
                      '${agendamentosDia.length}',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      AppStrings.receitaEstimadaMes,
                      'R\$ ${receitaEstimada.toStringAsFixed(2)}',
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                AppStrings.statusDoDia,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildBarraStatus(
                    AppStrings.pendentes,
                    pendentesDia,
                    Colors.orange,
                  ),
                  _buildBarraStatus(
                    AppStrings.aprovados,
                    aprovadosDia,
                    Colors.green,
                  ),
                  _buildBarraStatus(
                    AppStrings.cancelRec,
                    canceladosDia,
                    Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                AppStrings.taxaCancelamento,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTaxaIndicator(AppStrings.hoje, taxaDia),
                      _buildTaxaIndicator(AppStrings.semana, taxaSemana),
                      _buildTaxaIndicator(AppStrings.mes, taxaMes),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                AppStrings.tiposMaisAgendados,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              if (distribuicaoTipos.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: distribuicaoTipos.entries.map((e) {
                              final index = distribuicaoTipos.keys
                                  .toList()
                                  .indexOf(e.key);
                              final color = Colors
                                  .primaries[index % Colors.primaries.length];
                              return PieChartSectionData(
                                color: color,
                                value: e.value.toDouble(),
                                title: '${e.value}',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: distribuicaoTipos.entries.map((e) {
                          final index = distribuicaoTipos.keys.toList().indexOf(
                            e.key,
                          );
                          final color =
                              Colors.primaries[index % Colors.primaries.length];
                          return Row(
                            children: [
                              Container(width: 12, height: 12, color: color),
                              const SizedBox(width: 4),
                              Text(
                                '${MassageTypeCatalog.localize(AppLocalizations.of(context)!, e.key)} (${e.value})',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                )
              else
                Center(
                  child: Text(
                    AppStrings.semDadosGrafico,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),

              const SizedBox(height: 20),
              const Divider(),

              // Área de Controle do Desenvolvedor (Gravação de Métricas)
              SwitchListTile(
                title: Text(
                  AppStrings.ativarGravacaoHistorico,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                subtitle: Text(AppStrings.permiteSalvarMetricas),
                value: _devGravarMetricas,
                onChanged: (val) => setState(() => _devGravarMetricas = val),
                secondary: const Icon(
                  Icons.developer_board,
                  color: Colors.grey,
                ),
              ),

              if (_devGravarMetricas)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_as),
                      label: Text(AppStrings.gravarSnapshot),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _salvarSnapshotMetricas(
                        agendamentosDia.length,
                        receitaEstimada,
                        pendentesDia,
                        aprovadosDia,
                        canceladosDia,
                        taxaDia,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _salvarSnapshotMetricas(
    int totalDia,
    double receita,
    int pendentes,
    int aprovados,
    int cancelados,
    double taxaCancelamento,
  ) async {
    try {
      final metricas = {
        'data_registro': FieldValue.serverTimestamp(),
        'total_agendamentos': totalDia,
        'receita_estimada': receita,
        'pendentes': pendentes,
        'aprovados': aprovados,
        'cancelados': cancelados,
        'taxa_cancelamento': taxaCancelamento,
        'snapshot_hora': DateFormat('HH:mm:ss').format(DateTime.now()),
      };

      await _firestoreService.salvarMetricasDiarias(metricas);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.metricasSalvasSucesso)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.erroSalvarMetricas('$e'))),
        );
      }
    }
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraStatus(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 10,
            color: color,
            margin: const EdgeInsets.symmetric(horizontal: 2),
          ),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTaxaIndicator(String label, double taxa) {
    return Column(
      children: [
        Text(
          '${taxa.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: taxa > 20 ? Colors.red : Colors.green,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildAgendamentosTab() {
    return StreamBuilder<List<Agendamento>>(
      stream: _firestoreService.getAgendamentos(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(AppStrings.erroGenerico('${snapshot.error}')),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filtrar apenas os pendentes
        final agendamentos =
            snapshot.data?.where((a) => a.status == 'pendente').toList() ?? [];

        if (agendamentos.isEmpty) {
          return Center(child: Text(AppStrings.nenhumAgendamentoPendente));
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
                subtitle: Text(
                  AppStrings.resumoClienteTipo(
                    agendamento.clienteId,
                    MassageTypeCatalog.localize(
                      AppLocalizations.of(context)!,
                      agendamento.tipo,
                    ),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (agendamento.listaEspera.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AppStrings.esperaLabel(
                            agendamento.listaEspera.length,
                          ),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _atualizarStatus(
                        agendamento,
                        'aprovado',
                        clienteId: agendamento.clienteId,
                      ),
                      tooltip: AppStrings.aprovar,
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () =>
                          _atualizarStatus(agendamento, 'recusado'),
                      tooltip: AppStrings.recusar,
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
            focusNode: _searchFocusNode,
            autofocus: false,
            decoration: InputDecoration(
              labelText: AppStrings.pesquisarCliente,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _resetPesquisarClientes,
              ),
              border: const OutlineInputBorder(),
            ),
            onTap: () {
              final texto = _searchController.text;
              _searchController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: texto.length,
              );
              if (_searchController.text.trim().isEmpty && _filtroNome.isEmpty) {
                setState(() {
                  _clientesRefreshNonce++;
                });
              }
            },
            onChanged: (value) {
              setState(() {
                _filtroNome = _normalizarTextoBusca(value);
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Cliente>>(
            key: ValueKey(_clientesRefreshNonce),
            stream: _firestoreService.getClientesAprovados(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                final erro = snapshot.error;
                final mensagemErro = erro is FirebaseException &&
                        erro.code == 'permission-denied'
                    ? AppStrings.erroCarregar(
                        AppStrings.erroPermissaoLerClientes,
                      )
                    : AppStrings.erroCarregar('$erro');

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      mensagemErro,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final todosClientes = snapshot.data ?? const <Cliente>[];

              final clientes = _filtroNome.isEmpty
                  ? todosClientes
                  : todosClientes
                        .where(
                          (c) => _clienteCorrespondeFiltro(c, _filtroNome),
                        )
                        .toList();

              if (clientes.isEmpty) {
                return Center(child: Text(AppStrings.nenhumClienteEncontrado));
              }

              return ListView.builder(
                itemCount: clientes.length,
                itemBuilder: (context, index) {
                  final cliente = clientes[index];
                  final nomeExibicao = cliente.nomeExibicao.isNotEmpty
                      ? cliente.nomeExibicao
                      : cliente.nome;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.teal,
                                child: Text(
                                  nomeExibicao.isNotEmpty
                                      ? nomeExibicao[0].toUpperCase()
                                      : '?',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  nomeExibicao,
                                  style: (() {
                                    final estiloBase =
                                        Theme.of(context).textTheme.titleMedium;
                                    final tamanhoBase = estiloBase?.fontSize ?? 16;
                                    final tamanhoAjustado =
                                        (tamanhoBase - 1).clamp(12.0, 40.0).toDouble();
                                    return (estiloBase ?? const TextStyle()).copyWith(
                                      fontSize: tamanhoAjustado,
                                      fontWeight: FontWeight.bold,
                                    );
                                  })(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildResumoClienteDetalhado(cliente),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              StreamBuilder<UsuarioModel?>(
                                stream: _firestoreService.getUsuarioStream(
                                  cliente.uid,
                                ),
                                builder: (context, snapshot) {
                                  final usuario = snapshot.data;
                                  final podeVerTudo =
                                      usuario?.visualizaTodos ?? false;

                                  return Tooltip(
                                    message: AppStrings.permitirVerTodosHorarios,
                                    child: IconButton(
                                      icon: Icon(
                                        podeVerTudo
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      color: podeVerTudo
                                          ? Colors.blue
                                          : Colors.grey,
                                      onPressed: () => _firestoreService
                                          .atualizarPermissaoVisualizacao(
                                            cliente.uid,
                                            !podeVerTudo,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              Tooltip(
                                message: AppStrings.alterarTemaUsuario,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.palette,
                                    color: Colors.purple,
                                  ),
                                  onPressed: () => _alterarTemaUsuarioDialog(cliente),
                                ),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add_circle, size: 16),
                                label: Text(AppStrings.alterarPacotes),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade50,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () => _adicionarPacoteDialog(cliente),
                              ),
                            ],
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

  Future<void> _alterarTemaUsuarioDialog(Cliente cliente) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: Text(AppStrings.temaDe(cliente.nome)),
          children: AppThemeType.values.map((theme) {
            final data = CustomThemeData.getData(theme);
            return SimpleDialogOption(
              child: Row(
                children: [
                  Icon(
                    data.iconAsset ?? Icons.circle,
                    color: data.iconColor != Colors.white24
                        ? data.iconColor
                        : Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Text(data.label),
                ],
              ),
              onPressed: () async {
                await _firestoreService.atualizarTemaUsuario(
                  cliente.uid,
                  theme.toString(),
                );

                // Fecha o diálogo usando o contexto do diálogo
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                // Exibe o SnackBar usando o contexto da Tela (State), verificado pelo 'mounted' do State
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.temaAlteradoPara(data.label)),
                    ),
                  );
                }
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _adicionarPacoteDialog(Cliente cliente) async {
    await _firestoreService.adicionarPacote(cliente.uid, 10);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.pacoteAdicionadoPara(cliente.nome))),
      );
    }
  }

  // --- USUARIOS PENDENTES TAB ---
  Widget _buildUsuariosTab() {
    return StreamBuilder<List<UsuarioModel>>(
      stream: _firestoreService.getUsuariosPendentes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(AppStrings.erroGenerico('${snapshot.error}')),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final usuarios = snapshot.data ?? [];

        if (usuarios.isEmpty) {
          return Center(child: Text(AppStrings.nenhumUsuarioPendente));
        }

        return ListView.builder(
          itemCount: usuarios.length,
          itemBuilder: (context, index) {
            final usuario = usuarios[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.orange),
                title: Text(
                  usuario.nome,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  AppStrings.emailCadastroLabel(
                    usuario.email,
                    usuario.dataCadastro != null
                        ? DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(usuario.dataCadastro!)
                        : '-',
                  ),
                ),
                trailing: IconButton(
                  icon: _usuarioAprovandoId == usuario.id
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: _usuarioAprovandoId == usuario.id
                      ? null
                      : () => _aprovarUsuario(usuario),
                  tooltip: AppStrings.aprovarCadastro,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _atualizarStatus(
    Agendamento agendamento,
    String novoStatus, {
    String? clienteId,
  }) async {
    if (agendamento.id == null) return;

    await _firestoreService.atualizarStatusAgendamento(
      agendamento.id!,
      novoStatus,
      clienteId: clienteId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.agendamentoStatusSucesso(novoStatus)),
        ),
      );
    }
  }

  Future<void> _aprovarUsuario(UsuarioModel usuario) async {
    setState(() {
      _usuarioAprovandoId = usuario.id;
    });

    try {
      await _firestoreService.aprovarUsuario(usuario.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.usuarioAprovadoSucesso(usuario.nome)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.erroCarregar('$e'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _usuarioAprovandoId = null;
        });
      }
    }
  }
}
