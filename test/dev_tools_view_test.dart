import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda/view/dev_tools_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  // Configura o mock do Firebase Core antes de rodar os testes
  setupFirebaseCoreMocks();

  testWidgets('DevToolsView deve exibir diálogo de senha ao iniciar', (WidgetTester tester) async {
    // 1. Carrega o widget DevToolsView dentro de um MaterialApp
    await tester.pumpWidget(const MaterialApp(
      home: DevToolsView(),
    ));

    // 2. O diálogo é exibido via addPostFrameCallback, então precisamos de um pump extra
    await tester.pump(); 

    // 3. Verifica se o diálogo (AlertDialog) está presente na árvore de widgets
    expect(find.byType(AlertDialog), findsOneWidget);
    
    // 4. Verifica o conteúdo textual do diálogo
    expect(find.text('Acesso ao Banco de Dados'), findsOneWidget);
    expect(find.text('Senha do Banco (DB Admin)'), findsOneWidget);
  });
}

// Função auxiliar para mockar a inicialização do Firebase
void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('plugins.flutter.io/firebase_core');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (MethodCall methodCall) async {
      if (methodCall.method == 'FirebaseApp#initializeApp') {
        return {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': dotenv.env['FIREBASE_API_KEY'] ?? '123',
            'appId': dotenv.env['FIREBASE_APP_ID'] ?? '123',
            'messagingSenderId': dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '123',
            'projectId': dotenv.env['FIREBASE_PROJECT_ID'] ?? '123',
          },
          'pluginConstants': {},
        };
      }
      return null;
    },
  );
}