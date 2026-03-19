import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agenda/core/services/firestore_service.dart';
import 'package:agenda/core/models/firestore_structure_helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:agenda/core/utils/app_strings.dart';
import 'package:agenda/app_localizations.dart';
import 'package:agenda/core/utils/massage_type_catalog.dart';

class _RegistroConferencia {
  final String caminho;
  final String status;
  final String detalhes;
  final DateTime horario;

  const _RegistroConferencia({
    required this.caminho,
    required this.status,
    required this.detalhes,
    required this.horario,
  });
}

/// Tela de ferramentas de administração para visualização e configuração
/// de dados do banco de dados Firebase.
///
/// Exibe:
/// - Campos editáveis (podem ser alterados)
/// - Campos não editáveis (cinza, apenas visualização - fixos no banco/app)
class AdminFerramentasDatabaseSetupView extends StatefulWidget {
  const AdminFerramentasDatabaseSetupView({super.key});

  @override
  State<AdminFerramentasDatabaseSetupView> createState() =>
      _AdminFerramentasDatabaseSetupViewState();
}

class _AdminFerramentasDatabaseSetupViewState
    extends State<AdminFerramentasDatabaseSetupView> {
  static const String _prefLembrarCredenciais =
      'admin_tools_lembra_credenciais';
  static const String _prefUsuarioCredenciais = 'admin_tools_usuario';
  static const String _prefSenhaCredenciais = 'admin_tools_senha';

  String get _usuarioPadraoAcesso =>
      (dotenv.env['ADMIN_TOOLS_SETUP_USERNAME'] ?? '').trim();
  String get _senhaPadraoAcesso =>
      (dotenv.env['ADMIN_TOOLS_SETUP_PASSWORD'] ?? '').trim();
  bool get _temAcessoBootstrapConfigurado =>
      _usuarioPadraoAcesso.isNotEmpty && _senhaPadraoAcesso.isNotEmpty;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  bool _acessoLiberado = false;
  bool _lembrarCredenciais = false;
  bool _validandoAcesso = false;
  bool _carregando = true;
  String? _erroAcesso;
  String _usuarioAcessoEsperado = '';
  String _senhaAcessoEsperada = '';

  final _usuarioAcessoController = TextEditingController();
  final _senhaAcessoController = TextEditingController();
  Map<String, dynamic> _configGeral = {};
  Map<String, dynamic> _configSeguranca = {};
  Map<String, dynamic> _configServicos = {};
  Map<String, dynamic> _configNotificacoes = {};
  Map<String, dynamic> _configPagamento = {};
  List<_RegistroConferencia> _registrosConferencia = const [];

  // Controllers para campos editáveis
  final _whatsappController = TextEditingController();
  final _precoSessaoController = TextEditingController();
  final _horasAntecedenciaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inicializarCredenciaisAcesso();
  }

  @override
  void dispose() {
    _usuarioAcessoController.dispose();
    _senhaAcessoController.dispose();
    _whatsappController.dispose();
    _precoSessaoController.dispose();
    _horasAntecedenciaController.dispose();
    super.dispose();
  }

  Future<void> _inicializarCredenciaisAcesso() async {
    String usuarioEsperado = _usuarioPadraoAcesso;
    String senhaEsperada = _senhaPadraoAcesso;

    try {
      final segurancaSnap = await _db
          .collection('configuracoes')
          .doc('seguranca')
          .get();
      final data = segurancaSnap.data() ?? <String, dynamic>{};
      final usuarioFirestore =
          (data['usuario_admin_ferramentas'] as String? ?? '').trim();
      final senhaFirestore = (data['senha_admin_ferramentas'] as String? ?? '')
          .trim();

      if (usuarioFirestore.isNotEmpty) {
        usuarioEsperado = usuarioFirestore;
      }
      if (senhaFirestore.isNotEmpty) {
        senhaEsperada = senhaFirestore;
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final lembrar = prefs.getBool(_prefLembrarCredenciais) ?? false;
    final usuarioSalvo = (prefs.getString(_prefUsuarioCredenciais) ?? '')
        .trim();
    final senhaSalva = (prefs.getString(_prefSenhaCredenciais) ?? '').trim();

    if (!mounted) return;
    setState(() {
      _usuarioAcessoEsperado = usuarioEsperado;
      _senhaAcessoEsperada = senhaEsperada;
      _lembrarCredenciais = lembrar;
      _usuarioAcessoController.text = lembrar && usuarioSalvo.isNotEmpty
          ? usuarioSalvo
          : usuarioEsperado;
      _senhaAcessoController.text = lembrar ? senhaSalva : '';
    });
  }

  Future<void> _persistirPreferenciaCredenciais() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefLembrarCredenciais, _lembrarCredenciais);

    if (_lembrarCredenciais) {
      await prefs.setString(
        _prefUsuarioCredenciais,
        _usuarioAcessoController.text.trim(),
      );
      await prefs.setString(
        _prefSenhaCredenciais,
        _senhaAcessoController.text.trim(),
      );
      return;
    }

    await prefs.remove(_prefUsuarioCredenciais);
    await prefs.remove(_prefSenhaCredenciais);
  }

  Future<void> _liberarAcesso() async {
    final usuario = _usuarioAcessoController.text.trim();
    final senha = _senhaAcessoController.text.trim();

    setState(() {
      _validandoAcesso = true;
      _erroAcesso = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 150));

    final acessoRapidoPadrao =
        _temAcessoBootstrapConfigurado &&
        usuario == _usuarioPadraoAcesso &&
        senha == _senhaPadraoAcesso;
    final acessoConfigurado =
        usuario == _usuarioAcessoEsperado && senha == _senhaAcessoEsperada;

    if (acessoRapidoPadrao || acessoConfigurado) {
      await _persistirPreferenciaCredenciais();
      if (!mounted) return;
      setState(() {
        _acessoLiberado = true;
        _validandoAcesso = false;
        _erroAcesso = null;
      });
      await _carregarConfiguracoes();
      return;
    }

    if (!mounted) return;
    setState(() {
      _validandoAcesso = false;
      _erroAcesso = AppStrings.credenciaisInvalidas;
    });
  }

  Future<void> _carregarConfiguracoes() async {
    setState(() => _carregando = true);

    try {
      final geralSnap = await _db
          .collection('configuracoes')
          .doc('geral')
          .get();
      final segurancaSnap = await _db
          .collection('configuracoes')
          .doc('seguranca')
          .get();
      final servicosSnap = await _db
          .collection('configuracoes')
          .doc('servicos')
          .get();
      final notificacoesSnap = await _db
          .collection('configuracoes')
          .doc('notificacoes')
          .get();
      final pagamentoSnap = await _db
          .collection('configuracoes')
          .doc('pagamento')
          .get();

      _configGeral = geralSnap.data() ?? {};
      _configSeguranca = segurancaSnap.data() ?? {};
      _configServicos = servicosSnap.data() ?? {};
      _configNotificacoes = notificacoesSnap.data() ?? {};
      _configPagamento = pagamentoSnap.data() ?? {};

      // Preenche controllers
      final geralPadrao = FirestoreStructureHelper.getConfigGeralPadrao();
      _whatsappController.text =
          (_configGeral['whatsapp_admin'] ??
                  geralPadrao['whatsapp_admin'] ??
                  '')
              .toString();
      _precoSessaoController.text =
          (_configGeral['preco_sessao'] ?? geralPadrao['preco_sessao'] ?? 0.0)
              .toString();
      _horasAntecedenciaController.text =
          (_configGeral['horas_antecedencia_cancelamento'] ??
                  geralPadrao['horas_antecedencia_cancelamento'] ??
                  0.0)
              .toString();

      if (!mounted) return;
      setState(() => _carregando = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.erroCarregar(e.toString()))),
        );
      }
    }
  }

  Future<void> _conferirECriarRegistrosFaltantes() async {
    setState(() {
      _carregando = true;
      _registrosConferencia = const [];
    });

    try {
      await _conferirDocumento(
        'configuracoes/geral',
        FirestoreStructureHelper.getConfigGeralPadrao(),
      );
      await _conferirDocumento(
        'configuracoes/seguranca',
        FirestoreStructureHelper.getConfigSegurancaPadrao(),
      );
      await _conferirDocumento(
        'configuracoes/servicos',
        FirestoreStructureHelper.getConfigServicosPadrao(),
      );
      await _conferirDocumento(
        'configuracoes/notificacoes',
        FirestoreStructureHelper.getConfigNotificacoesPadrao(),
      );
      await _conferirDocumento(
        'configuracoes/pagamento',
        FirestoreStructureHelper.getConfigPagamentoPadrao(),
      );
      await _conferirCredenciaisAcessoFerramentas();

      await _carregarConfiguracoes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.conferenciaConcluidaSemSobrescrever),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.erroConferirRegistros(e.toString()))),
      );
    }
  }

  Future<void> _conferirDocumento(
    String caminho,
    Map<String, dynamic> padrao,
  ) async {
    final docRef = _db.doc(caminho);
    final snap = await docRef.get();

    if (!snap.exists || snap.data() == null) {
      await docRef.set(padrao, SetOptions(merge: true));
      _adicionarRegistro(
        caminho: caminho,
        status: 'criado',
        detalhes: AppStrings.registroDocumentoCriado(padrao.length),
      );
      return;
    }

    final dadosAtuais = snap.data()!;
    final faltantes = <String, dynamic>{};
    padrao.forEach((campo, valorPadrao) {
      if (!dadosAtuais.containsKey(campo) || dadosAtuais[campo] == null) {
        faltantes[campo] = valorPadrao;
      }
    });

    if (faltantes.isNotEmpty) {
      await docRef.set(faltantes, SetOptions(merge: true));
      _adicionarRegistro(
        caminho: caminho,
        status: 'atualizado',
        detalhes: AppStrings.registroCamposCriados(faltantes.keys.join(', ')),
      );
    } else {
      _adicionarRegistro(
        caminho: caminho,
        status: 'conferido',
        detalhes: AppStrings.registroSemCamposFaltantes,
      );
    }
  }

  Future<void> _conferirCredenciaisAcessoFerramentas() async {
    const caminho = 'configuracoes/seguranca';
    final docRef = _db.doc(caminho);
    final snap = await docRef.get();
    final data = snap.data() ?? <String, dynamic>{};

    final faltantes = <String, dynamic>{};
    final usuarioAtual = (data['usuario_admin_ferramentas'] as String? ?? '')
        .trim();
    final senhaAtual = (data['senha_admin_ferramentas'] as String? ?? '')
        .trim();

    if (usuarioAtual.isEmpty && _usuarioPadraoAcesso.isNotEmpty) {
      faltantes['usuario_admin_ferramentas'] = _usuarioPadraoAcesso;
    }
    if (senhaAtual.isEmpty && _senhaPadraoAcesso.isNotEmpty) {
      faltantes['senha_admin_ferramentas'] = _senhaPadraoAcesso;
    }

    if (faltantes.isNotEmpty) {
      await docRef.set(faltantes, SetOptions(merge: true));
      _adicionarRegistro(
        caminho: caminho,
        status: 'atualizado',
        detalhes: AppStrings.registroCredenciaisCriadas(
          faltantes.keys.join(', '),
        ),
      );
    } else {
      _adicionarRegistro(
        caminho: caminho,
        status: 'conferido',
        detalhes: AppStrings.registroCredenciaisJaExistentes,
      );
    }
  }

  void _adicionarRegistro({
    required String caminho,
    required String status,
    required String detalhes,
  }) {
    final proximo = List<_RegistroConferencia>.from(_registrosConferencia)
      ..add(
        _RegistroConferencia(
          caminho: caminho,
          status: status,
          detalhes: detalhes,
          horario: DateTime.now(),
        ),
      );

    if (!mounted) return;
    setState(() {
      _registrosConferencia = proximo;
    });
  }

  Future<void> _salvarAlteracoes() async {
    try {
      setState(() => _carregando = true);

      // Salva campos editáveis
      await _firestoreService.salvarTelefoneAdmin(_whatsappController.text);

      // Atualiza outros campos editáveis com merge (sem apagar os demais campos já existentes).
      await _db.collection('configuracoes').doc('geral').set({
        'whatsapp_admin': _whatsappController.text,
        'preco_sessao': double.tryParse(_precoSessaoController.text) ?? 100.0,
        'horas_antecedencia_cancelamento':
            double.tryParse(_horasAntecedenciaController.text) ?? 24.0,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.alteracoesSalvasSucesso),
            backgroundColor: Colors.green,
          ),
        );
        await _carregarConfiguracoes();
      }
    } catch (e) {
      setState(() => _carregando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.erroSalvar(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_acessoLiberado) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.acessoFerramentasBancoTitulo),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        size: 56,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.informeCredenciaisContinuar,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _usuarioAcessoController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: AppStrings.usuarioLabel,
                          hintText: _usuarioAcessoEsperado,
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppStrings.usuarioConfiguradoAcesso(
                            _usuarioAcessoEsperado,
                          ),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _senhaAcessoController,
                        obscureText: true,
                        onSubmitted: (_) =>
                            _validandoAcesso ? null : _liberarAcesso(),
                        decoration: InputDecoration(
                          labelText: AppStrings.senhaLabel,
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () async {
                            setState(() {
                              _lembrarCredenciais = !_lembrarCredenciais;
                            });

                            if (!_lembrarCredenciais) {
                              await _persistirPreferenciaCredenciais();
                            }
                          },
                          icon: Icon(
                            _lembrarCredenciais
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 18,
                          ),
                          label: Text(AppStrings.lembrarMinhasCredenciais),
                        ),
                      ),
                      if (_erroAcesso != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Text(
                            _erroAcesso!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _validandoAcesso ? null : _liberarAcesso,
                          icon: _validandoAcesso
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: Text(AppStrings.entrarBtn),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.ferramentasDatabaseSetup),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (!_carregando)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _carregarConfiguracoes,
              tooltip: AppStrings.recarregar,
            ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSecaoTitulo(
                    '📋 ${AppStrings.secaoConfiguracoesGerais}',
                  ),
                  _buildCard([
                    _buildCampoEditavel(
                      AppStrings.whatsappAdminCampo,
                      _whatsappController,
                      Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildCampoEditavel(
                      AppStrings.precoSessaoCampo,
                      _precoSessaoController,
                      Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                    _buildCampoEditavel(
                      AppStrings.horasAntecedenciaCancelamentoCampo,
                      _horasAntecedenciaController,
                      Icons.schedule,
                      keyboardType: TextInputType.number,
                    ),
                    const Divider(height: 32),
                    _buildCampoNaoEditavel(
                      AppStrings.horarioPadraoInicioCampo,
                      _configGeral['horario_padrao_inicio'] ?? '',
                      Icons.access_time,
                    ),
                    _buildCampoNaoEditavel(
                      AppStrings.horarioPadraoFimCampo,
                      _configGeral['horario_padrao_fim'] ?? '',
                      Icons.access_time_filled,
                    ),
                    _buildCampoNaoEditavel(
                      AppStrings.intervaloAgendamentosMinCampo,
                      (_configGeral['intervalo_agendamentos_minutos'] ?? 0)
                          .toString(),
                      Icons.timer,
                    ),
                    _buildCampoNaoEditavel(
                      AppStrings.inicioSonoHoraCampo,
                      (_configGeral['inicio_sono'] ?? 22).toString(),
                      Icons.bedtime,
                    ),
                    _buildCampoNaoEditavel(
                      AppStrings.fimSonoHoraCampo,
                      (_configGeral['fim_sono'] ?? 6).toString(),
                      Icons.wb_sunny,
                    ),
                    _buildCampoBoolNaoEditavel(
                      AppStrings.biometriaAtivaCampo,
                      _configGeral['biometria_ativa'] ?? true,
                      Icons.fingerprint,
                    ),
                    _buildCampoBoolNaoEditavel(
                      AppStrings.configChatAtivo,
                      _configGeral['chat_ativo'] ?? true,
                      Icons.chat,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSecaoTitulo(
                    '🔒 ${AppStrings.secaoConfiguracoesSeguranca}',
                  ),
                  _buildCard([
                    _buildCampoNaoEditavel(
                      AppStrings.tentativasLoginMaxCampo,
                      (_configSeguranca['tentativas_login_max'] ?? 3)
                          .toString(),
                      Icons.lock_clock,
                    ),
                    _buildCampoNaoEditavel(
                      AppStrings.tempoBloqueioMinCampo,
                      (_configSeguranca['tempo_bloqueio_minutos'] ?? 15)
                          .toString(),
                      Icons.block,
                    ),
                    _buildCampoSensivelNaoEditavel(
                      AppStrings.senhaAdminFerramentasCampo,
                      _configSeguranca['senha_admin_ferramentas'] ?? '',
                      Icons.vpn_key,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSecaoTitulo(
                    '💆 ${AppStrings.secaoConfiguracoesServicos}',
                  ),
                  _buildCard([
                    _buildCampoListaNaoEditavel(
                      AppStrings.tiposMassagemCampo,
                      MassageTypeCatalog.normalizeIds(
                            List<String>.from(
                              _configServicos['tipos_massagem_ids'] ??
                                  _configServicos['tipos_massagem'] ??
                                  [],
                            ),
                          )
                          .map(
                            (tipoId) => MassageTypeCatalog.localize(
                              AppLocalizations.of(context)!,
                              tipoId,
                            ),
                          )
                          .toList(),
                      Icons.spa,
                    ),
                    _buildCampoNaoEditavel(
                      AppStrings.duracaoPadraoMinCampo,
                      (_configServicos['duracao_padrao_minutos'] ?? 60)
                          .toString(),
                      Icons.hourglass_empty,
                    ),
                    _buildCampoNaoEditavel(
                      AppStrings.precoPadraoCampo,
                      (_configServicos['preco_padrao'] ?? 150.0).toString(),
                      Icons.money,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSecaoTitulo(
                    '🔔 ${AppStrings.secaoConfiguracoesNotificacoes}',
                  ),
                  _buildCard([
                    _buildCampoNaoEditavel(
                      AppStrings.lembreteAntecedenciaHorasCampo,
                      (_configNotificacoes['lembrete_antecedencia_horas'] ?? 24)
                          .toString(),
                      Icons.notifications_active,
                    ),
                    _buildCampoBoolNaoEditavel(
                      AppStrings.enviarConfirmacaoCampo,
                      _configNotificacoes['enviar_confirmacao_agendamento'] ??
                          true,
                      Icons.check_circle,
                    ),
                    _buildCampoBoolNaoEditavel(
                      AppStrings.lembreteAutomaticoCampo,
                      _configNotificacoes['enviar_lembrete_automatico'] ?? true,
                      Icons.alarm,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSecaoTitulo(
                    '💳 ${AppStrings.secaoConfiguracoesPagamento}',
                  ),
                  _buildCard([
                    _buildCampoBoolNaoEditavel(
                      AppStrings.aceitaPixCampo,
                      _configPagamento['aceita_pix'] ?? true,
                      Icons.qr_code,
                    ),
                    _buildCampoBoolNaoEditavel(
                      AppStrings.aceitaDinheiroCampo,
                      _configPagamento['aceita_dinheiro'] ?? true,
                      Icons.money,
                    ),
                    _buildCampoBoolNaoEditavel(
                      AppStrings.aceitaCartaoCampo,
                      _configPagamento['aceita_cartao'] ?? true,
                      Icons.credit_card,
                    ),
                    _buildCampoNaoEditavel(
                      AppStrings.taxaCancelamentoPercentCampo,
                      (_configPagamento['taxa_cancelamento_percent'] ?? 50)
                          .toString(),
                      Icons.percent,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSecaoTitulo('⚙️ ${AppStrings.secaoVariaveisAmbiente}'),
                  _buildCard([
                    _buildCampoEnvNaoEditavel('DB_ADMIN_PASSWORD'),
                    _buildCampoEnvNaoEditavel('ADMIN_EMAIL'),
                    _buildCampoEnvNaoEditavel(
                      'PUSH_NOTIFICATION_FUNCTION_NAME',
                    ),
                    _buildCampoEnvNaoEditavel('RANDOM_MESSAGES_FUNCTION_NAME'),
                    _buildCampoEnvNaoEditavel('RECAPTCHA_SITE_KEY'),
                    _buildCampoEnvNaoEditavel('VAPID_KEY'),
                  ]),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _carregando
                          ? null
                          : _conferirECriarRegistrosFaltantes,
                      icon: const Icon(Icons.fact_check),
                      label: Text(AppStrings.conferirCriarRegistrosFaltantes),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _carregando ? null : _salvarAlteracoes,
                      icon: const Icon(Icons.save),
                      label: Text(AppStrings.salvarAlteracoes),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_registrosConferencia.isNotEmpty) ...[
                    _buildSecaoTitulo(
                      '🧾 ${AppStrings.secaoRegistrosConferidosCriados}',
                    ),
                    _buildCard([
                      ..._registrosConferencia.reversed.map(
                        (registro) => _buildRegistroConferencia(registro),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildRegistroConferencia(_RegistroConferencia registro) {
    final cor = switch (registro.status) {
      'criado' => Colors.green,
      'atualizado' => Colors.orange,
      _ => Colors.blueGrey,
    };
    final icone = switch (registro.status) {
      'criado' => Icons.add_circle,
      'atualizado' => Icons.playlist_add_check_circle,
      _ => Icons.verified,
    };
    final statusLabel = switch (registro.status) {
      'criado' => AppStrings.statusCriado,
      'atualizado' => AppStrings.statusAtualizado,
      _ => AppStrings.statusConferido,
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$statusLabel - ${registro.caminho}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(registro.detalhes),
                const SizedBox(height: 4),
                Text(
                  '${registro.horario.hour.toString().padLeft(2, '0')}:${registro.horario.minute.toString().padLeft(2, '0')}:${registro.horario.second.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildCampoEditavel(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.green, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildCampoNaoEditavel(String label, String valor, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: TextEditingController(text: valor),
        enabled: false,
        style: const TextStyle(color: Colors.grey),
        decoration: InputDecoration(
          labelText: AppStrings.rotuloFixo(label),
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildCampoBoolNaoEditavel(String label, bool valor, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.rotuloFixo(label),
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: valor ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: valor ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Text(
              valor ? AppStrings.valorAtivo : AppStrings.valorInativo,
              style: TextStyle(
                color: valor ? Colors.green[900] : Colors.red[900],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoListaNaoEditavel(
    String label,
    List<String> valores,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey),
              const SizedBox(width: 12),
              Text(
                AppStrings.rotuloFixo(label),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey, width: 1),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: valores
                  .map(
                    (v) =>
                        Chip(label: Text(v), backgroundColor: Colors.grey[200]),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoSensivelNaoEditavel(
    String label,
    String valor,
    IconData icon,
  ) {
    final mascarado = valor.isEmpty
        ? AppStrings.naoConfiguradaComParenteses
        : '••••••••';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: TextEditingController(text: mascarado),
        enabled: false,
        style: const TextStyle(color: Colors.grey),
        decoration: InputDecoration(
          labelText: AppStrings.rotuloFixo(label),
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: const Icon(Icons.visibility_off, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildCampoEnvNaoEditavel(String chave) {
    final valor = dotenv.env[chave];
    final mascarado = valor == null || valor.isEmpty
        ? AppStrings.naoConfiguradaComParenteses
        : '${valor.substring(0, valor.length > 4 ? 4 : valor.length)}••••';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: TextEditingController(text: mascarado),
        enabled: false,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
        decoration: InputDecoration(
          labelText: AppStrings.rotuloAmbiente(chave),
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
          prefixIcon: const Icon(Icons.code, color: Colors.grey, size: 20),
          suffixIcon: const Icon(Icons.lock, color: Colors.grey, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
