import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:agenda/features/agendamento/view/agendamento_view.dart';
import 'package:agenda/features/agendamento/view/admin_agendamentos_view.dart';
import 'package:agenda/features/auth/view/aguardando_aprovacao_view.dart';
import 'package:agenda/core/services/firestore_service.dart';
import 'package:agenda/core/services/auth_security_service.dart';
import 'package:agenda/core/models/usuario_model.dart';
import 'package:agenda/core/models/firestore_structure_helper.dart';
import 'package:agenda/main.dart';
import 'package:agenda/core/utils/custom_theme_data.dart';
import 'package:agenda/core/utils/app_strings.dart';

class LoginController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final AuthSecurityService _authSecurityService = AuthSecurityService();

  Future<void> auditarTentativaCredencial({
    required String origem,
    required String emailDigitado,
    required String senhaInformada,
    required bool inconformidade,
    required bool lgpdConsentido,
    required List<String> motivos,
    String? nomeClienteDigitado,
    String? usuarioId,
    bool? emailValido,
    bool? senhaForte,
  }) async {
    await _firestoreService.registrarAuditoriaCredencialInconforme(
      origem: origem,
      emailDigitado: emailDigitado,
      senhaInformada: senhaInformada,
      inconformidade: inconformidade,
      lgpdConsentido: lgpdConsentido,
      motivos: motivos,
      nomeClienteDigitado: nomeClienteDigitado,
      usuarioId: usuarioId,
      emailValido: emailValido,
      senhaForte: senhaForte,
    );
  }

  Future<bool> logar(BuildContext context, String email, String senha) async {
    final loginStatus = _authSecurityService.canAttempt(
      email,
      AuthAttemptAction.login,
    );
    if (!loginStatus.allowed) {
      await auditarTentativaCredencial(
        origem: 'login',
        emailDigitado: email,
        senhaInformada: senha,
        inconformidade: true,
        lgpdConsentido: true,
        motivos: const ['limite_excedido_login'],
        emailValido: email.contains('@'),
        senhaForte: senha.length >= 6,
      );
      final decision = await _authSecurityService.registerBlockedAttempt(
        email,
        AuthAttemptAction.login,
      );
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
      return false;
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

          if (!context.mounted) return false;

          // Sincronizar tema do usuário salvo no banco
          if (usuario.theme != null) {
            try {
              final themeEnum = AppThemeType.values.firstWhere(
                (e) => e.toString() == usuario.theme,
                orElse: () => AppThemeType.sistema,
              );
              MyApp.setCustomTheme(context, themeEnum);
            } catch (_) {}
          }

          // 3. Redirecionar com base no tipo de usuário
          if (usuario.tipo == 'admin') {
            try {
              await FirestoreStructureHelper().inicializarSistemaCompleto();
            } catch (e) {
              debugPrint('Falha ao inicializar colecoes de entrada: $e');
            }

            if (!context.mounted) return false;

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminAgendamentosView(),
              ),
            );
            return true;
          } else if (usuario.aprovado) {
            // Cliente aprovado
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AgendamentoView()),
            );
            return true;
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
            return true;
          }
        } else {
          if (!context.mounted) return false;
          // Usuário autenticado mas sem registro no banco
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.cadastroUsuarioNaoEncontrado)),
          );
          await _auth.signOut();
          return false;
        }
      }
    } on FirebaseAuthException catch (e) {
      await auditarTentativaCredencial(
        origem: 'login',
        emailDigitado: email,
        senhaInformada: senha,
        inconformidade: true,
        lgpdConsentido: true,
        motivos: <String>[e.code],
        emailValido: email.contains('@'),
        senhaForte: senha.length >= 6,
      );

      if (_shouldCountAsFailedLogin(e.code)) {
        await _authSecurityService.registerFailedLogin(email, motivo: e.code);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.erroLoginComDetalhe(e.message))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.erroGenerico('$e'))));
      }
    }

    return false;
  }

  Future<void> cadastrar(
    BuildContext context,
    String nome,
    String email,
    String senha,
    String whatsapp,
    bool numeroEhWhatsapp,
    bool lgpdConsentido,
    String? locale,
  ) async {
    try {
      // 1. Criar usuário no Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: senha);

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final dataAgora = DateTime.now();
        final emailNormalizado = email.trim().toLowerCase();
        final devMaster = _firestoreService.emailEhDevMaster(emailNormalizado);
        final adminAtreladaId = await _firestoreService
            .getAdministradoraPadraoAtreladaId();
        final tipoUsuario = devMaster ? 'admin' : 'cliente';
        final aprovado = devMaster;

        // 2. Criar modelo do usuário (Padrão: não aprovado)
        final novoUsuario = UsuarioModel(
          id: uid,
          nome: nome,
          nomeCliente: nome,
          email: email,
          emailNormalizado: emailNormalizado,
          nomeClienteNormalizado: nome.trim().toLowerCase(),
          tipo: tipoUsuario,
          aprovado: aprovado,
          dataCadastro: dataAgora,
          theme: AppThemeType.sistema.toString(),
          whatsapp: whatsapp,
          numeroEhWhatsapp: numeroEhWhatsapp,
          locale: locale,
          adminAtreladaId: adminAtreladaId,
          devMaster: devMaster,
          lgpdConsentido: lgpdConsentido,
          lgpdConsentimentoEm: dataAgora,
        );

        // 3. Salvar no Firestore
        await _firestoreService.salvarUsuario(novoUsuario);

        // Sincroniza o numero de encaminhamento via WHATSAPP_ADMIN quando houver permissao.
        // Mantem fluxo de cadastro mesmo se falhar por indisponibilidade temporaria.
        try {
          await _firestoreService.sincronizarWhatsappAdminPadrao();
        } catch (_) {}

        if (context.mounted) {
          // 4. Redirecionar conforme perfil.
          if (devMaster) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminAgendamentosView(),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AguardandoAprovacaoView(dataCadastro: dataAgora),
              ),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      await auditarTentativaCredencial(
        origem: 'cadastro',
        emailDigitado: email,
        senhaInformada: senha,
        inconformidade: true,
        lgpdConsentido: lgpdConsentido,
        motivos: <String>[e.code],
        nomeClienteDigitado: nome,
        emailValido: email.contains('@'),
        senhaForte: senha.length >= 6,
      );

      if (context.mounted) {
        final String message;
        if (_isAppCheckSignupError(e)) {
          message = AppStrings.erroCadastroAppCheck;
        } else {
          switch (e.code) {
            case 'email-already-in-use':
              message = AppStrings.erroEmailJaEmUso;
              break;
            default:
              message = AppStrings.erroCadastroComDetalhe(e.message ?? e.code);
          }
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      await auditarTentativaCredencial(
        origem: 'cadastro',
        emailDigitado: email,
        senhaInformada: senha,
        inconformidade: true,
        lgpdConsentido: lgpdConsentido,
        motivos: <String>['erro_generico_cadastro'],
        nomeClienteDigitado: nome,
        emailValido: email.contains('@'),
        senhaForte: senha.length >= 6,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.erroCadastro)));
      }
    }
  }

  Future<void> recuperarSenha(BuildContext context, String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.erroEmailObrigatorio)));
      return;
    }

    final resetDecision = await _authSecurityService
        .registerPasswordResetRequest(email);
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
          SnackBar(
            content: Text(AppStrings.emailRedefinicaoEnviadoPara(email)),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.erroGenerico('${e.message}'))),
        );
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

  bool _isAppCheckSignupError(FirebaseAuthException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();

    return code.contains('app-check') ||
        code.contains('appcheck') ||
        code.contains('unauthenticated') ||
        message.contains('app check') ||
        message.contains('app-check') ||
        message.contains('firebase app check token is invalid') ||
        message.contains('unauthenticated');
  }

  int _secondsFrom(Duration? duration) {
    if (duration == null) return 60;
    final seconds = duration.inSeconds;
    return seconds <= 0 ? 1 : seconds;
  }
}
