import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controller/firestore_service.dart';
import '../controller/agendamento_model.dart';
import '../usuario_model.dart';

class AdminAgendamentosView extends StatefulWidget {
  const AdminAgendamentosView({super.key});

  @override
  State<AdminAgendamentosView> createState() => _AdminAgendamentosViewState();
}

class _AdminAgendamentosViewState extends State<AdminAgendamentosView> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Administração'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_today), text: 'Agendamentos'),
              Tab(icon: Icon(Icons.person_add), text: 'Usuários'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            _buildAgendamentosTab(),
            _buildUsuariosTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendamentosTab() {
    return StreamBuilder<List<Agendamento>>(
        stream: _firestoreService.getAgendamentos(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filtrar apenas os pendentes
          final agendamentos = snapshot.data
                  ?.where((a) => a.status == 'pendente')
                  .toList() ??
              [];

          if (agendamentos.isEmpty) {
            return const Center(child: Text('Nenhum agendamento pendente.'));
          }

          return ListView.builder(
            itemCount: agendamentos.length,
            itemBuilder: (context, index) {
              final agendamento = agendamentos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(agendamento.dataHora),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Cliente: ${agendamento.clienteId}\nTipo: ${agendamento.tipo}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _atualizarStatus(agendamento, 'aprovado'),
                        tooltip: 'Aprovar',
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _atualizarStatus(agendamento, 'recusado'),
                        tooltip: 'Recusar',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
    );
  }

  Widget _buildUsuariosTab() {
    return StreamBuilder<List<UsuarioModel>>(
      stream: _firestoreService.getUsuariosPendentes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final usuarios = snapshot.data ?? [];

        if (usuarios.isEmpty) {
          return const Center(child: Text('Nenhum usuário pendente.'));
        }

        return ListView.builder(
          itemCount: usuarios.length,
          itemBuilder: (context, index) {
            final usuario = usuarios[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.orange),
                title: Text(usuario.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Email: ${usuario.email}\nCadastrado em: ${usuario.dataCadastro != null ? DateFormat('dd/MM/yyyy HH:mm').format(usuario.dataCadastro!) : '-'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => _aprovarUsuario(usuario),
                  tooltip: 'Aprovar Cadastro',
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _atualizarStatus(Agendamento agendamento, String novoStatus) async {
    if (agendamento.id == null) return;
    
    await _firestoreService.atualizarStatusAgendamento(agendamento.id!, novoStatus);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agendamento $novoStatus com sucesso!')),
      );
    }
  }

  Future<void> _aprovarUsuario(UsuarioModel usuario) async {
    await _firestoreService.aprovarUsuario(usuario.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuário ${usuario.nome} aprovado com sucesso!')),
      );
    }
  }
}