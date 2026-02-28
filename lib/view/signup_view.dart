import 'package:flutter/material.dart';
import '../controller/login_controller.dart';
import '../app_localizations.dart';
import '../widgets/language_selector.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _controller = LoginController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.signupTitle),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: const [LanguageSelector()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.person_add, size: 60, color: Colors.teal),
            const SizedBox(height: 20),
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.fullNameLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
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
              controller: _whatsappController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.whatsappLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _controller.cadastrar(
                    context,
                    _nomeController.text,
                    _emailController.text,
                    _senhaController.text,
                    _whatsappController.text,
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                child: Text(AppLocalizations.of(context)!.registerButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}