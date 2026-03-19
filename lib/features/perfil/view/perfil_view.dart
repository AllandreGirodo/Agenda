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
import 'package:agenda/core/utils/international_phone_input_formatter.dart';
import 'package:agenda/core/widgets/language_selector.dart';
import 'package:agenda/app_localizations.dart';
import 'package:agenda/core/utils/massage_type_catalog.dart';

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
  final _nomePreferidoController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _nomeContatoSecundarioController = TextEditingController();
  final _telefoneSecundarioController = TextEditingController();
  final _nomeIndicacaoController = TextEditingController();
  final _telefoneIndicacaoController = TextEditingController();
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
  String _ddiPrincipal = InternationalPhoneInputFormatter.defaultDdi;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _nomePreferidoController.dispose();
    _whatsappController.dispose();
    _nomeContatoSecundarioController.dispose();
    _telefoneSecundarioController.dispose();
    _nomeIndicacaoController.dispose();
    _telefoneIndicacaoController.dispose();
    _cpfController.dispose();
    _cepController.dispose();
    _enderecoController.dispose();
    _historicoController.dispose();
    _alergiasController.dispose();
    _medicamentosController.dispose();
    _cirurgiasController.dispose();
    super.dispose();
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
    final dynamic usuario = results[2];

    if (cliente != null) {
      _ddiPrincipal = InternationalPhoneInputFormatter.normalizeDdi(
        cliente.ddiCliente,
      );
      _nomeController.text = cliente.nome;
      _nomePreferidoController.text = cliente.nomePreferidoCliente ?? '';
      _whatsappController.text = InternationalPhoneInputFormatter.formatLocal(
        cliente.telefonePrincipal,
        ddi: _ddiPrincipal,
        maxLocalDigits: _maxLocalDigitsParaDdi(_ddiPrincipal),
      );
      _nomeContatoSecundarioController.text = cliente.nomeContatoSecundario;
      _telefoneSecundarioController.text =
          InternationalPhoneInputFormatter.formatLocal(
        cliente.telefoneSecundario,
        ddi: _ddiPrincipal,
        maxLocalDigits: _maxLocalDigitsParaDdi(_ddiPrincipal),
      );
      _nomeIndicacaoController.text = cliente.nomeIndicacao;
      _telefoneIndicacaoController.text =
          InternationalPhoneInputFormatter.formatLocal(
        cliente.telefoneIndicacao,
        ddi: _ddiPrincipal,
        maxLocalDigits: _maxLocalDigitsParaDdi(_ddiPrincipal),
      );
      _cpfController.text = cliente.cpf;
      _cepController.text = cliente.cep;
      _enderecoController.text = cliente.endereco;
      _historicoController.text = cliente.historicoMedico;
      _alergiasController.text = cliente.alergias;
      _medicamentosController.text = cliente.medicamentos;
      _cirurgiasController.text = cliente.cirurgias;
      _dataNascimento = cliente.dataNascimento;
    } else if (usuario != null) {
      _ddiPrincipal = InternationalPhoneInputFormatter.normalizeDdi(
        usuario.ddi as String?,
      );
      _nomeController.text = (usuario.nome as String? ?? '').trim();
      _nomePreferidoController.text =
          (usuario.nomePreferido as String? ?? '').trim();
      _whatsappController.text = InternationalPhoneInputFormatter.formatLocal(
        (usuario.telefonePrincipal as String? ??
                usuario.whatsapp as String? ??
                '')
            .trim(),
        ddi: _ddiPrincipal,
        maxLocalDigits: _maxLocalDigitsParaDdi(_ddiPrincipal),
      );
      _nomeContatoSecundarioController.text =
          (usuario.nomeContatoSecundario as String? ?? '').trim();
      _telefoneSecundarioController.text =
          InternationalPhoneInputFormatter.formatLocal(
        (usuario.telefoneSecundario as String? ?? '').trim(),
        ddi: _ddiPrincipal,
        maxLocalDigits: _maxLocalDigitsParaDdi(_ddiPrincipal),
      );
      _nomeIndicacaoController.text =
          (usuario.nomeIndicacao as String? ?? '').trim();
      _telefoneIndicacaoController.text =
          InternationalPhoneInputFormatter.formatLocal(
        (usuario.telefoneIndicacao as String? ?? '').trim(),
        ddi: _ddiPrincipal,
        maxLocalDigits: _maxLocalDigitsParaDdi(_ddiPrincipal),
      );
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
    if (cep.length != 8) return AppStrings.invalidCep;
    return null;
  }

  Future<void> _buscarCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.invalidCep)),
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
              SnackBar(content: Text(AppStrings.cepNotFound)),
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
          SnackBar(content: Text(AppStrings.cepError)),
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
        SnackBar(content: Text(AppStrings.birthDateRequired)),
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
      nomeCliente: _nomeController.text.trim(),
      nomePreferidoCliente: _nomePreferidoController.text.trim(),
      ddiCliente: _ddiPrincipal,
      whatsappCliente: InternationalPhoneInputFormatter.localDigits(
        _whatsappController.text,
        ddi: _ddiPrincipal,
        maxLocalDigits: _maxLocalDigitsParaDdi(_ddiPrincipal),
      ),
      telefonePrincipalCliente: InternationalPhoneInputFormatter.localDigits(
        _whatsappController.text,
        ddi: _ddiPrincipal,
        maxLocalDigits: _maxLocalDigitsParaDdi(_ddiPrincipal),
      ),
      nomeContatoSecundarioCliente:
          _nomeContatoSecundarioController.text.trim(),
      telefoneSecundarioCliente: InternationalPhoneInputFormatter.localDigits(
        _telefoneSecundarioController.text,
        ddi: _ddiPrincipal,
        maxLocalDigits: _maxLocalDigitsParaDdi(_ddiPrincipal),
      ),
      nomeIndicacaoCliente: _nomeIndicacaoController.text.trim(),
      telefoneIndicacaoCliente: InternationalPhoneInputFormatter.localDigits(
        _telefoneIndicacaoController.text,
        ddi: _ddiPrincipal,
        maxLocalDigits: _maxLocalDigitsParaDdi(_ddiPrincipal),
      ),
      cpfCliente: _somenteDigitos(_cpfController.text),
      cepCliente: _somenteDigitos(_cepController.text),
      enderecoCliente: _enderecoController.text,
      dataNascimentoCliente: _dataNascimento,
      historicoMedicoCliente: _historicoController.text,
      alergiasCliente: _alergiasController.text,
      medicamentosCliente: _medicamentosController.text,
      cirurgiasCliente: _cirurgiasController.text,
      anamneseOkCliente: true,
    );

    await _firestoreService.salvarCliente(cliente);
    await _firestoreService.sincronizarPerfilClienteNoUsuario(
      _user.uid,
      cliente,
    );

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
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.loginAgainToDelete)));
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.erroGenerico('${e.message}'))));
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.erroGenerico('$e'))));
      }
    }
  }

  String _somenteDigitos(String valor) {
    return valor.replaceAll(RegExp(r'[^0-9]'), '');
  }

  int _maxLocalDigitsParaDdi(String ddi) {
    final normalizedDdi = InternationalPhoneInputFormatter.normalizeDdi(ddi);
    if (normalizedDdi == InternationalPhoneInputFormatter.defaultDdi) {
      return InternationalPhoneInputFormatter.defaultMaxLocalDigits;
    }
    return InternationalPhoneInputFormatter.maxInternationalLocalDigits;
  }

  InputDecoration _buildPhoneDecoration({
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isBrazil =
        _ddiPrincipal == InternationalPhoneInputFormatter.defaultDdi;

    return InputDecoration(
      labelText: label,
      hintText: isBrazil ? '(16) 99999-9999' : '999 999 999',
      prefixIcon: Icon(icon),
      prefix: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBrazil ? '🇧🇷' : '🌍',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 4),
            Text(
              '+$_ddiPrincipal',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
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
              decoration: InputDecoration(labelText: AppStrings.fullNameLabel, prefixIcon: const Icon(Icons.person)),
              validator: (v) => _validar('nome', v),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nomePreferidoController,
              decoration: InputDecoration(
                labelText: AppStrings.preferredNameLabel,
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 20),
            Text(AppStrings.contactDataTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _whatsappController,
              decoration: _buildPhoneDecoration(
                label: AppStrings.whatsappLabel,
                icon: Icons.phone,
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                InternationalPhoneInputFormatter(
                  ddi: _ddiPrincipal,
                  maxLocalDigits: _maxLocalDigitsParaDdi(_ddiPrincipal),
                ),
              ],
              validator: (v) => _validar('whatsapp', v),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nomeContatoSecundarioController,
              decoration: InputDecoration(
                labelText: AppStrings.secondaryContactNameLabel,
                prefixIcon: const Icon(Icons.people_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _telefoneSecundarioController,
              decoration: _buildPhoneDecoration(
                label: AppStrings.secondaryPhoneLabel,
                icon: Icons.phone_outlined,
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                InternationalPhoneInputFormatter(
                  ddi: _ddiPrincipal,
                  maxLocalDigits: _maxLocalDigitsParaDdi(_ddiPrincipal),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nomeIndicacaoController,
              decoration: InputDecoration(
                labelText: AppStrings.referralNameLabel,
                prefixIcon: const Icon(Icons.volunteer_activism_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _telefoneIndicacaoController,
              decoration: _buildPhoneDecoration(
                label: AppStrings.referralPhoneLabel,
                icon: Icons.call_outlined,
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                InternationalPhoneInputFormatter(
                  ddi: _ddiPrincipal,
                  maxLocalDigits: _maxLocalDigitsParaDdi(_ddiPrincipal),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _cpfController,
              decoration: InputDecoration(labelText: AppStrings.cpfLabel, prefixIcon: const Icon(Icons.badge)),
              keyboardType: TextInputType.number,
              validator: _validarCpf,
            ),
            const SizedBox(height: 10),
            ListTile(
              title: Text(AppStrings.birthDateLabel),
              subtitle: Text(_dataNascimento == null ? AppStrings.birthDateNotInformed : DateFormat('dd/MM/yyyy').format(_dataNascimento!)),
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
            Text(AppStrings.addressLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cepController,
                    decoration: InputDecoration(labelText: AppStrings.cepLabel, prefixIcon: const Icon(Icons.location_on)),
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
              decoration: InputDecoration(labelText: AppStrings.addressLabel),
              maxLines: 2,
              validator: (v) => _validar('endereco', v),
            ),
            const SizedBox(height: 20),
            Text(AppStrings.anamnesisTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _historicoController,
              decoration: InputDecoration(labelText: AppStrings.medicalHistoryLabel),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _alergiasController,
              decoration: InputDecoration(labelText: AppStrings.allergiesLabel),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _medicamentosController,
              decoration: InputDecoration(labelText: AppStrings.medicationsLabel),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _cirurgiasController,
              decoration: InputDecoration(labelText: AppStrings.surgeriesLabel),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _salvar,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
              child: Text(AppStrings.saveProfile),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _excluirConta,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: Text(AppStrings.deleteMyAccount, style: const TextStyle(color: Colors.red)),
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
        if (agendamentos.isEmpty) return Center(child: Text(AppStrings.noAppointmentsFound));

        return ListView.builder(
          itemCount: agendamentos.length,
          itemBuilder: (context, index) {
            final a = agendamentos[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(
                  MassageTypeCatalog.localize(AppLocalizations.of(context)!, a.tipo),
                ),
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
