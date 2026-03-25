import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:agenda/features/agendamento/view/agendamento_view.dart';
import 'package:agenda/features/agendamento/view/admin_agendamentos_view.dart';
import 'package:agenda/features/auth/view/aguardando_aprovacao_view.dart';
import 'package:agenda/features/auth/view/signup_view.dart';
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
    String metodoEntrada = 'email_senha',
    String provedorEntrada = 'firebase_auth',
    String? emailAutenticado,
    String? vinculoIdCliente,
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
      metodoEntrada: metodoEntrada,
      provedorEntrada: provedorEntrada,
      emailAutenticado: emailAutenticado,
      vinculoIdCliente: vinculoIdCliente,
      emailValido: emailValido,
      senhaForte: senhaForte,
    );
  }

  Future<VinculoClienteCadastroStatus> consultarStatusVinculoClientePorEmail({
    required String email,
    String? uidFallback,
    String? nomeFallback,
    String? telefoneFallback,
  }) {
    return _firestoreService.obterStatusVinculoClientePorEmail(
      email: email,
      uidFallback: uidFallback,
      nomeFallback: nomeFallback,
      telefoneFallback: telefoneFallback,
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

      final authUser = userCredential.user;
      if (authUser == null) {
        return false;
      }

      return _finalizarLoginPosAutenticacao(
        context,
        authUser,
        criarUsuarioSeAusente: false,
      );
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

  Future<bool> logarComGoogleAutenticado(BuildContext context) async {
    final authUser = _auth.currentUser;
    if (authUser == null) {
      return false;
    }

    return _finalizarLoginPosAutenticacao(
      context,
      authUser,
      criarUsuarioSeAusente: true,
      validarCadastroGoogle: true,
    );
  }

  Future<bool> completarCadastroGoogleCliente(
    BuildContext context,
    String nome,
    String whatsapp,
    bool numeroEhWhatsapp,
    String? locale,
  ) async {
    final authUser = _auth.currentUser;
    if (authUser == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.googleCadastroSessaoExpirada)),
        );
      }
      return false;
    }

    final uid = authUser.uid;
    final dataAgora = DateTime.now();
    final email = (authUser.email ?? '').trim();
    final emailNormalizado = email.toLowerCase();
    final nomeNormalizado = nome.trim().isNotEmpty
        ? nome.trim()
        : _resolverNomeBaseUsuario(authUser, emailNormalizado: emailNormalizado);
    final telefoneNormalizado = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');

    if (telefoneNormalizado.length < 10) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.googleCadastroTelefoneInvalido)),
        );
      }
      return false;
    }

    try {
      final usuarioExistente = await _firestoreService.getUsuario(uid);
      final devMaster =
          usuarioExistente?.devMaster ??
          _firestoreService.emailEhDevMaster(emailNormalizado);
      final tipoUsuario =
          usuarioExistente?.tipo ?? (devMaster ? 'admin' : 'cliente');
      final aprovado = usuarioExistente?.aprovado ?? devMaster;
      final adminAtreladaIdInformada =
          (usuarioExistente?.adminAtreladaId ?? '').trim();
      final adminAtreladaId = adminAtreladaIdInformada.isNotEmpty
          ? adminAtreladaIdInformada
          : await _firestoreService.getAdministradoraPadraoAtreladaId();

      final usuarioAtualizado = UsuarioModel(
        id: uid,
        nome: nomeNormalizado,
        nomeCliente: nomeNormalizado,
        nomePreferido: usuarioExistente?.nomePreferido,
        email: email,
        emailNormalizado: emailNormalizado,
        nomeClienteNormalizado: nomeNormalizado.toLowerCase(),
        tipo: tipoUsuario,
        aprovado: aprovado,
        dataCadastro: usuarioExistente?.dataCadastro ?? dataAgora,
        fcmToken: usuarioExistente?.fcmToken,
        visualizaTodos: usuarioExistente?.visualizaTodos ?? false,
        theme: usuarioExistente?.theme ?? AppThemeType.sistema.toString(),
        whatsapp: telefoneNormalizado,
        ddi: usuarioExistente?.ddi ?? '55',
        telefonePrincipal: telefoneNormalizado,
        nomeContatoSecundario: usuarioExistente?.nomeContatoSecundario,
        telefoneSecundario: usuarioExistente?.telefoneSecundario,
        nomeIndicacao: usuarioExistente?.nomeIndicacao,
        telefoneIndicacao: usuarioExistente?.telefoneIndicacao,
        categoriaOrigem: usuarioExistente?.categoriaOrigem,
        numeroEhWhatsapp: numeroEhWhatsapp,
        locale: locale ?? usuarioExistente?.locale ?? 'pt',
        adminAtreladaId: adminAtreladaId,
        devMaster: devMaster,
        lgpdConsentido: true,
        lgpdConsentimentoEm: dataAgora,
        lastChangelogSeen: usuarioExistente?.lastChangelogSeen,
        showChangelogAuto: usuarioExistente?.showChangelogAuto ?? true,
      );

      await _atualizarTokenAutenticacao(authUser);

      await _firestoreService.salvarUsuario(usuarioAtualizado);

      if (tipoUsuario == 'cliente') {
        await _firestoreService.salvarPerfilInicialClienteGoogle(
          uid: uid,
          nomeCliente: nomeNormalizado,
          whatsapp: telefoneNormalizado,
        );

        // Mantem sincronizacao best-effort para nao bloquear login social.
        try {
          await _firestoreService.sincronizarWhatsappAdminPadrao();
        } catch (_) {}
      }

      return _finalizarLoginPosAutenticacao(
        context,
        authUser,
        criarUsuarioSeAusente: false,
        validarCadastroGoogle: true,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.erroCadastroComDetalhe('$e'))),
        );
      }
      return false;
    }
  }

  Future<bool> _finalizarLoginPosAutenticacao(
    BuildContext context,
    User authUser, {
    required bool criarUsuarioSeAusente,
    bool validarCadastroGoogle = false,
  }) async {
    final uid = authUser.uid;
    var criouUsuarioAgora = false;
    UsuarioModel? usuario = await _firestoreService.getUsuario(uid);

    if (usuario == null && criarUsuarioSeAusente) {
      final dataAgora = DateTime.now();
      final email = (authUser.email ?? '').trim();
      final emailNormalizado = email.toLowerCase();
      final nomeBaseResolvido = _resolverNomeBaseUsuario(
        authUser,
        emailNormalizado: emailNormalizado,
      );
      final devMaster = _firestoreService.emailEhDevMaster(emailNormalizado);
      VinculoClienteCadastroStatus? vinculoGoogleStatus;

      if (validarCadastroGoogle) {
        vinculoGoogleStatus = await _firestoreService
            .obterStatusVinculoClientePorEmail(
              email: email,
              uidFallback: uid,
              nomeFallback: nomeBaseResolvido,
            );
      }

      if (!devMaster &&
          validarCadastroGoogle &&
          vinculoGoogleStatus != null &&
          !vinculoGoogleStatus.cadastroCompleto) {
        if (!context.mounted) return false;
        _abrirFluxoCompletarCadastroGoogle(
          context,
          authUser: authUser,
          usuarioExistente: null,
          vinculoStatus: vinculoGoogleStatus,
        );
        return true;
      }

      final nomeBase =
          vinculoGoogleStatus != null &&
              vinculoGoogleStatus.nomeSugerido.trim().isNotEmpty
          ? vinculoGoogleStatus.nomeSugerido.trim()
          : nomeBaseResolvido;
      final telefoneBase =
          (vinculoGoogleStatus?.telefoneSugerido ?? '').replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
      // Regras de usuarios exigem lgpd_consentido=true no primeiro write.
      final lgpdConsentido = true;
      final adminAtreladaId = await _firestoreService
          .getAdministradoraPadraoAtreladaId();
      final tipoUsuario = devMaster ? 'admin' : 'cliente';
      final aprovado = devMaster;

      final novoUsuario = UsuarioModel(
        id: uid,
        nome: nomeBase,
        nomeCliente: nomeBase,
        email: email,
        emailNormalizado: emailNormalizado,
        nomeClienteNormalizado: nomeBase.trim().toLowerCase(),
        tipo: tipoUsuario,
        aprovado: aprovado,
        dataCadastro: dataAgora,
        theme: AppThemeType.sistema.toString(),
        whatsapp: telefoneBase,
        ddi: '55',
        telefonePrincipal: telefoneBase,
        numeroEhWhatsapp: true,
        locale: 'pt',
        adminAtreladaId: adminAtreladaId,
        devMaster: devMaster,
        lgpdConsentido: lgpdConsentido,
        lgpdConsentimentoEm: dataAgora,
      );

      await _atualizarTokenAutenticacao(authUser);

      await _firestoreService.salvarUsuario(novoUsuario);
      criouUsuarioAgora = true;

      // Mantem sincronizacao best-effort para nao bloquear login social.
      try {
        await _firestoreService.sincronizarWhatsappAdminPadrao();
      } catch (_) {}

      usuario = await _firestoreService.getUsuario(uid);
    }

    if (usuario == null) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.cadastroUsuarioNaoEncontrado)),
      );
      await _auth.signOut();
      return false;
    }

    final usuarioAtual = usuario;
    VinculoClienteCadastroStatus? statusCadastroGoogle;

    if (validarCadastroGoogle) {
      statusCadastroGoogle = await _firestoreService
          .obterStatusVinculoClientePorEmail(
            email: usuarioAtual.email,
            uidFallback: uid,
            nomeFallback: (usuarioAtual.nomeCliente ?? usuarioAtual.nome).trim(),
            telefoneFallback:
                (usuarioAtual.telefonePrincipal ?? usuarioAtual.whatsapp ?? '')
                    .trim(),
          );
    }

    if (validarCadastroGoogle &&
        _usuarioPrecisaCompletarCadastroGoogle(
          usuarioAtual,
          statusCadastroGoogle,
        )) {
      if (!context.mounted) return false;
      _abrirFluxoCompletarCadastroGoogle(
        context,
        authUser: authUser,
        usuarioExistente: usuarioAtual,
        vinculoStatus: statusCadastroGoogle,
      );
      return true;
    }

    // Atualiza token sem bloquear o login caso a gravação falhe.
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestoreService.atualizarToken(uid, token);
      }
    } catch (_) {}

    if (!context.mounted) return false;

    if (validarCadastroGoogle &&
        criouUsuarioAgora &&
        statusCadastroGoogle != null &&
        statusCadastroGoogle.cadastroCompleto &&
        statusCadastroGoogle.vinculoIdCliente.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.vinculoClienteIdentificado(
              statusCadastroGoogle.vinculoIdCliente,
            ),
          ),
        ),
      );
    }

    // Sincronizar tema do usuário salvo no banco
    if (usuarioAtual.theme != null) {
      try {
        final themeEnum = AppThemeType.values.firstWhere(
          (e) => e.toString() == usuarioAtual.theme,
          orElse: () => AppThemeType.sistema,
        );
        MyApp.setCustomTheme(context, themeEnum);
      } catch (_) {}
    }

    // Redirecionar com base no tipo de usuário
    if (usuarioAtual.tipo == 'admin') {
      try {
        await FirestoreStructureHelper().inicializarSistemaCompleto();
      } catch (e) {
        debugPrint('Falha ao inicializar colecoes de entrada: $e');
      }

      if (!context.mounted) return false;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminAgendamentosView()),
      );
      return true;
    }

    if (usuarioAtual.aprovado) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AgendamentoView()),
      );
      return true;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AguardandoAprovacaoView(
          dataCadastro: usuarioAtual.dataCadastro ?? DateTime.now(),
        ),
      ),
    );
    return true;
  }

  void _abrirFluxoCompletarCadastroGoogle(
    BuildContext context, {
    required User authUser,
    required UsuarioModel? usuarioExistente,
    VinculoClienteCadastroStatus? vinculoStatus,
  }) {
    final email = (authUser.email ?? usuarioExistente?.email ?? '').trim();
    final nomeInicial = (vinculoStatus?.nomeSugerido ??
            usuarioExistente?.nomeCliente ??
            usuarioExistente?.nome ??
            _resolverNomeBaseUsuario(
              authUser,
              emailNormalizado: email.toLowerCase(),
            ))
        .trim();
    final whatsappInicial = (vinculoStatus?.telefoneSugerido ??
            usuarioExistente?.telefonePrincipal ??
            usuarioExistente?.whatsapp ??
            '')
        .trim();
    final vinculoIdCliente = (vinculoStatus?.vinculoIdCliente ?? '').trim();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpView(
          emailInicial: email,
          emailSomenteLeitura: true,
          modoCompletarCadastroGoogle: true,
          nomeInicial: nomeInicial,
          whatsappInicial: whatsappInicial,
          numeroEhWhatsappInicial: usuarioExistente?.numeroEhWhatsapp ?? true,
          vinculoIdCliente:
              vinculoIdCliente.isEmpty ? null : vinculoIdCliente,
          camposObrigatoriosPendentes:
              vinculoStatus?.camposObrigatoriosPendentes ?? const <String>[],
        ),
      ),
    );
  }

  bool _usuarioPrecisaCompletarCadastroGoogle(
    UsuarioModel usuario,
    VinculoClienteCadastroStatus? vinculoStatus,
  ) {
    if (usuario.tipo != 'cliente') return false;

    if (vinculoStatus != null && vinculoStatus.possuiVinculo) {
      return !vinculoStatus.cadastroCompleto;
    }

    final nome = (usuario.nomeCliente ?? usuario.nome).trim();
    final telefone =
        (usuario.telefonePrincipal ?? usuario.whatsapp ?? '').replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );

    return nome.isEmpty || telefone.length < 10 || !usuario.lgpdConsentido;
  }

  String _resolverNomeBaseUsuario(
    User authUser, {
    String? emailNormalizado,
  }) {
    final nomeExibicao = (authUser.displayName ?? '').trim();
    if (nomeExibicao.isNotEmpty) return nomeExibicao;

    final emailBase =
        (emailNormalizado ?? (authUser.email ?? '').trim().toLowerCase())
            .trim();
    if (emailBase.contains('@')) {
      return emailBase.split('@').first;
    }
    if (emailBase.isNotEmpty) {
      return emailBase;
    }

    return 'Cliente';
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
    UserCredential? credencialCriada;
    try {
      // 1. Criar usuário no Auth
      credencialCriada = await _auth
          .createUserWithEmailAndPassword(email: email, password: senha);

      if (credencialCriada.user != null) {
        final authUser = credencialCriada.user!;
        final uid = authUser.uid;
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
          ddi: '55',
          telefonePrincipal: whatsapp,
          numeroEhWhatsapp: numeroEhWhatsapp,
          locale: locale,
          adminAtreladaId: adminAtreladaId,
          devMaster: devMaster,
          lgpdConsentido: lgpdConsentido,
          lgpdConsentimentoEm: dataAgora,
        );

        await _atualizarTokenAutenticacao(authUser);

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
      final erroPermissaoFirestore =
          e is FirebaseException && e.code == 'permission-denied';

      // Evita conta parcialmente criada no Auth quando falha a escrita inicial no Firestore.
      if (erroPermissaoFirestore && credencialCriada?.user != null) {
        try {
          await credencialCriada!.user!.delete();
        } catch (_) {}
      }

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
        ).showSnackBar(
          SnackBar(
            content: Text(
              erroPermissaoFirestore
                  ? AppStrings.erroCadastroAppCheck
                  : AppStrings.erroCadastro,
            ),
          ),
        );
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

  Future<void> _atualizarTokenAutenticacao(User user) async {
    try {
      await user.getIdToken(true);
    } catch (_) {}
  }

  int _secondsFrom(Duration? duration) {
    if (duration == null) return 60;
    final seconds = duration.inSeconds;
    return seconds <= 0 ? 1 : seconds;
  }
}
