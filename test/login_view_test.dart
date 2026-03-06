import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda/view/login_view.dart';
import 'package:flutter/services.dart';

void main() {
  // Configura mocks do Firebase Core e Auth
  setupFirebaseMocks();

  testWidgets('LoginView deve exibir erro ao inserir credenciais inválidas', (WidgetTester tester) async {
    // 1. Carrega o widget LoginView
    // Envolvemos em MaterialApp e ScaffoldMessenger para capturar SnackBars
    await tester.pumpWidget(const MaterialApp(
      home: LoginView(),
    ));

    // 2. Encontra os campos de texto (Email e Senha)
    // Assume-se que existem 2 TextFormFields na tela
    final emailFinder = find.byType(TextFormField).at(0);
    final passwordFinder = find.byType(TextFormField).at(1);
    
    // Tenta encontrar o botão pelo texto (ajuste conforme o texto real do seu app: 'Entrar', 'Login', etc)
    final buttonFinder = find.text('Entrar'); 

    // 3. Interage com os widgets
    await tester.enterText(emailFinder, 'usuario@teste.com');
    await tester.enterText(passwordFinder, 'senhaerrada');
    await tester.pump(); // Reconstrói para atualizar estado

    // Garante que o botão foi encontrado antes de clicar
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    
    // 4. Aguarda o processamento (simulação do delay da auth)
    await tester.pump(); 

    // 5. Verifica se uma mensagem de erro apareceu (SnackBar ou Dialog)
    // O texto exato depende da sua implementação de tratamento de erro
    expect(find.byType(SnackBar), findsOneWidget);
    // Opcional: verificar texto específico se souber a mensagem exata
    // expect(find.textContaining('Erro'), findsOneWidget);
  });
}

void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock do Firebase Core
  const MethodChannel channelCore = MethodChannel('plugins.flutter.io/firebase_core');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    channelCore,
    (MethodCall methodCall) async {
      if (methodCall.method == 'FirebaseApp#initializeApp') {
        return {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': '123',
            'appId': '123',
            'messagingSenderId': '123',
            'projectId': '123',
          },
          'pluginConstants': {},
        };
      }
      return null;
    },
  );

  // Mock do Firebase Auth para simular erro
  const MethodChannel channelAuth = MethodChannel('plugins.flutter.io/firebase_auth');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    channelAuth,
    (MethodCall methodCall) async {
      if (methodCall.method == 'signInWithEmailAndPassword') {
        // Simula erro de credenciais inválidas
        throw PlatformException(
          code: 'INVALID_LOGIN_CREDENTIALS', 
          message: 'A senha é inválida ou o usuário não tem senha.',
        );
      }
      return null;
    },
  );
}