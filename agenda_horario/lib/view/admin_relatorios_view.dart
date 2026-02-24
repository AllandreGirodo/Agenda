import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controller/firestore_service.dart';
import '../controller/agendamento_model.dart';

class AdminRelatoriosView extends StatelessWidget {
  const AdminRelatoriosView({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios Gerenciais'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Agendamento>>(
        stream: firestoreService.getAgendamentos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final agendamentos = snapshot.data!;
          final now = DateTime.now();
          final mesAtual = DateTime(now.year, now.month);
          
          // Filtrar agendamentos do mês atual
          final agendamentosMes = agendamentos.where((a) => 
            a.dataHora.year == now.year && a.dataHora.month == now.month
          ).toList();

          if (agendamentosMes.isEmpty) {
            return const Center(child: Text('Sem dados para este mês.'));
          }

          // Métricas
          final total = agendamentosMes.length;
          final cancelados = agendamentosMes.where((a) => a.status.contains('cancelado') || a.status == 'recusado').length;
          final realizados = agendamentosMes.where((a) => a.status == 'aprovado').length; // Considerando aprovados como realizados/futuros confirmados
          
          final taxaCancelamento = total > 0 ? (cancelados / total) * 100 : 0.0;
          final taxaOcupacao = total > 0 ? (realizados / total) * 100 : 0.0; // Simplificado: Ocupação sobre o total agendado

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Resumo de ${DateFormat('MMMM yyyy', 'pt_BR').format(now)}', 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Total Agendado', '$total', Colors.blue)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildMetricCard('Realizados/Conf.', '$realizados', Colors.green)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Cancelados', '$cancelados', Colors.red)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildMetricCard('Taxa Cancelamento', '${taxaCancelamento.toStringAsFixed(1)}%', Colors.orange)),
                ],
              ),

              const SizedBox(height: 30),
              const Text('Detalhamento de Cancelamentos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              ...agendamentosMes.where((a) => a.status.contains('cancelado')).map((a) {
                return ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.red),
                  title: Text(DateFormat('dd/MM HH:mm').format(a.dataHora)),
                  subtitle: Text(a.motivoCancelamento ?? 'Sem motivo registrado'),
                  trailing: Text(a.status == 'cancelado_tardio' ? 'Tardio' : 'Normal', 
                    style: TextStyle(color: a.status == 'cancelado_tardio' ? Colors.purple : Colors.grey)),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.3))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[800]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}