import 'package:flutter/material.dart';
import '../controller/login_controller.dart';
import '../app_localizations.dart';
import '../main.dart';
import 'signup_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _controller = LoginController();

  @override
  Widget build(BuildContext context) {
    // Determinar o idioma atual para exibir no dropdown
    final currentLocale = Localizations.localeOf(context);
    Locale dropdownValue;
    if (currentLocale.languageCode == 'en') {
      dropdownValue = const Locale('en', 'US');
    } else if (currentLocale.languageCode == 'es') {
      dropdownValue = const Locale('es', 'ES');
    } else if (currentLocale.languageCode == 'ja') {
      dropdownValue = const Locale('ja', 'JP');
    } else {
      dropdownValue = const Locale('pt', 'BR');
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          DropdownButton<Locale>(
            value: dropdownValue,
            icon: const Icon(Icons.language, color: Colors.teal),
            underline: Container(), // Remove a linha padrão do dropdown
            onChanged: (Locale? newValue) {
              if (newValue != null) {
                MyApp.setLocale(context, newValue);
              }
            },
            items: const [
              DropdownMenuItem(value: Locale('pt', 'BR'), child: Text('🇧🇷 PT')),
              DropdownMenuItem(value: Locale('en', 'US'), child: Text('🇺🇸 EN')),
              DropdownMenuItem(value: Locale('es', 'ES'), child: Text('🇪🇸 ES')),
              DropdownMenuItem(value: Locale('ja', 'JP'), child: Text('🇯🇵 JA')),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.spa, size: 80, color: Colors.teal),
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