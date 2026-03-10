import 'package:flutter/material.dart';
import 'package:agenda/core/services/firestore_service.dart';
import 'package:agenda/core/models/firestore_structure_helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  final FirestoreService _firestoreService = FirestoreService();
  final FirestoreStructureHelper _structureHelper = FirestoreStructureHelper();

  bool _carregando = true;
  Map<String, dynamic> _configGeral = {};
  Map<String, dynamic> _configSeguranca = {};
  Map<String, dynamic> _configServicos = {};
  Map<String, dynamic> _configNotificacoes = {};
  Map<String, dynamic> _configPagamento = {};

  // Controllers para campos editáveis
  final _whatsappController = TextEditingController();
  final _precoSessaoController = TextEditingController();
  final _horasAntecedenciaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarConfiguracoes();
  }

  @override
  void dispose() {
    _whatsappController.dispose();
    _precoSessaoController.dispose();
    _horasAntecedenciaController.dispose();
    super.dispose();
  }

  Future<void> _carregarConfiguracoes() async {
    setState(() => _carregando = true);

    try {
      // Garante que a estrutura existe
      await _structureHelper.inicializarEstruturaConfiguracoes();

      // Carrega configurações
      _configGeral = await _structureHelper.getOrCreateDocument(
        'configuracoes/geral',
        FirestoreStructureHelper.getConfigGeralPadrao(),
      );

      _configSeguranca = await _structureHelper.getOrCreateDocument(
        'configuracoes/seguranca',
        FirestoreStructureHelper.getConfigSegurancaPadrao(),
      );

      _configServicos = await _structureHelper.getOrCreateDocument(
        'configuracoes/servicos',
        FirestoreStructureHelper.getConfigServicosPadrao(),
      );

      _configNotificacoes = await _structureHelper.getOrCreateDocument(
        'configuracoes/notificacoes',
        FirestoreStructureHelper.getConfigNotificacoesPadrao(),
      );

      _configPagamento = await _structureHelper.getOrCreateDocument(
        'configuracoes/pagamento',
        FirestoreStructureHelper.getConfigPagamentoPadrao(),
      );

      // Preenche controllers
      _whatsappController.text = _configGeral['whatsapp_admin'] ?? '';
      _precoSessaoController.text = (_configGeral['preco_sessao'] ?? 0.0).toString();
      _horasAntecedenciaController.text =
          (_configGeral['horas_antecedencia_cancelamento'] ?? 0.0).toString();

      setState(() => _carregando = false);
    } catch (e) {
      setState(() => _carregando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar: $e')),
        );
      }
    }
  }

  Future<void> _salvarAlteracoes() async {
    try {
      setState(() => _carregando = true);

      // Salva campos editáveis
      await _firestoreService.salvarTelefoneAdmin(_whatsappController.text);
      
      // Atualiza outros campos editáveis
      await _structureHelper.ensureDocumentExists('configuracoes/geral', {
        ..._configGeral,
        'whatsapp_admin': _whatsappController.text,
        'preco_sessao': double.tryParse(_precoSessaoController.text) ?? 100.0,
        'horas_antecedencia_cancelamento':
            double.tryParse(_horasAntecedenciaController.text) ?? 24.0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alterações salvas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        await _carregarConfiguracoes();
      }
    } catch (e) {
      setState(() => _carregando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ferramentas - Database Setup'),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (!_carregando)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _carregarConfiguracoes,
              tooltip: 'Recarregar',
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
                  _buildSecaoTitulo('📋 Configurações Gerais'),
                  _buildCard([
                    _buildCampoEditavel(
                      'WhatsApp Admin',
                      _whatsappController,
                      Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildCampoEditavel(
                      'Preço Sessão (R\$)',
                      _precoSessaoController,
                      Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                    _buildCampoEditavel(
                      'Horas Antecedência Cancelamento',
                      _horasAntecedenciaController,
                      Icons.schedule,
                      keyboardType: TextInputType.number,
                    ),
                    const Divider(height: 32),
                    _buildCampoNaoEditavel(
                      'Horário Padrão Início',
                      _configGeral['horario_padrao_inicio'] ?? '',
                      Icons.access_time,
                    ),
                    _buildCampoNaoEditavel(
                      'Horário Padrão Fim',
                      _configGeral['horario_padrao_fim'] ?? '',
                      Icons.access_time_filled,
                    ),
                    _buildCampoNaoEditavel(
                      'Intervalo Agendamentos (min)',
                      (_configGeral['intervalo_agendamentos_minutos'] ?? 0).toString(),
                      Icons.timer,
                    ),
                    _buildCampoNaoEditavel(
                      'Início Sono (hora)',
                      (_configGeral['inicio_sono'] ?? 22).toString(),
                      Icons.bedtime,
                    ),
                    _buildCampoNaoEditavel(
                      'Fim Sono (hora)',
                      (_configGeral['fim_sono'] ?? 6).toString(),
                      Icons.wb_sunny,
                    ),
                    _buildCampoBoolNaoEditavel(
                      'Biometria Ativa',
                      _configGeral['biometria_ativa'] ?? true,
                      Icons.fingerprint,
                    ),
                    _buildCampoBoolNaoEditavel(
                      'Chat Ativo',
                      _configGeral['chat_ativo'] ?? true,
                      Icons.chat,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSecaoTitulo('🔒 Configurações de Segurança'),
                  _buildCard([
                    _buildCampoNaoEditavel(
                      'Tentativas Login Máx',
                      (_configSeguranca['tentativas_login_max'] ?? 3).toString(),
                      Icons.lock_clock,
                    ),
                    _buildCampoNaoEditavel(
                      'Tempo Bloqueio (min)',
                      (_configSeguranca['tempo_bloqueio_minutos'] ?? 15).toString(),
                      Icons.block,
                    ),
                    _buildCampoSensivelNaoEditavel(
                      'Senha Admin Ferramentas',
                      _configSeguranca['senha_admin_ferramentas'] ?? '',
                      Icons.vpn_key,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSecaoTitulo('💆 Configurações de Serviços'),
                  _buildCard([
                    _buildCampoListaNaoEditavel(
                      'Tipos de Massagem',
                      List<String>.from(_configServicos['tipos_massagem'] ?? []),
                      Icons.spa,
                    ),
                    _buildCampoNaoEditavel(
                      'Duração Padrão (min)',
                      (_configServicos['duracao_padrao_minutos'] ?? 60).toString(),
                      Icons.hourglass_empty,
                    ),
                    _buildCampoNaoEditavel(
                      'Preço Padrão (R\$)',
                      (_configServicos['preco_padrao'] ?? 150.0).toString(),
                      Icons.money,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSecaoTitulo('🔔 Configurações de Notificações'),
                  _buildCard([
                    _buildCampoNaoEditavel(
                      'Lembrete Antecedência (h)',
                      (_configNotificacoes['lembrete_antecedencia_horas'] ?? 24).toString(),
                      Icons.notifications_active,
                    ),
                    _buildCampoBoolNaoEditavel(
                      'Enviar Confirmação',
                      _configNotificacoes['enviar_confirmacao_agendamento'] ?? true,
                      Icons.check_circle,
                    ),
                    _buildCampoBoolNaoEditavel(
                      'Lembrete Automático',
                      _configNotificacoes['enviar_lembrete_automatico'] ?? true,
                      Icons.alarm,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSecaoTitulo('💳 Configurações de Pagamento'),
                  _buildCard([
                    _buildCampoBoolNaoEditavel(
                      'Aceita PIX',
                      _configPagamento['aceita_pix'] ?? true,
                      Icons.qr_code,
                    ),
                    _buildCampoBoolNaoEditavel(
                      'Aceita Dinheiro',
                      _configPagamento['aceita_dinheiro'] ?? true,
                      Icons.money,
                    ),
                    _buildCampoBoolNaoEditavel(
                      'Aceita Cartão',
                      _configPagamento['aceita_cartao'] ?? true,
                      Icons.credit_card,
                    ),
                    _buildCampoNaoEditavel(
                      'Taxa Cancelamento (%)',
                      (_configPagamento['taxa_cancelamento_percent'] ?? 50).toString(),
                      Icons.percent,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSecaoTitulo('⚙️ Variáveis de Ambiente (.env)'),
                  _buildCard([
                    _buildCampoEnvNaoEditavel('DB_ADMIN_PASSWORD'),
                    _buildCampoEnvNaoEditavel('ADMIN_EMAIL'),
                    _buildCampoEnvNaoEditavel('FCM_SERVER_KEY'),
                    _buildCampoEnvNaoEditavel('RECAPTCHA_SITE_KEY'),
                    _buildCampoEnvNaoEditavel('VAPID_KEY'),
                  ]),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _carregando ? null : _salvarAlteracoes,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar Alterações'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
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
          labelText: '$label (fixo)',
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
              '$label (fixo)',
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
              valor ? 'ATIVO' : 'INATIVO',
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
                '$label (fixo)',
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
                  .map((v) => Chip(
                        label: Text(v),
                        backgroundColor: Colors.grey[200],
                      ))
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
    final mascarado = valor.isEmpty ? '(não configurada)' : '••••••••';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: TextEditingController(text: mascarado),
        enabled: false,
        style: const TextStyle(color: Colors.grey),
        decoration: InputDecoration(
          labelText: '$label (fixo)',
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
        ? '(não configurada)'
        : '${valor.substring(0, valor.length > 4 ? 4 : valor.length)}••••';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: TextEditingController(text: mascarado),
        enabled: false,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
        decoration: InputDecoration(
          labelText: '$chave (ambiente)',
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
