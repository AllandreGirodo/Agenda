import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:agenda/core/services/firestore_service.dart';
import 'package:agenda/app_localizations.dart';
import 'package:agenda/core/widgets/language_selector.dart';
import 'package:agenda/core/widgets/confetti_animation.dart';

class AguardandoAprovacaoView extends StatefulWidget {
  final DateTime dataCadastro;

  const AguardandoAprovacaoView({super.key, required this.dataCadastro});

  @override
  State<AguardandoAprovacaoView> createState() =>
      _AguardandoAprovacaoViewState();
}

class _AguardandoAprovacaoViewState extends State<AguardandoAprovacaoView> {
  final FirestoreService _firestoreService = FirestoreService();
  late final Future<ContatoAprovacaoConfig> _contatoConfigFuture;

  @override
  void initState() {
    super.initState();
    _contatoConfigFuture = _firestoreService.getContatoAprovacaoConfig();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.waitingApprovalTitle),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: const [LanguageSelector()],
        automaticallyImplyLeading: false, // Remove botão de voltar para não burlar
      ),
      body: ConfettiAnimation(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 80, color: Colors.orange),
                  const SizedBox(height: 24),
                  Text(
                    localizations.analysisTitle,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.analysisMessage(
                      DateFormat('dd/MM/yyyy HH:mm').format(widget.dataCadastro),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  FutureBuilder<ContatoAprovacaoConfig>(
                    future: _contatoConfigFuture,
                    builder: (context, snapshot) {
                      final nomeAdmin =
                          (snapshot.data?.nomeAdministradoraExibicao ?? '').trim();
                      final label = nomeAdmin.isEmpty
                          ? localizations.contactAdminButton
                          : localizations.contactAdminButtonWithName(nomeAdmin);

                      return ElevatedButton.icon(
                        onPressed: _abrirWhatsApp,
                        icon: const Icon(Icons.chat),
                        label: Text(label),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                    child: Text(localizations.backToLoginButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomSheet: StreamBuilder<DateTime>(
        stream: Stream.periodic(
          const Duration(seconds: 1),
          (_) => DateTime.now(),
        ).asBroadcastStream(),
        builder: (context, snapshot) {
          final now = snapshot.data ?? DateTime.now();
          final user = FirebaseAuth.instance.currentUser;
          return Container(
            width: double.infinity,
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Validação: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(now)}\nUsuário: ${user?.email ?? "N/A"}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
          );
        },
      ),
    );
  }

  Future<void> _abrirWhatsApp() async {
    final authUser = FirebaseAuth.instance.currentUser;

    final config = await _firestoreService.getContatoAprovacaoConfig();
    final usuario =
        authUser == null ? null : await _firestoreService.getUsuario(authUser.uid);

    final nomeCliente = (usuario?.nomeCliente ?? usuario?.nome ?? authUser?.displayName ?? '').trim();
    final telefoneCliente =
        (usuario?.telefonePrincipal ?? usuario?.whatsapp ?? '').trim();
    final emailCliente = (usuario?.email ?? authUser?.email ?? '').trim();

    final mensagem = _firestoreService.montarMensagemContatoAprovacao(
      config: config,
      clienteNome: nomeCliente,
      clienteTelefone: telefoneCliente,
      clienteEmail: emailCliente,
      dataHora: DateTime.now(),
    );

    final phone = config.whatsappRedirecionamento.trim();
    if (phone.isEmpty) {
      debugPrint('WhatsApp admin nao configurado em configuracoes/geral.');
      return;
    }

    final whatsappUrl = Uri.parse(
      'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(mensagem)}',
    );
    final webUrl = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(mensagem)}',
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Não foi possível abrir o WhatsApp.');
    }
  }
}