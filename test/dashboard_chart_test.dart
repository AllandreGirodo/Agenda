import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda/view/dashboard_view.dart';
import 'package:agenda/controller/firestore_service.dart';
import 'package:agenda/controller/transacao_model.dart';
import 'package:agenda/controller/agendamento_model.dart';
import 'package:agenda/controller/estoque_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

// Mock manual do FirestoreService para evitar dependências complexas de mockito/build_runner
class MockFirestoreService extends FirestoreService {
  @override
  Stream<List<TransacaoFinanceira>> getTransacoes() {
    // Cria dados fictícios para o gráfico
    final hoje = DateTime.now();
    return Stream.value([
      TransacaoFinanceira(
        id: 't1',
        clienteUid: 'c1',
        valorBruto: 100.0,
        valorLiquido: 100.0,
        metodoPagamento: 'pix',
        dataPagamento: hoje, // Venda hoje
        criadoPorUid: 'admin',
      ),
      TransacaoFinanceira(
        id: 't2',
        clienteUid: 'c2',
        valorBruto: 50.0,
        valorLiquido: 50.0,
        metodoPagamento: 'dinheiro',
        dataPagamento: hoje.subtract(const Duration(days: 1)), // Venda ontem
        criadoPorUid: 'admin',
      ),
    ]);
  }

  // Mocks dos outros streams chamados no build para evitar erros de null
  @override
  Stream<List<Agendamento>> getAgendamentos() => Stream.value([]);
  
  @override
  Stream<List<ItemEstoque>> getEstoque() => Stream.value([]);
  
  @override
  Stream<bool> getManutencaoStream() => Stream.value(false);
}

void main() {
  // Setup necessário para mocks do Firebase Core se houver chamadas estáticas
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
    // Carrega variáveis de ambiente vazias para evitar erro no dotenv
    dotenv.testLoad(fileInput: 'ADMIN_EMAIL=teste@admin.com');
  });

  testWidgets('DashboardView deve renderizar o gráfico financeiro com dados', (WidgetTester tester) async {
    // 1. Inicializa o Mock
    final mockService = MockFirestoreService();

    // 2. Constrói a View injetando o Mock
    // Envolvemos em MaterialApp para fornecer contexto de tema e navegação
    await tester.pumpWidget(MaterialApp(
      home: DashboardView(firestoreService: mockService),
    ));

    // 3. Aguarda a renderização dos Streams (pump)
    await tester.pumpAndSettle();

    // 4. Verificações
    
    // Verifica se o título do gráfico está presente
    expect(find.textContaining('Faturamento (Últimos 7 dias)'), findsOneWidget);

    // Verifica se o Widget do gráfico (BarChart) foi renderizado
    expect(find.byType(BarChart), findsOneWidget);

    // Opcional: Verificar se não há indicadores de carregamento infinitos
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Dropdown de filtro de dias deve atualizar o título do gráfico', (WidgetTester tester) async {
    final mockService = MockFirestoreService();

    await tester.pumpWidget(MaterialApp(
      home: DashboardView(firestoreService: mockService),
    ));
    await tester.pumpAndSettle();

    // 1. Verifica estado inicial (7 dias)
    expect(find.textContaining('Faturamento (Últimos 7 dias)'), findsOneWidget);

    // 2. Abre o Dropdown
    // O DropdownButton geralmente tem uma chave ou pode ser encontrado pelo tipo
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();

    // 3. Seleciona a opção '15 dias' no menu aberto
    // Nota: O texto '15 dias' aparece no menu suspenso
    await tester.tap(find.text('15 dias').last);
    await tester.pumpAndSettle();

    // 4. Verifica se o título atualizou para 15 dias
    expect(find.textContaining('Faturamento (Últimos 7 dias)'), findsNothing);
    expect(find.textContaining('Faturamento (Últimos 15 dias)'), findsOneWidget);
  });
}

// Função auxiliar padrão para testes que envolvem Firebase
void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Mock do canal do Firebase Core (necessário pois o main.dart ou serviços podem chamar initializeApp)
  // Nota: Como estamos mockando o Service, o FirebaseFirestore.instance não deve ser chamado nos métodos testados,
  // mas o Firebase.initializeApp no setUpAll exige isso.
  // (O código de setup do mock channel é interno do flutter_test ou firebase_core_platform_interface, 
  // mas em testes simples de widget com serviço mockado, apenas o initializeApp no setup costuma bastar).
}