import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:agenda/view/app_styles.dart';
import 'package:agenda/view/app_strings.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:agenda/view/agendamento_view.dart';
import 'package:agenda/view/admin_agendamentos_view.dart';
import 'package:agenda/view/perfil_view.dart'; // Para cadastro, se necessário redirecionar
import 'package:agenda/widgets/language_selector.dart';
import 'package:agenda/controller/firestore_service.dart';

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
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _verificarBiometriaAutomatica();
  }

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
        final adminEmail = dotenv.env['ADMIN_EMAIL'];
        if (user.email == adminEmail) { 
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

  Future<void> _recuperarSenha() async {
    String email = _emailController.text.trim();
    
    // Se o campo estiver vazio, abre um diálogo para digitar o email
    if (email.isEmpty) {
      final emailDigitado = await showDialog<String>(
        context: context,
        builder: (context) {
          final controllerTemp = TextEditingController();
          return AlertDialog(
            title: Text(AppStrings.esqueceuSenha),
            content: TextField(
              controller: controllerTemp,
              decoration: const InputDecoration(labelText: 'Digite seu e-mail cadastrado'),
              keyboardType: TextInputType.emailAddress,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.cancelButton)),
              ElevatedButton(onPressed: () => Navigator.pop(context, controllerTemp.text.trim()), child: const Text('Enviar')),
            ],
          );
        },
      );
      if (emailDigitado == null || emailDigitado.isEmpty) return;
      email = emailDigitado;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppStrings.emailRecuperacaoEnviado),
        backgroundColor: Colors.green,
      ));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message ?? 'Erro ao enviar email'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // Usuário cancelou
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      // Redirecionamento é tratado pelo StreamBuilder no AgendamentoView ou aqui manualmente
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AgendamentoView()));
      
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro no Google Login: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verificarBiometriaAutomatica() async {
    // Verifica se a biometria está ativa nas configurações globais
    final config = await FirestoreService().getConfiguracao();
    if (!config.biometriaAtiva) return;

    // Verifica se o dispositivo suporta
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

    if (canAuthenticate) {
      // Opcional: Tentar autenticar automaticamente se já houver sessão válida (mas expirada na UI)
      // Para este exemplo, deixaremos apenas o botão visível.
    }
  }

  Future<void> _loginBiometrico() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: AppStrings.biometriaBtn,
        options: const AuthenticationOptions(biometricOnly: false),
      );

      if (didAuthenticate) {
        // Em um app real, aqui recuperaríamos as credenciais do SecureStorage.
        // Como estamos usando Firebase Auth que persiste a sessão, se o currentUser não for nulo,
        // podemos pular o login. Se for nulo, a biometria serve apenas como "atalho" visual,
        // mas ainda precisaria de credenciais.
        // Para o TCC, simularemos que a biometria valida o usuário atual se ele já estiver logado no cache.
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && mounted) {
           Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AgendamentoView()));
        } else if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faça login com senha uma vez para habilitar o acesso rápido.')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppStrings.biometriaErro}: $e')));
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
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
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
                    style: AppStyles.subtitle.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
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
                          onPressed: _recuperarSenha,
                          child: Text(AppStrings.esqueceuSenha, style: const TextStyle(color: Colors.grey)),
                        ),
                        const Divider(),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.login, color: Colors.red), // Ícone genérico, ideal seria logo do Google
                          label: Text(AppStrings.googleLoginBtn),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                          onPressed: _googleLogin,
                        ),
                        const SizedBox(height: 10),
                        // Botão de Biometria
                        IconButton(
                          icon: const Icon(Icons.fingerprint, size: 40, color: AppColors.primary),
                          tooltip: AppStrings.biometriaBtn,
                          onPressed: _loginBiometrico,
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