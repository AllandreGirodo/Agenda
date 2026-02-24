import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../view/agendamento_view.dart';
import '../view/admin_agendamentos_view.dart';
import 'firestore_service.dart';

class LoginController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> logar(BuildContext context, String email, String senha) async {
    try {
      // 1. Autenticar no Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        
        // 2. Buscar dados do usuário no Firestore para verificar o tipo
        final usuario = await _firestoreService.getUsuario(uid);

        if (context.mounted) {
          if (usuario != null) {
            // 3. Redirecionar com base no tipo de usuário
            if (usuario.tipo == 'admin') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminAgendamentosView()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AgendamentoView()),
              );
            }
          } else {
            // Usuário autenticado mas sem registro no banco
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cadastro de usuário não encontrado.')),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de login: ${e.message}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
}