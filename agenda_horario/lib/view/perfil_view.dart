import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Necessário para File
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // Adicionar ao pubspec.yaml
import 'package:firebase_storage/firebase_storage.dart'; // Adicionar ao pubspec.yaml
import 'package:intl/intl.dart';
import '../controller/firestore_service.dart';
import '../controller/cliente_model.dart';
import '../controller/config_model.dart';
import '../controller/agendamento_model.dart';
import 'login_view.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  // Controllers
  final _nomeController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cepController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _historicoController = TextEditingController();
  final _alergiasController = TextEditingController();
  final _medicamentosController = TextEditingController();
  final _cirurgiasController = TextEditingController();
  DateTime? _dataNascimento;

  File? _imagemLocal;
  String? _urlImagemRemota;
  ConfigModel? _config;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    if (_user == null) return;

    // Carregar Configuração e Dados do Cliente em paralelo
    final results = await Future.wait([
      _firestoreService.getConfiguracao(),
      _firestoreService.getCliente(_user.uid),
      _firestoreService.getUsuario(_user.uid), // Fallback para nome/email
    ]);

    _config = results[0] as ConfigModel;
    final cliente = results[1] as Cliente?;
    final usuario = results[2]; // UsuarioModel

    if (cliente != null) {
      _nomeController.text = cliente.nome;
      _whatsappController.text = cliente.whatsapp;
      // Assumindo que você adicionará 'cpf' e 'fotoUrl' ao seu ClienteModel
      // _cpfController.text = cliente.cpf ?? '';
      // _urlImagemRemota = cliente.fotoUrl;
      _enderecoController.text = cliente.endereco;
      _historicoController.text = cliente.historicoMedico;
      _alergiasController.text = cliente.alergias;
      _medicamentosController.text = cliente.medicamentos;
      _cirurgiasController.text = cliente.cirurgias;
      _dataNascimento = cliente.dataNascimento;
    } else if (usuario != null) {
      // Preencher dados básicos se o cliente ainda não existir na coleção 'clientes'
      // (mas existir em 'usuarios')
      _nomeController.text = (usuario as dynamic).nome;
    }

    setState(() {
      _isLoading = false;
    });
  }

  bool _isObrigatorio(String key) {
    return _config?.camposObrigatorios[key] ?? false;
  }

  String? _validar(String key, String? value) {
    if (_isObrigatorio(key) && (value == null || value.trim().isEmpty)) {
      return 'Este campo é obrigatório';
    }
    return null;
  }

  // Algoritmo de validação de CPF
  String? _validarCpf(String? value) {
    if (value == null || value.isEmpty) return _isObrigatorio('cpf') ? 'CPF obrigatório' : null;
    
    final cpf = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.isEmpty && !_isObrigatorio('cpf')) return null;
    if (cpf.length != 11) return 'CPF deve ter 11 dígitos';
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return 'CPF inválido';

    List<int> numbers = cpf.split('').map(int.parse).toList();
    int sum = 0;
    for (int i = 0; i < 9; i++) sum += numbers[i] * (10 - i);
    int digit1 = 11 - (sum % 11);
    if (digit1 >= 10) digit1 = 0;
    if (numbers[9] != digit1) return 'CPF inválido';

    sum = 0;
    for (int i = 0; i < 10; i++) sum += numbers[i] * (11 - i);
    int digit2 = 11 - (sum % 11);
    if (digit2 >= 10) digit2 = 0;
    if (numbers[10] != digit2) return 'CPF inválido';

    return null;
  }

  String? _validarCep(String? value) {
    if (value == null || value.isEmpty) return null; // Opcional se não for obrigatório
    final cep = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) return 'CEP inválido';
    return null;
  }

  Future<void> _buscarCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite um CEP válido com 8 números.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cep/json/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('erro')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CEP não encontrado. Por favor, digite o endereço manualmente.')),
            );
            // Não limpamos o campo de endereço para permitir que o usuário digite
            _enderecoController.clear(); 
          }
        } else {
          _enderecoController.text = '${data['logradouro']}, ${data['bairro']}, ${data['localidade']} - ${data['uf']}';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao buscar CEP. Verifique sua conexão ou digite manualmente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selecionarImagem() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      setState(() {
        _imagemLocal = File(image.path);
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isObrigatorio('data_nascimento') && _dataNascimento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe a Data de Nascimento.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Upload da imagem se houver nova seleção
    String? urlFinal = _urlImagemRemota;
    if (_imagemLocal != null) {
      try {
        final ref = FirebaseStorage.instance.ref().child('perfis/${_user!.uid}.jpg');
        await ref.putFile(_imagemLocal!);
        urlFinal = await ref.getDownloadURL();
      } catch (e) {
        debugPrint('Erro ao fazer upload da imagem: $e');
      }
    }

    final cliente = Cliente(
      uid: _user!.uid,
      nome: _nomeController.text,
      whatsapp: _whatsappController.text,
      // cpf: _cpfController.text, // Adicione este campo ao ClienteModel
      // fotoUrl: urlFinal,        // Adicione este campo ao ClienteModel
      endereco: _enderecoController.text,
      dataNascimento: _dataNascimento,
      historicoMedico: _historicoController.text,
      alergias: _alergiasController.text,
      medicamentos: _medicamentosController.text,
      cirurgias: _cirurgiasController.text,
      anamneseOk: true, // Marca como preenchido
    );

    await _firestoreService.salvarCliente(cliente);

    if (mounted) setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _excluirConta() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Conta e Dados?'),
        content: const Text(
            'Atenção: Esta ação excluirá permanentemente sua conta, histórico e agendamentos (LGPD). Não é possível desfazer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir Tudo'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted && _user != null) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.excluirConta(_user.uid); // Apaga do Firestore
        await _user.delete(); // Apaga do Authentication

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sua conta foi excluída com sucesso.')));
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginView()), (route) => false);
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir (faça login novamente): $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meu Perfil'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.save), onPressed: _salvar),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Dados'),
              Tab(icon: Icon(Icons.history), text: 'Histórico'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDadosTab(),
            _buildHistoricoTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDadosTab() {
    return Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Dados Pessoais', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 10),
            
            // Área da Foto de Perfil
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _imagemLocal != null 
                        ? FileImage(_imagemLocal!) 
                        : (_urlImagemRemota != null ? NetworkImage(_urlImagemRemota!) : null) as ImageProvider?,
                    child: (_imagemLocal == null && _urlImagemRemota == null) 
                        ? const Icon(Icons.person, size: 50, color: Colors.grey) 
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.teal,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        onPressed: _selecionarImagem,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Nome é obrigatório' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _cpfController,
              decoration: InputDecoration(
                labelText: 'CPF ${_isObrigatorio('cpf') ? '*' : ''}',
                border: const OutlineInputBorder(),
                hintText: '000.000.000-00',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CpfInputFormatter(),
              ],
              validator: _validarCpf,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _whatsappController,
              decoration: InputDecoration(
                labelText: 'WhatsApp ${_isObrigatorio('whatsapp') ? '*' : ''}',
                border: const OutlineInputBorder(),
              ),
              validator: (v) => _validar('whatsapp', v),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TelefoneInputFormatter(),
              ],
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cepController,
                    decoration: const InputDecoration(labelText: 'CEP', border: OutlineInputBorder(), hintText: '00000-000'),
                    keyboardType: TextInputType.number,
                    validator: _validarCep,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                  ),
                ),
                IconButton(icon: const Icon(Icons.search), onPressed: _buscarCep, tooltip: 'Buscar Endereço'),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _enderecoController,
              decoration: InputDecoration(
                labelText: 'Endereço ${_isObrigatorio('endereco') ? '*' : ''}',
                border: const OutlineInputBorder(),
              ),
              validator: (v) => _validar('endereco', v),
            ),
            const SizedBox(height: 10),
            ListTile(
              title: Text(_dataNascimento == null 
                  ? 'Data de Nascimento ${_isObrigatorio('data_nascimento') ? '*' : ''}' 
                  : 'Nascimento: ${DateFormat('dd/MM/yyyy').format(_dataNascimento)}'),
              trailing: const Icon(Icons.calendar_today),
              shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dataNascimento ?? DateTime(1990),
                  firstDate: DateTime(1920),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _dataNascimento = picked);
              },
            ),
            const SizedBox(height: 20),
            const Text('Ficha de Anamnese', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 10),
            _buildAnamneseField('Histórico Médico', 'historico_medico', _historicoController),
            _buildAnamneseField('Alergias', 'alergias', _alergiasController),
            _buildAnamneseField('Medicamentos em uso', 'medicamentos', _medicamentosController),
            _buildAnamneseField('Cirurgias Recentes', 'cirurgias', _cirurgiasController),
            
            const SizedBox(height: 30),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: TextButton.icon(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text('Excluir minha conta e dados (LGPD)', style: TextStyle(color: Colors.red)),
                onPressed: _excluirConta,
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildHistoricoTab() {
    if (_user == null) return const Center(child: Text('Usuário não identificado'));

    return StreamBuilder<List<Agendamento>>(
      stream: _firestoreService.getAgendamentosDoCliente(_user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhum agendamento encontrado.'));
        }

        final agendamentos = snapshot.data!;
        
        return ListView.builder(
          itemCount: agendamentos.length,
          itemBuilder: (context, index) {
            final agendamento = agendamentos[index];
            final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(agendamento.dataHora);
            
            // Verifica se pode cancelar (não recusado/cancelado e data futura)
            final bool podeCancelar = agendamento.status != 'recusado' && 
                                      agendamento.status != 'cancelado' && 
                                      agendamento.status != 'cancelado_tardio' &&
                                      agendamento.dataHora.isAfter(DateTime.now());
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: _getIconStatus(agendamento.status),
                title: Text(dataFormatada),
                subtitle: Text('Status: ${agendamento.status.toUpperCase()}${agendamento.motivoCancelamento != null ? '\nMotivo: ${agendamento.motivoCancelamento}' : ''}'),
                isThreeLine: agendamento.motivoCancelamento != null,
                trailing: podeCancelar 
                    ? IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        tooltip: 'Cancelar Agendamento',
                        onPressed: () => _iniciarCancelamento(agendamento),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  // Lógica de Cancelamento (Similar à AgendamentoView)
  Future<void> _iniciarCancelamento(Agendamento agendamento) async {
    _config ??= await _firestoreService.getConfiguracao();
    
    final agora = DateTime.now();
    final dataAgendamento = agendamento.dataHora;

    // Cálculo de horas válidas (descontando sono configurado)
    int minutosValidos = 0;
    DateTime cursor = agora;
    
    while (cursor.isBefore(dataAgendamento)) {
      final hora = cursor.hour;
      bool dormindo = false;

      if (_config!.inicioSono < _config!.fimSono) {
        dormindo = hora >= _config!.inicioSono && hora < _config!.fimSono;
      } else {
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
      builder: (dialogContext) {
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
                    'Atenção: Você está cancelando com menos de $horasNecessarias horas úteis de antecedência.\nTempo útil restante: ${horasValidas.toStringAsFixed(1)}h.',
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
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Voltar')),
            ElevatedButton(
              onPressed: () async {
                if (motivoController.text.isEmpty) return;
                
                final status = foraDoPrazo ? 'cancelado_tardio' : 'cancelado';
                final motivoFinal = foraDoPrazo ? '[FORA DO PRAZO] ${motivoController.text}' : motivoController.text;

                await _firestoreService.cancelarAgendamento(agendamento.id!, motivoFinal, status);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Confirmar Cancelamento'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnamneseField(String label, String key, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: '$label ${_isObrigatorio(key) ? '*' : ''}',
          border: const OutlineInputBorder(),
        ),
        validator: (v) => _validar(key, v),
        maxLines: 2,
      ),
    );
  }

  Icon _getIconStatus(String status) {
    switch (status) {
      case 'aprovado': return const Icon(Icons.check_circle, color: Colors.green);
      case 'cancelado': return const Icon(Icons.cancel, color: Colors.red);
      case 'pendente': return const Icon(Icons.access_time, color: Colors.orange);
      default: return const Icon(Icons.info, color: Colors.grey);
    }
  }
}

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.length > 11) return oldValue;
    
    var newText = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) newText.write('.');
      if (i == 9) newText.write('-');
      newText.write(text[i]);
    }
    
    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.length > 11) return oldValue;

    var newText = StringBuffer();
    if (text.isNotEmpty) newText.write('(');
    for (int i = 0; i < text.length; i++) {
      if (i == 2) newText.write(') ');
      if (i == 7) newText.write('-');
      newText.write(text[i]);
    }

    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}