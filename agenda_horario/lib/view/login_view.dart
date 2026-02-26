import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agenda/controller/login_controller.dart';
import 'package:agenda/controller/firestore_service.dart';
import 'package:agenda/controller/changelog_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agenda/app_localizations.dart';
import 'package:agenda/main.dart';
import 'package:agenda/view/signup_view.dart';
import 'package:agenda/view/db_seeder.dart';
import 'package:agenda/widgets/language_selector.dart';
import 'package:agenda/widgets/theme_selector.dart';
import 'package:agenda/widgets/sound_control.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _controller = LoginController();
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Verifica atualizações após a construção da interface
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarNovidades();
    });
  }

  Future<void> _verificarNovidades() async {
    try {
      // 1. Busca a última versão no banco
      final latestLog = await _firestoreService.getLatestChangeLog();
      if (latestLog == null) return;

      // 2. Busca a última versão vista localmente
      final prefs = await SharedPreferences.getInstance();
      final lastSeenVersion = prefs.getString('last_seen_version');

      // 3. Se forem diferentes, mostra o modal
      if (lastSeenVersion != latestLog.versao && mounted) {
        await _mostrarModalChangeLog(latestLog);
        
        // 4. Atualiza a versão vista
        await prefs.setString('last_seen_version', latestLog.versao);
      }

      // 5. Sincroniza metadados do Auth se estiver logado
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Este método não existe em firestore_service.dart, então foi removido para evitar erros.
        // await _firestoreService.sincronizarMetadadosUsuario(user);
      }
    } catch (e) {
      debugPrint('Erro ao verificar change log: $e');
    }
  }

  Future<void> _mostrarModalChangeLog(ChangeLogModel log) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // Obriga o usuário a clicar em "Entendi"
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.new_releases, color: Colors.teal),
            const SizedBox(width: 10),
            Expanded(child: Text('Novidades da v${log.versao}')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atualizado em: ${DateFormat('dd/MM/yyyy').format(log.data)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 16),
              ...log.mudancas.map((mudanca) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(mudanca)),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Legal, entendi!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          SoundControl(),
          ThemeSelector(),
          LanguageSelector(),
          SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onLongPress: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Iniciando população do banco (DEV)...')),
                  );
                  await DbSeeder.popularBancoDados();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Banco de dados populado com sucesso!')),
                    );
                  }
                },
                child: const Icon(Icons.spa, size: 80, color: Colors.teal),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.loginTitle,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.emailLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _senhaController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.passwordLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _controller.recuperarSenha(context, _emailController.text.trim());
                  },
                  child: Text(AppLocalizations.of(context)!.forgotPasswordButton),
                ),
              ),

              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _controller.logar(
                      context,
                      _emailController.text,
                      _senhaController.text,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppLocalizations.of(context)!.enterButton),
                ),
              ),
              
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpView()),
                  );
                },
                child: Text(AppLocalizations.of(context)!.createAccountButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}