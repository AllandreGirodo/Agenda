import 'package:flutter/material.dart';
import 'package:agenda/core/services/firestore_service.dart';
import 'package:agenda/features/admin/view/admin_ferramentas_database_setup_view.dart';
import 'package:agenda/core/utils/app_strings.dart';

class AdminFerramentasSenhaSetupView extends StatefulWidget {
  final VoidCallback? onConfirmed;

  const AdminFerramentasSenhaSetupView({
    super.key,
    this.onConfirmed,
  });

  @override
  State<AdminFerramentasSenhaSetupView> createState() =>
      _AdminFerramentasSenhaSetupViewState();
}

class _AdminFerramentasSenhaSetupViewState
    extends State<AdminFerramentasSenhaSetupView> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _senhaConfigurada = false;
  bool _carregando = true;
  bool _mostraFormulario = false;
  final TextEditingController _novoaSenhaController = TextEditingController();
  final TextEditingController _confirmacaoController = TextEditingController();
  bool _mostrarSenha = false;
  String? _mensagemErro;

  @override
  void initState() {
    super.initState();
    _verificarSenha();
  }

  Future<void> _verificarSenha() async {
    try {
      final existe = await _firestoreService.verificaSenhaAdminFerramentasConfigurada();
      if (!mounted) return;
      setState(() {
        _senhaConfigurada = existe;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _mensagemErro = AppStrings.erroVerificarConfiguracao(e.toString());
      });
    }
  }

  Future<void> _salvarNovaSenha() async {
    if (_novoaSenhaController.text.isEmpty) {
      setState(() => _mensagemErro = AppStrings.senhaObrigatoria);
      return;
    }
    if (_novoaSenhaController.text != _confirmacaoController.text) {
      setState(() => _mensagemErro = AppStrings.senhasNaoCoincidem);
      return;
    }
    if (_novoaSenhaController.text.length < 6) {
      setState(() => _mensagemErro = AppStrings.minimoSeisCaracteres);
      return;
    }

    setState(() => _mensagemErro = null);

    try {
      await _firestoreService.salvarSenhaAdminFerramentas(_novoaSenhaController.text);
      if (!mounted) return;
      
      _novoaSenhaController.clear();
      _confirmacaoController.clear();
      
      setState(() {
        _senhaConfigurada = true;
        _mostraFormulario = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.senhaConfiguradaSucesso)),
      );

      widget.onConfirmed?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _mensagemErro = AppStrings.erroSalvar(e.toString()));
    }
  }

  void _abrirFormulario() {
    setState(() {
      _mostraFormulario = true;
      _mensagemErro = null;
      _novoaSenhaController.clear();
      _confirmacaoController.clear();
    });
  }

  @override
  void dispose() {
    _novoaSenhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_senhaConfigurada && !_mostraFormulario) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.configuracaoFerramentas),
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              Text(
                AppStrings.senhaAdminConfiguradaTitulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  AppStrings.acesseFerramentasBancoAbaixo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.storage),
                label: Text(AppStrings.conferirPrepararBanco),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminFerramentasDatabaseSetupView(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: Text(AppStrings.alterarSenha),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                onPressed: _abrirFormulario,
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.voltar),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.configuracaoFerramentas),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _abrirFormulario,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    padding: const EdgeInsets.all(40),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                  Text(
                    AppStrings.cliqueIconeConfigurarSenhaFerramentas,
                  textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 50),
                if (_mostraFormulario) ...[
                    Text(
                      AppStrings.novaSenhaAdminTitulo,
                      style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _novoaSenhaController,
                    obscureText: !_mostrarSenha,
                    decoration: InputDecoration(
                      labelText: AppStrings.senhaLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _mostrarSenha ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _mostrarSenha = !_mostrarSenha);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmacaoController,
                    obscureText: !_mostrarSenha,
                    decoration: InputDecoration(
                      labelText: AppStrings.confirmeSenha,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  if (_mensagemErro != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _mensagemErro!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _mostraFormulario = false);
                          },
                          child: Text(AppStrings.cancelButton),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _salvarNovaSenha,
                          child: Text(AppStrings.salvar),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
