import 'package:flutter/material.dart';
import '../app_localizations.dart';
// import 'package:firebase_auth/firebase_auth.dart';

class LoginController {
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> logar(BuildContext context, String email, String senha) async {
    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fillFieldsError)),
      );
      return;
    }

    // TODO: Implementar lógica real do Firebase Auth aqui
    print("Tentando logar com $email");
    
    // Simulação de sucesso
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.loginSuccess)),
    );
    // Navigator.pushReplacementNamed(context, '/home');
  }
}