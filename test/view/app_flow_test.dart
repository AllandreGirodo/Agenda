import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:agenda/main.dart' as app;
import 'package:agenda/view/app_strings.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Fluxo Completo de App', () {
    testWidgets('Deve realizar login e visualizar o dashboard', (tester) async {
      // 1. Iniciar o aplicativo
      // Chamamos o main() do app para garantir que toda a inicialização (Firebase, etc) ocorra.
      app.main();
      
      // Aguarda o app carregar e estabilizar (Splash/Onboarding/Login)
      await tester.pumpAndSettle();

      // Se cair no Onboarding, pula para o Login
      final btnPular = find.text('Pular'); // Ajuste conforme o texto real do seu Onboarding
      if (btnPular.evaluate().isNotEmpty) {
        await tester.tap(btnPular);
        await tester.pumpAndSettle();
      }

      // 2. Verificar se está na tela de Login
      expect(find.text(AppStrings.loginTitulo), findsOneWidget);

      // 3. Preencher credenciais (Admin)
      // Encontra os campos de texto. Geralmente o primeiro é email e o segundo senha.
      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);

      await tester.enterText(emailField, 'admin@teste.com');
      await tester.pump();
      await tester.enterText(passwordField, '123456');
      await tester.pump();

      // Fecha o teclado para garantir que o botão esteja visível
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // 4. Clicar em Entrar
      final btnEntrar = find.text(AppStrings.entrarBtn);
      await tester.tap(btnEntrar);

      // 5. Aguardar navegação e processamento do Firebase Auth
      // pumpAndSettle aguarda todas as animações e microtarefas terminarem
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // 6. Verificar se chegou no Dashboard Administrativo
      // O título da AppBar na AdminAgendamentosView é 'Administração'
      expect(find.text('Administração'), findsOneWidget);

      // Verifica se a tab de Dashboard está presente
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
      
      // Opcional: Verificar se o gráfico carregou
      expect(find.text('Agendamentos (Dia)'), findsOneWidget);
    });
  });
}