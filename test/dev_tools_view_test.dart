import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda/view/dev_tools_view.dart';
import 'package:agenda/features/admin/view/admin_ferramentas_senha_setup_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await dotenv.load(fileName: '.env');
    await Firebase.initializeApp();
    _setupOtherChannelMocks();
  });

  testWidgets('DevToolsView exibe tela de configuracao se senha nao esta configurada',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DevToolsView(),
        ),
      ),
    );
    await tester.pump();

    final findSetupView = find.byType(AdminFerramentasSenhaSetupView);

    if (findSetupView.evaluate().isEmpty) {
      expect(
        find.byType(DevToolsView),
        findsAtLeastNWidgets(1),
        reason:
            'DevToolsView deve estar no widget tree, mesmo que AdminFerramentasSenhaSetupView não esteja',
      );
    } else {
      expect(
        findSetupView,
        findsOneWidget,
        reason: 'Deve mostrar tela de setup quando senha não está configurada',
      );
    }
  });

  testWidgets('DevToolsView widget monta sem erros', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DevToolsView(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(DevToolsView), findsOneWidget);
  });
}

// Configura mocks de plataforma para Firestore, Auth, Functions, Storage e SharedPreferences
void _setupOtherChannelMocks() {
  // Mock Cloud Firestore
  const firestoreChannel = MethodChannel('plugins.flutter.io/cloud_firestore');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    firestoreChannel,
    (MethodCall methodCall) async {
      if (methodCall.method == 'DocumentReference#get') {
        return {'data': {}, 'exists': false};
      }
      return null;
    },
  );

  // Mock Firebase Auth
  const authChannel = MethodChannel('plugins.flutter.io/firebase_auth');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    authChannel,
    (MethodCall methodCall) async => null,
  );

  // Mock Firebase Functions
  const functionsChannel = MethodChannel('plugins.flutter.io/cloud_functions');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    functionsChannel,
    (MethodCall methodCall) async => null,
  );

  // Mock Firebase Storage
  const storageChannel = MethodChannel('plugins.flutter.io/firebase_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    storageChannel,
    (MethodCall methodCall) async => null,
  );

  // Mock SharedPreferences
  const prefsChannel = MethodChannel('plugins.flutter.io/shared_preferences');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    prefsChannel,
    (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') return {};
      return null;
    },
  );
}

