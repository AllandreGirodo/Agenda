import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // Requer adicionar ao pubspec.yaml
import '../controller/firestore_service.dart';
import '../app_localizations.dart';
import '../widgets/language_selector.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              onPressed: () => Navigator.of(context).pop(), // Voltar para Login
              child: Text(AppLocalizations.of(context)!.backToLoginButton),
            ),
          ],
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
    // Busca o número atualizado do banco de dados
    final firestoreService = FirestoreService();
    final phone = await firestoreService.getTelefoneAdmin();
    const message = 'Olá! Acabei de me cadastrar no app e aguardo aprovação.';
    
    // Tenta abrir diretamente o app do WhatsApp
    final whatsappUrl = Uri.parse('whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}');
    // Link alternativo para navegador (caso não tenha o app)
    final webUrl = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Não foi possível abrir o WhatsApp.');
    }
  }
}