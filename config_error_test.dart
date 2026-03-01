import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:agenda/main.dart' as app;
import 'package:agenda/view/config_error_view.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Deve exibir ConfigErrorView quando .env estiver faltando (Simulação)', (WidgetTester tester) async {
    // Este teste assume que foi iniciado com:
    // --dart-define=ENV=inexistente (para falhar o carregamento do .env)
    // --dart-define=FORCE_CONFIG_CHECK=true (para exibir a tela de erro mesmo em debug)
    
    // Executa o main do app
    app.main();
    
    // Aguarda a renderização da interface
    await tester.pumpAndSettle();

    // Verifica se a tela de erro está presente
    expect(find.byType(ConfigErrorView), findsOneWidget);
    expect(find.text('Erro de Configuração'), findsOneWidget);
  });
}