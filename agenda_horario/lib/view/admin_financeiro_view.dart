import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controller/firestore_service.dart';
import '../controller/transacao_model.dart';
import '../controller/cliente_model.dart';
import 'admin_nova_transacao_view.dart';

class AdminFinanceiroView extends StatelessWidget {
  const AdminFinanceiroView({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminNovaTransacaoView()));
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<TransacaoFinanceira>>(
        stream: firestoreService.getTransacoes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final transacoes = snapshot.data ?? [];
          if (transacoes.isEmpty) return const Center(child: Text('Nenhuma transação registrada.'));

          return ListView.builder(
            itemCount: transacoes.length,
            itemBuilder: (context, index) {
              final t = transacoes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: t.statusPagamento == 'pago' ? Colors.green : Colors.orange,
                    child: Icon(t.statusPagamento == 'pago' ? Icons.check : Icons.access_time, color: Colors.white),
                  ),
                  title: Text('R\$ ${t.valorLiquido.toStringAsFixed(2)}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<Cliente?>(
                        future: firestoreService.getCliente(t.clienteUid),
                        builder: (context, snapshot) {
                          return Text(snapshot.data?.nome ?? 'Cliente: ${t.clienteUid}');
                        },
                      ),
                      Text('${t.metodoPagamento.toUpperCase()} - ${DateFormat('dd/MM/yyyy').format(t.dataPagamento)}'),
                    ],
                  ),
                  trailing: Text(t.statusPagamento.toUpperCase(), style: TextStyle(
                    color: t.statusPagamento == 'pago' ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold
                  )),
                ),
              );
            },
          );
        },
      ),
    );
  }
}