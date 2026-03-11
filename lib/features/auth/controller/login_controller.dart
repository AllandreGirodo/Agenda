import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:agenda/features/agendamento/view/agendamento_view.dart';
import 'package:agenda/features/agendamento/view/admin_agendamentos_view.dart';
import 'package:agenda/features/auth/view/aguardando_aprovacao_view.dart';
import 'package:agenda/core/services/firestore_service.dart';
import 'package:agenda/core/services/auth_security_service.dart';
import 'package:agenda/core/models/usuario_model.dart';
import 'package:agenda/main.dart';
import 'package:agenda/core/utils/custom_theme_data.dart';
import 'package:agenda/core/utils/app_strings.dart';

class LoginController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final AuthSecurityService _authSecurityService = AuthSecurityService();

  Future<void> logar(BuildContext context, String email, String senha) async {
    final loginStatus = _authSecurityService.canAttempt(email, AuthAttemptAction.login);
    if (!loginStatus.allowed) {
      final decision = await _authSecurityService.registerBlockedAttempt(email, AuthAttemptAction.login);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.tentativasExcedidas(
                AppStrings.acaoLogin,
                _secondsFrom(decision.retryAfter),
              ),
            ),
          ),
        );
      }
      return;
    }

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

        if (usuario != null) {
          // Atualiza token sem bloquear o login caso a gravação falhe.
          try {
            final token = await _firebaseMessaging.getToken();
            if (token != null) {
              await _firestoreService.atualizarToken(uid, token);
            }
          } catch (_) {}

          if (!context.mounted) return;

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
          if (!context.mounted) return;
          // Usuário autenticado mas sem registro no banco
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.cadastroUsuarioNaoEncontrado)),
          );
          await _auth.signOut();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (_shouldCountAsFailedLogin(e.code)) {
        await _authSecurityService.registerFailedLogin(
          email,
          motivo: e.code,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.erroLoginComDetalhe(e.message))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.erroGenerico('$e'))),
        );
      }
    }
  }

  Future<void> cadastrar(
    BuildContext context,
    String nome,
    String email,
    String senha,
    String whatsapp,
    bool numeroEhWhatsapp,
  ) async {
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
          whatsapp: whatsapp,
          numeroEhWhatsapp: numeroEhWhatsapp,
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
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        final message = e.code == 'firebase-app-check-token-is-invalid'
            ? AppStrings.erroCadastroAppCheck
            : AppStrings.erroCadastroComDetalhe(e.message ?? e.code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.erroCadastroComDetalhe('$e'))));
      }
    }
  }

  Future<void> recuperarSenha(BuildContext context, String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.erroEmailObrigatorio)),
      );
      return;
    }

    final resetDecision = await _authSecurityService.registerPasswordResetRequest(email);
    if (!resetDecision.allowed) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.tentativasExcedidas(
                AppStrings.acaoRecuperacaoSenha,
                _secondsFrom(resetDecision.retryAfter),
              ),
            ),
          ),
        );
      }
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.emailRedefinicaoEnviadoPara(email))),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.erroGenerico('${e.message}'))));
      }
    }
  }

  bool _shouldCountAsFailedLogin(String code) {
    return code == 'wrong-password' ||
        code == 'invalid-credential' ||
        code == 'invalid-login-credentials' ||
        code == 'user-not-found' ||
        code == 'invalid-email';
  }

  int _secondsFrom(Duration? duration) {
    if (duration == null) return 60;
    final seconds = duration.inSeconds;
    return seconds <= 0 ? 1 : seconds;
  }
}