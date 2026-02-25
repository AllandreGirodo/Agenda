import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../controller/firestore_service.dart';
import '../controller/cliente_model.dart';
import '../controller/config_model.dart';
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
  final _enderecoController = TextEditingController();
  final _historicoController = TextEditingController();
  final _alergiasController = TextEditingController();
  final _medicamentosController = TextEditingController();
  final _cirurgiasController = TextEditingController();
  DateTime? _dataNascimento;

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

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isObrigatorio('data_nascimento') && _dataNascimento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe a Data de Nascimento.')),
      );
      return;
    }

    final cliente = Cliente(
      uid: _user!.uid,
      nome: _nomeController.text,
      whatsapp: _whatsappController.text,
      endereco: _enderecoController.text,
      dataNascimento: _dataNascimento,
      historicoMedico: _historicoController.text,
      alergias: _alergiasController.text,
      medicamentos: _medicamentosController.text,
      cirurgias: _cirurgiasController.text,
      anamneseOk: true, // Marca como preenchido
    );

    await _firestoreService.salvarCliente(cliente);

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil e Anamnese'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _salvar),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Dados Pessoais', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Nome é obrigatório' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _whatsappController,
              decoration: InputDecoration(
                labelText: 'WhatsApp ${_isObrigatorio('whatsapp') ? '*' : ''}',
                border: const OutlineInputBorder(),
              ),
              validator: (v) => _validar('whatsapp', v),
              keyboardType: TextInputType.phone,
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
                  : 'Nascimento: ${DateFormat('dd/MM/yyyy').format(_dataNascimento!)}'),
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
      ),
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
}