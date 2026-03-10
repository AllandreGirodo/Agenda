import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:agenda/core/services/firestore_service.dart';
import 'package:agenda/core/models/cliente_model.dart';
import 'package:agenda/core/models/config_model.dart';
import 'package:agenda/core/models/agendamento_model.dart';
import 'package:agenda/core/utils/validadores.dart';
import 'package:agenda/features/auth/view/login_view.dart';
import 'package:agenda/core/utils/app_strings.dart';
import 'package:agenda/core/widgets/language_selector.dart';

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

  XFile? _imagemLocal;
  Uint8List? _imagemBytes;
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

    final results = await Future.wait([
      _firestoreService.getConfiguracao(),
      _firestoreService.getCliente(_user.uid),
      _firestoreService.getUsuario(_user.uid),
    ]);

    _config = results[0] as ConfigModel;
    final cliente = results[1] as Cliente?;
    final usuario = results[2];

    if (cliente != null) {
      _nomeController.text = cliente.nome;
      _whatsappController.text = cliente.whatsapp;
      _enderecoController.text = cliente.endereco;
      _historicoController.text = cliente.historicoMedico;
      _alergiasController.text = cliente.alergias;
      _medicamentosController.text = cliente.medicamentos;
      _cirurgiasController.text = cliente.cirurgias;
      _dataNascimento = cliente.dataNascimento;
    } else if (usuario != null) {
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
      return AppStrings.requiredField;
    }
    return null;
  }

  String? _validarCpf(String? value) {
    return Validadores.validarCpf(value, obrigatorio: _isObrigatorio('cpf'));
  }

  String? _validarCep(String? value) {
    if (value == null || value.isEmpty) return null;
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
      final bytes = await image.readAsBytes();
      setState(() {
        _imagemLocal = image;
        _imagemBytes = bytes;
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

    if (_imagemLocal != null) {
      try {
        final ref = FirebaseStorage.instance.ref().child('perfis/${_user!.uid}.jpg');
        await ref.putData(_imagemBytes!);
        _urlImagemRemota = await ref.getDownloadURL();
      } catch (e) {
        debugPrint('Erro ao fazer upload da imagem: $e');
      }
    }

    final cliente = Cliente(
      idCliente: _user!.uid,
      nomeCliente: _nomeController.text,
      whatsappCliente: _whatsappController.text,
      enderecoCliente: _enderecoController.text,
      dataNascimentoCliente: _dataNascimento,
      historicoMedicoCliente: _historicoController.text,
      alergiasCliente: _alergiasController.text,
      medicamentosCliente: _medicamentosController.text,
      cirurgiasCliente: _cirurgiasController.text,
      anamneseOkCliente: true,
    );

    await _firestoreService.salvarCliente(cliente);

    if (mounted) setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.profileUpdatedSuccess)),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _excluirConta() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.deleteAccountDialogTitle),
        content: Text(AppStrings.deleteAccountDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancelButton),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.deleteEverythingButton),
          ),
        ],
      ),
    );

    if (confirm == true && mounted && _user != null) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.anonimizarConta(_user.uid);
        await _user.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.accountDeletedSuccess)));
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginView()), (route) => false);
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) setState(() => _isLoading = false);
        if (e.code == 'requires-recent-login') {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por segurança, faça login novamente para excluir a conta.')));
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.message}')));
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
          title: Text(AppStrings.profileTitle),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [
            const LanguageSelector(),
            IconButton(icon: const Icon(Icons.save), onPressed: _salvar, tooltip: AppStrings.saveButton),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(icon: Icon(Icons.person), text: AppStrings.dataTab),
              Tab(icon: Icon(Icons.history), text: AppStrings.historyTab),
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
            Text(AppStrings.personalDataTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 10),
            
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _imagemBytes != null 
                        ? MemoryImage(_imagemBytes!) 
                        : (_urlImagemRemota != null ? NetworkImage(_urlImagemRemota!) : null) as ImageProvider?,
                    child: (_imagemBytes == null && _urlImagemRemota == null) ? const Icon(Icons.person, size: 50) : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.orange,
                      radius: 18,
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
              decoration: const InputDecoration(labelText: 'Nome Completo', prefixIcon: Icon(Icons.person)),
              validator: (v) => _validar('nome', v),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _whatsappController,
              decoration: const InputDecoration(labelText: 'WhatsApp', prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone,
              validator: (v) => _validar('whatsapp', v),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _cpfController,
              decoration: const InputDecoration(labelText: 'CPF', prefixIcon: Icon(Icons.badge)),
              keyboardType: TextInputType.number,
              validator: _validarCpf,
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text('Data de Nascimento'),
              subtitle: Text(_dataNascimento == null ? 'Não informada' : DateFormat('dd/MM/yyyy').format(_dataNascimento!)),
              leading: const Icon(Icons.calendar_today),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dataNascimento ?? DateTime(2000),
                  firstDate: DateTime(1920),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _dataNascimento = date);
              },
            ),
            const SizedBox(height: 20),
            const Text('Endereço', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cepController,
                    decoration: const InputDecoration(labelText: 'CEP', prefixIcon: Icon(Icons.location_on)),
                    keyboardType: TextInputType.number,
                    validator: _validarCep,
                  ),
                ),
                IconButton(icon: const Icon(Icons.search), onPressed: _buscarCep),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _enderecoController,
              decoration: const InputDecoration(labelText: 'Endereço Completo'),
              maxLines: 2,
              validator: (v) => _validar('endereco', v),
            ),
            const SizedBox(height: 20),
            const Text('Anamnese / Saúde', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _historicoController,
              decoration: const InputDecoration(labelText: 'Histórico Médico / Observações'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _alergiasController,
              decoration: const InputDecoration(labelText: 'Alergias'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _medicamentosController,
              decoration: const InputDecoration(labelText: 'Medicamentos em uso'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _cirurgiasController,
              decoration: const InputDecoration(labelText: 'Cirurgias recentes'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _salvar,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
              child: const Text('SALVAR PERFIL'),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _excluirConta,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('EXCLUIR MINHA CONTA', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
    );
  }

  Widget _buildHistoricoTab() {
    return StreamBuilder<List<Agendamento>>(
      stream: _firestoreService.getAgendamentosDoCliente(_user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final agendamentos = snapshot.data ?? [];
        if (agendamentos.isEmpty) return const Center(child: Text('Nenhum agendamento encontrado.'));

        return ListView.builder(
          itemCount: agendamentos.length,
          itemBuilder: (context, index) {
            final a = agendamentos[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(a.tipo),
                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(a.dataHora)),
                trailing: Text(a.status.toUpperCase(), style: TextStyle(color: a.status == 'aprovado' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }
}
