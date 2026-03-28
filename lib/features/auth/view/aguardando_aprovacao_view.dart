import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:agenda/core/services/firestore_service.dart';
import 'package:agenda/app_localizations.dart';
import 'package:agenda/core/widgets/language_selector.dart';
import 'package:agenda/core/widgets/confetti_animation.dart';

class AguardandoAprovacaoView extends StatelessWidget {
  final DateTime dataCadastro;

  const AguardandoAprovacaoView({super.key, required this.dataCadastro});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.waitingApprovalTitle),
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
                    AppLocalizations.of(context)!.analysisTitle,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.analysisMessage(DateFormat('dd/MM/yyyy HH:mm').format(dataCadastro)),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _abrirWhatsApp,
                    icon: const Icon(Icons.chat),
                    label: Text(AppLocalizations.of(context)!.contactAdminButton),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                    child: Text(AppLocalizations.of(context)!.backToLoginButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomSheet: StreamBuilder<DateTime>(
        stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
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
    final firestoreService = FirestoreService();
    final authUser = FirebaseAuth.instance.currentUser;

    final config = await firestoreService.getContatoAprovacaoConfig();
    final usuario = authUser == null ? null : await firestoreService.getUsuario(authUser.uid);

    final nomeCliente = (usuario?.nomeCliente ?? usuario?.nome ?? authUser?.displayName ?? '').trim();
    final telefoneCliente =
        (usuario?.telefonePrincipal ?? usuario?.whatsapp ?? '').trim();
    final emailCliente = (usuario?.email ?? authUser?.email ?? '').trim();

    final mensagem = firestoreService.montarMensagemContatoAprovacao(
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