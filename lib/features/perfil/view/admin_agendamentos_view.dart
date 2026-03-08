import 'package:flutter/material.dart';

class AdminAgendamentosView extends StatelessWidget {
  const AdminAgendamentosView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administração de Agendamentos')),
      body: const Center(child: Text('Tela de Administração')),
    );
  }
}