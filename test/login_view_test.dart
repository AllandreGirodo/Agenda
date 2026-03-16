import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:agenda/features/auth/view/login_view.dart';
import 'package:agenda/core/utils/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Firebase.initializeApp();
  });

  testWidgets('LoginView deve exibir erro ao inserir credenciais inválidas', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginView()));
    await tester.pumpAndSettle();

    final emailFinder = find.byType(TextField).at(0);
    final passwordFinder = find.byType(TextField).at(1);

    await tester.enterText(emailFinder, 'email-invalido');
    await tester.enterText(passwordFinder, '123');
    await tester.pump();

    await tester.tap(find.text(AppStrings.entrarBtn));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SnackBar), findsOneWidget);
  });
}
