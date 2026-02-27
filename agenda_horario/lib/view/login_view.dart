import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agenda/view/app_styles.dart';
import 'package:agenda/view/app_strings.dart';
import 'package:agenda/view/agendamento_view.dart';
import 'package:agenda/view/admin_agendamentos_view.dart';
import 'package:agenda/view/perfil_view.dart'; // Para cadastro, se necessário redirecionar
import 'package:agenda/widgets/language_selector.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;
  bool _isObscure = true;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );
      
      if (!mounted) return;
      
      // Verifica se é admin (lógica simples por email, ideal seria claim ou banco)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (user.email == 'admin@agenda.com') { // Exemplo de verificação
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminAgendamentosView()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AgendamentoView()));
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message ?? 'Erro ao fazer login'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cadastro() async {
    // Lógica simplificada de cadastro direto ou navegação para tela de registro
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );
      if (!mounted) return;
      // Após cadastro, vai para perfil para completar dados
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PerfilView()));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message ?? 'Erro ao cadastrar'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usa o tema atual (Light ou Dark) configurado no main.dart
    final theme = Theme.of(context);

    return Scaffold(
      // Fundo transparente para permitir ver o AnimatedBackground do main.dart
      backgroundColor: Colors.transparent, 
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            // Cor do card adapta-se ao tema (Surface)
            color: theme.colorScheme.surface.withOpacity(0.9),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(alignment: Alignment.topRight, child: LanguageSelector()),
                  const Icon(Icons.spa, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.loginTitulo,
                    style: AppStyles.title.copyWith(color: theme.colorScheme.onSurface),
                  ),
                  Text(
                    AppStrings.loginSubtitulo,
                    style: AppStyles.subtitle.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: AppStrings.emailLabel,
                      prefixIcon: const Icon(Icons.email),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _senhaController,
                    decoration: InputDecoration(
                      labelText: AppStrings.senhaLabel,
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isObscure = !_isObscure),
                      ),
                    ),
                    obscureText: _isObscure,
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: AppStyles.primaryButton,
                            child: Text(AppStrings.entrarBtn),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _cadastro,
                          child: Text(AppStrings.cadastrarBtn),
                        ),
                        TextButton(
                          onPressed: () {
                            // Lógica de recuperação de senha
                          },
                          child: Text(AppStrings.esqueceuSenha, style: const TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}