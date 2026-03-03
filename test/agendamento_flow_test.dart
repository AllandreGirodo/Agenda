import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:agenda/controller/firestore_service.dart';
import 'package:agenda/controller/agendamento_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Fluxo de Agendamento (E2E)', () {
    late FirestoreService service;
    final String clienteIdTeste = 'test_integration_user';
    String? agendamentoIdCriado;

    setUpAll(() async {
      await Firebase.initializeApp();
      service = FirestoreService();
    });

    tearDownAll(() async {
      // Limpeza: Remove o agendamento criado após o teste
      if (agendamentoIdCriado != null) {
        await service.cancelarAgendamento(agendamentoIdCriado!, 'Limpeza de Teste', 'cancelado');
      }
    });

    testWidgets('Deve criar um agendamento e aprovar com sucesso', (WidgetTester tester) async {
      // 1. CRIAÇÃO (Simulando Cliente)
      final dataFutura = DateTime.now().add(const Duration(days: 2));
      
      final novoAgendamento = Agendamento(
        clienteId: clienteIdTeste,
        dataHora: dataFutura,
        tipo: 'Massagem',
        status: 'pendente',
        valorFinal: 150.0,
        avaliacao: 0,
        comentarioAvaliacao: '',
      );

      await service.salvarAgendamento(novoAgendamento);

      // 2. VERIFICAÇÃO DA CRIAÇÃO
      // Busca agendamentos do cliente para encontrar o ID gerado
      final listaAposCriacao = await service.getAgendamentosDoCliente(clienteIdTeste).first;
      final agendamentoSalvo = listaAposCriacao.firstWhere(
        (a) => a.tipo == 'Massagem' && a.status == 'pendente'
      );
      
      expect(agendamentoSalvo, isNotNull);
      agendamentoIdCriado = agendamentoSalvo.id;
      expect(agendamentoSalvo.status, 'pendente');

      // 3. APROVAÇÃO (Simulando Admin)
      // O método atualizarStatusAgendamento também lida com lógica de estoque e push notification
      await service.atualizarStatusAgendamento(agendamentoIdCriado!, 'aprovado', clienteId: clienteIdTeste);

      // 4. VERIFICAÇÃO DA APROVAÇÃO
      // Aguarda um pouco para a propagação no Firestore se necessário, ou busca novamente
      final listaAposAprovacao = await service.getAgendamentosDoCliente(clienteIdTeste).first;
      final agendamentoAprovado = listaAposAprovacao.firstWhere((a) => a.id == agendamentoIdCriado);

      expect(agendamentoAprovado.status, 'aprovado');
    });
  });
}