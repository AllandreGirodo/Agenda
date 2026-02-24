import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

class LoginController {
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> logar(BuildContext context, String email, String senha) async {
    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha email e senha')),
      );
      return;
    }

    // TODO: Implementar lógica real do Firebase Auth aqui
    print("Tentando logar com $email");
    
    // Simulação de sucesso
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login realizado com sucesso (Simulação)')),
    );
    // Navigator.pushReplacementNamed(context, '/home');
  }
}