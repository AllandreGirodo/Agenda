import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../controller/firestore_service.dart';

class AdminLgpdLogsView extends StatelessWidget {
  const AdminLgpdLogsView({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoria LGPD'),
        backgroundColor: Colors.purple, // Cor distinta para indicar área sensível
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestoreService.getLgpdLogs(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('Nenhum registro de auditoria LGPD encontrado.'),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final log = logs[index];
              final timestamp = log['data_hora'] as Timestamp?;
              final dataFormatada = timestamp != null 
                  ? DateFormat('dd/MM/yyyy HH:mm:ss').format(timestamp.toDate()) 
                  : 'Data desconhecida';

              return ListTile(
                leading: const Icon(Icons.privacy_tip, color: Colors.purple),
                title: Text(log['acao'] ?? 'Ação Desconhecida', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Data: $dataFormatada\nID Usuário: ${log['usuario_id']}\nMotivo: ${log['motivo']}'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}