import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:agenda/view/agendamento_view.dart';
import 'package:agenda/view/admin_agendamentos_view.dart';
import 'package:agenda/view/aguardando_aprovacao_view.dart';
import 'package:agenda/controller/firestore_service.dart';
import 'package:agenda/usuario_model.dart';
import 'package:agenda/main.dart';
import 'package:agenda/custom_theme_data.dart';

class LoginController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> logar(BuildContext context, String email, String senha) async {
    try {
      // 1. Autenticar no Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;

        // Salvar Token FCM
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _firestoreService.atualizarToken(uid, token);
        }
        
        // 2. Buscar dados do usuário no Firestore para verificar o tipo
        final usuario = await _firestoreService.getUsuario(uid);

        if (context.mounted) {
          if (usuario != null) {
            // Sincronizar tema do usuário salvo no banco
            if (usuario.theme != null) {
              try {
                final themeEnum = AppThemeType.values.firstWhere(
                  (e) => e.toString() == usuario.theme,
                  orElse: () => AppThemeType.sistema
                );
                MyApp.setCustomTheme(context, themeEnum);
              } catch (_) {}
            }

            // 3. Redirecionar com base no tipo de usuário
            if (usuario.tipo == 'admin') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminAgendamentosView()),
              );
            } else if (usuario.aprovado) {
              // Cliente aprovado
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AgendamentoView()),
              );
            } else {
              // Cliente não aprovado (Pendente)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AguardandoAprovacaoView(
                    dataCadastro: usuario.dataCadastro ?? DateTime.now(),
                  ),
                ),
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

  Future<void> cadastrar(BuildContext context, String nome, String email, String senha, String whatsapp) async {
    try {
      // 1. Criar usuário no Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final dataAgora = DateTime.now();

        // 2. Criar modelo do usuário (Padrão: não aprovado)
        final novoUsuario = UsuarioModel(
          id: uid,
          nome: nome,
          email: email,
          tipo: 'cliente',
          aprovado: false,
          dataCadastro: dataAgora,
          theme: AppThemeType.sistema.toString(),
        );

        // 3. Salvar no Firestore
        await _firestoreService.salvarUsuario(novoUsuario);

        if (context.mounted) {
          // 4. Redirecionar para tela de aguardo
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AguardandoAprovacaoView(dataCadastro: dataAgora)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao cadastrar: $e')));
      }
    }
  }

  Future<void> recuperarSenha(BuildContext context, String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha o campo de email para recuperar a senha.')),
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email de redefinição enviado para $email')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.message}')));
      }
    }
  }
}