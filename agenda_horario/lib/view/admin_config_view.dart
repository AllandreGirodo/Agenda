import 'package:flutter/material.dart';
import '../controller/firestore_service.dart';
import '../controller/config_model.dart';

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

  // Campos que não podem ser desmarcados pelo admin (Regra de Negócio/Segurança)
  final List<String> _camposCriticos = ['whatsapp', 'data_nascimento', 'termos_uso'];

  // Mapa de nomes amigáveis para exibição
  final Map<String, String> _labels = {
    'whatsapp': 'WhatsApp',
    'endereco': 'Endereço Completo',
    'data_nascimento': 'Data de Nascimento',
    'historico_medico': 'Histórico Médico',
    'alergias': 'Alergias',
    'medicamentos': 'Uso de Medicamentos',
    'cirurgias': 'Cirurgias Recentes',
    'termos_uso': 'Termos de Uso (Aceite Obrigatório)',
  };

  @override
  void initState() {
    super.initState();
    _carregarConfig();
  }

  Future<void> _carregarConfig() async {
    final config = await _firestoreService.getConfiguracao();
    setState(() {
      _campos = Map.from(config.camposObrigatorios);
      
      // Garante que campos críticos estejam marcados como TRUE, mesmo que venham false do banco
      for (var critico in _camposCriticos) {
        _campos[critico] = true;
      }

      _horasAntecedencia = config.horasAntecedenciaCancelamento;
      _inicioSono = config.inicioSono;
      _fimSono = config.fimSono;
      _precoSessao = config.precoSessao;
      _statusCampoCupom = config.statusCampoCupom;
      _isLoading = false;
    });
  }

  Future<void> _salvar() async {
    await _firestoreService.salvarConfiguracao(ConfigModel(
      camposObrigatorios: _campos,
      horasAntecedenciaCancelamento: _horasAntecedencia,
      inicioSono: _inicioSono,
      fimSono: _fimSono,
      precoSessao: _precoSessao,
      statusCampoCupom: _statusCampoCupom,
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração de Campos'),
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
                const Text('Financeiro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      initialValue: _precoSessao.toString(),
                      decoration: const InputDecoration(labelText: 'Preço da Sessão (R\$)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) => setState(() => _precoSessao = double.tryParse(val) ?? 0.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Regras de Cancelamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Antecedência mínima (horas): $_horasAntecedencia h'),
                        Slider(
                          value: _horasAntecedencia.toDouble(),
                          min: 0,
                          max: 72,
                          divisions: 72,
                          label: '$_horasAntecedencia h',
                          onChanged: (val) => setState(() => _horasAntecedencia = val.toInt()),
                        ),
                        const Divider(),
                        const Text('Horário de Sono da Administradora', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Text('Este intervalo não conta para o cálculo de antecedência.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _inicioSono,
                                decoration: const InputDecoration(labelText: 'Dorme às'),
                                items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('$i:00'))),
                                onChanged: (v) => setState(() => _inicioSono = v!),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _fimSono,
                                decoration: const InputDecoration(labelText: 'Acorda às'),
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
                const Text('Configuração de Cupons', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      RadioListTile<int>(
                        title: const Text('Ativo (Campo visível)'),
                        value: 1, groupValue: _statusCampoCupom, onChanged: (v) => setState(() => _statusCampoCupom = v!),
                      ),
                      RadioListTile<int>(
                        title: const Text('Oculto (Campo não aparece)'),
                        value: 2, groupValue: _statusCampoCupom, onChanged: (v) => setState(() => _statusCampoCupom = v!),
                      ),
                      RadioListTile<int>(
                        title: const Text('Opacidade (Visível mas inativo)'),
                        subtitle: const Text('Aparece com transparência e não clicável'),
                        value: 3, groupValue: _statusCampoCupom, onChanged: (v) => setState(() => _statusCampoCupom = v!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Marque os campos que devem ser OBRIGATÓRIOS para o cliente:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ..._labels.keys.map((key) {
                  final isCritico = _camposCriticos.contains(key);
                  return SwitchListTile(
                    title: Text(_labels[key]!),
                    subtitle: isCritico ? const Text('Campo crítico (Sempre obrigatório)', style: TextStyle(color: Colors.red, fontSize: 12)) : null,
                    value: _campos[key] ?? false,
                    onChanged: isCritico ? null : (val) => setState(() => _campos[key] = val),
                  );
                }),
              ],
            ),
    );
  }
}