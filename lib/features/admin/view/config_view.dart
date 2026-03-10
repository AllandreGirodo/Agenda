import 'package:flutter/material.dart';
import 'package:agenda/core/services/firestore_service.dart';
import 'package:agenda/core/models/config_model.dart';
import 'package:agenda/core/utils/app_strings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';

class AdminConfigView extends StatefulWidget {
  const AdminConfigView({super.key});

  @override
  State<AdminConfigView> createState() => _AdminConfigViewState();
}

class _AdminConfigViewState extends State<AdminConfigView> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, bool> _campos = {};
  int _horasAntecedencia = 24;
  int _inicioSono = 22;
  int _fimSono = 6;
  double _precoSessao = 100.0;
  int _statusCampoCupom = 1;
  bool _isLoading = true;
  bool _biometriaAtiva = true;
  bool _chatAtivo = true;
  bool _reciboLeitura = true;
  String _senhaAdminFerramentas = '';

  // Campos que não podem ser desmarcados pelo admin (Regra de Negócio/Segurança)
  final List<String> _camposCriticos = ['whatsapp', 'data_nascimento', 'termos_uso'];

  // Mapa de nomes amigáveis para exibição
  final Map<String, String> _labels = AppStrings.labelsConfig;

  @override
  void initState() {
    super.initState();
    _carregarConfig();
  }

  Future<void> _carregarConfig() async {
    final config = await _firestoreService.getConfiguracao();
    
    // Busca senha admin atual
    final senhaAtual = await _firestoreService.buscarSenhaAdminFerramentasAtual();
    
    setState(() {
      _campos = Map.from(config.camposObrigatorios);
      
      // Garante que campos críticos estejam marcados como TRUE, mesmo que venham false do banco
      for (var critico in _camposCriticos) {
        _campos[critico] = true;
      }

      _horasAntecedencia = config.horasAntecedenciaCancelamento.toInt();
      _inicioSono = config.inicioSono;
      _fimSono = config.fimSono;
      _precoSessao = config.precoSessao;
      _statusCampoCupom = config.statusCampoCupom;
      _biometriaAtiva = config.biometriaAtiva;
      _chatAtivo = config.chatAtivo;
      _reciboLeitura = config.reciboLeitura;
      _senhaAdminFerramentas = senhaAtual ?? '';
      _isLoading = false;
    });
    
    // Se algum valor estava vazio/padrão e veio do código, salva no banco
    await _garantirValoresPadrao(config);
  }
  
  Future<void> _garantirValoresPadrao(ConfigModel config) async {
    // Se a configuração estava vazia ou com valores default, força salvamento
    bool precisaSalvar = false;
    
    if (config.horasAntecedenciaCancelamento == 24 && 
        config.inicioSono == 22 && 
        config.fimSono == 6) {
      precisaSalvar = true;
    }
    
    if (precisaSalvar) {
      await _firestoreService.salvarConfiguracao(config);
    }
  }

  Future<void> _salvar() async {
    await _firestoreService.salvarConfiguracao(ConfigModel(
      camposObrigatorios: _campos,
      horasAntecedenciaCancelamento: _horasAntecedencia.toDouble(),
      inicioSono: _inicioSono,
      fimSono: _fimSono,
      precoSessao: _precoSessao,
      statusCampoCupom: _statusCampoCupom,
      biometriaAtiva: _biometriaAtiva,
      chatAtivo: _chatAtivo,
      reciboLeitura: _reciboLeitura,
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.configSalvaSucesso)),
      );
    }
  }

  Future<void> _exportarBackup() async {
    setState(() => _isLoading = true);
    try {
      final jsonStr = await _firestoreService.gerarBackupJson();
      // Salva temporariamente para compartilhar
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/backup_agenda_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);
      
      await Share.shareXFiles([XFile(file.path)], text: 'Backup Agenda Massoterapia');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao exportar: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importarBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);
        final file = File(result.files.single.path!);
        final jsonStr = await file.readAsString();
        await _firestoreService.restaurarBackupJson(jsonStr);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup restaurado com sucesso!')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao importar: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _configurarSenhaAdmin() async {
    final senhaController = TextEditingController();
    final confirmaSenhaController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_senhaAdminFerramentas.isEmpty ? 'Configurar Senha Admin' : 'Alterar Senha Admin'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nova Senha',
                  hintText: 'Mínimo 6 caracteres',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Senha obrigatória';
                  }
                  if (value.trim().length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmaSenhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirme a Senha',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != senhaController.text) {
                    return 'As senhas não coincidem';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  await _firestoreService.salvarSenhaAdminFerramentas(
                    senhaController.text.trim(),
                  );
                  setState(() => _senhaAdminFerramentas = senhaController.text.trim());
                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Senha salva com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao salvar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    senhaController.dispose();
    confirmaSenhaController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.configTitulo),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _salvar),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(AppStrings.configFinanceiro, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      initialValue: _precoSessao.toString(),
                      decoration: InputDecoration(labelText: AppStrings.configPrecoSessao),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) => setState(() => _precoSessao = double.tryParse(val) ?? 0.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(AppStrings.configRegrasCancelamento, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${AppStrings.configAntecedencia}: $_horasAntecedencia h'),
                        Slider(
                          value: _horasAntecedencia.toDouble(),
                          min: 0,
                          max: 72,
                          divisions: 72,
                          label: '$_horasAntecedencia h',
                          onChanged: (val) => setState(() => _horasAntecedencia = val.toInt()),
                        ),
                        const Divider(),
                        Text(AppStrings.configHorarioSono, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(AppStrings.configHorarioSonoDesc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _inicioSono,
                                decoration: InputDecoration(labelText: AppStrings.configDormeAs),
                                items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('$i:00'))),
                                onChanged: (v) => setState(() => _inicioSono = v!),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _fimSono,
                                decoration: InputDecoration(labelText: AppStrings.configAcordaAs),
                                items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('$i:00'))),
                                onChanged: (v) => setState(() => _fimSono = v!),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(AppStrings.configCupons, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      RadioListTile<int>(
                        title: Text(AppStrings.configCupomAtivo),
                        value: 1,
                        groupValue: _statusCampoCupom,
                        onChanged: (v) => setState(() => _statusCampoCupom = v!),
                      ),
                      RadioListTile<int>(
                        title: Text(AppStrings.configCupomOculto),
                        value: 2,
                        groupValue: _statusCampoCupom,
                        onChanged: (v) => setState(() => _statusCampoCupom = v!),
                      ),
                      RadioListTile<int>(
                        title: Text(AppStrings.configCupomOpaco),
                        subtitle: Text(AppStrings.configCupomOpacoDesc),
                        value: 3,
                        groupValue: _statusCampoCupom,
                        onChanged: (v) => setState(() => _statusCampoCupom = v!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Segurança - Senha Admin', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Senha de Acesso a DevTools',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Esta senha protege o acesso a ferramentas perigosas como DevTools.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _senhaAdminFerramentas.isEmpty 
                                    ? 'Não configurada' 
                                    : '••••••••',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _senhaAdminFerramentas.isEmpty 
                                      ? Colors.red 
                                      : Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: Icon(_senhaAdminFerramentas.isEmpty 
                                  ? Icons.add_circle 
                                  : Icons.edit),
                              label: Text(_senhaAdminFerramentas.isEmpty 
                                  ? 'Configurar' 
                                  : 'Alterar'),
                              onPressed: _configurarSenhaAdmin,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(AppStrings.configBiometria, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                SwitchListTile(
                  title: const Text('Ativar FaceID/TouchID'),
                  subtitle: Text(AppStrings.configBiometriaDesc),
                  value: _biometriaAtiva,
                  onChanged: (val) => setState(() => _biometriaAtiva = val),
                ),
                const SizedBox(height: 20),
                Text(AppStrings.configChat, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                SwitchListTile(
                  title: Text(AppStrings.configChatAtivo),
                  subtitle: Text(AppStrings.configChatDesc),
                  value: _chatAtivo,
                  onChanged: (val) => setState(() => _chatAtivo = val),
                ),
                SwitchListTile(
                  title: Text(AppStrings.configReciboLeitura),
                  subtitle: const Text('Exibir ícones de "Lido" nas mensagens'),
                  value: _reciboLeitura,
                  onChanged: (val) => setState(() => _reciboLeitura = val),
                ),
                const SizedBox(height: 20),
                Text(AppStrings.backupTitulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.download), label: Text(AppStrings.backupExportar), onPressed: _exportarBackup)),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.upload), label: Text(AppStrings.backupImportar), onPressed: _importarBackup)),
                  ],
                ),
                const SizedBox(height: 20),
                Text(AppStrings.configCamposObrigatorios, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ..._labels.keys.map((key) {
                  final isCritico = _camposCriticos.contains(key);
                  return SwitchListTile(
                    title: Text(_labels[key]!),
                    subtitle: isCritico ? Text(AppStrings.configCampoCritico, style: const TextStyle(color: Colors.red, fontSize: 12)) : null,
                    value: _campos[key] ?? false,
                    onChanged: isCritico ? null : (val) => setState(() => _campos[key] = val),
                  );
                }),
              ],
            ),
    );
  }
}
