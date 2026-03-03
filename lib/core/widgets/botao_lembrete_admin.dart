import 'package:flutter/material.dart';
import 'package:agenda/controller/firestore_service.dart';

class BotaoLembreteAdmin extends StatefulWidget {
  const BotaoLembreteAdmin({super.key});

  @override
  State<BotaoLembreteAdmin> createState() => _BotaoLembreteAdminState();
}

class _BotaoLembreteAdminState extends State<BotaoLembreteAdmin> {
  bool _isLoading = false;

  Future<void> _confirmarDisparo() async {
    final TextEditingController horasController = TextEditingController(text: '24');

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disparar Lembretes 🔔'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Deseja enviar notificações para agendamentos próximos?'),
            const SizedBox(height: 16),
            TextField(
              controller: horasController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Horas de antecedência',
                border: OutlineInputBorder(),
                suffixText: 'horas',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _isLoading = true);
      try {
        final horas = int.tryParse(horasController.text) ?? 24;
        final resultado = await FirestoreService().dispararLembretes(horas: horas);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(resultado['mensagem'] ?? 'Processo concluído!'),
            backgroundColor: Colors.green,
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao disparar: $e'),
            backgroundColor: Colors.red,
          ));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isLoading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.notifications_active),
      tooltip: 'Enviar Lembretes Manuais',
      onPressed: _isLoading ? null : _confirmarDisparo,
    );
  }
}
