import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:agenda/main.dart' as app;
import 'package:agenda/view/app_strings.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Fluxo de Agendamento do Cliente', () {
    testWidgets('Cliente deve conseguir agendar um horário', (tester) async {
      // 1. Iniciar o App
      app.main();
      await tester.pumpAndSettle();

      // Pula onboarding se necessário
      final btnPular = find.text('Pular');
      if (btnPular.evaluate().isNotEmpty) {
        await tester.tap(btnPular);
        await tester.pumpAndSettle();
      }

      // 2. Login como Cliente
      // Nota: Em testes reais, idealmente usamos um emulador de Auth ou um usuário de teste fixo
      await tester.enterText(find.byType(TextField).at(0), 'cliente@teste.com');
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(1), '123456');
      await tester.pump();
      
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      await tester.tap(find.text(AppStrings.entrarBtn));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // 3. Navegar para Agendamento
      // Verifica se está na Home do Cliente (assumindo que tem um botão ou aba "Agendar")
      // Se for um FAB (Floating Action Button):
      final fabAgendar = find.byType(FloatingActionButton);
      if (fabAgendar.evaluate().isNotEmpty) {
        await tester.tap(fabAgendar);
      } else {
        // Ou procura por texto/ícone no menu
        await tester.tap(find.text('Novo Agendamento')); 
      }
      await tester.pumpAndSettle();

      // 4. Selecionar Serviço (Ex: Massagem Relaxante)
      // Assumindo um Dropdown ou Lista de Cards
      final servicoOption = find.text('Massagem Relaxante');
      if (servicoOption.evaluate().isNotEmpty) {
        await tester.tap(servicoOption);
        await tester.pumpAndSettle();
      }

      // 5. Selecionar Data (Date Picker)
      // Abre o seletor de data
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();
      // Seleciona o dia 15 (exemplo) ou o botão "OK" se já vier com data
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 6. Selecionar Horário (Time Picker ou Chips)
      // Assumindo Chips de horário
      final horarioChip = find.text('14:00'); // Tenta achar um horário específico
      if (horarioChip.evaluate().isNotEmpty) {
        await tester.tap(horarioChip);
      } else {
        // Fallback: clica no primeiro chip de horário disponível
        await tester.tap(find.byType(ChoiceChip).first);
      }
      await tester.pumpAndSettle();

      // 7. Confirmar Agendamento
      await tester.tap(find.text('Confirmar Agendamento'));
      await tester.pumpAndSettle();

      // 8. Verificar Sucesso
      // Espera ver uma mensagem de sucesso ou voltar para a lista
      expect(find.textContaining('sucesso'), findsOneWidget);
      // Ou verifica se o agendamento aparece na lista de "Meus Agendamentos"
    });
  });
}