import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agenda/view/db_seeder.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Testes de Integração - DbSeeder', () {
    setUpAll(() async {
      await Firebase.initializeApp();
    });

    testWidgets('Deve popular a coleção de cupons corretamente', (WidgetTester tester) async {
      // 1. Preparação: Garante que o cupom de teste não existe antes do teste
      final docRef = FirebaseFirestore.instance.collection('cupons').doc('BEMVINDO');
      await docRef.delete();

      // 2. Ação: Executa o Seeder
      await DbSeeder.seedCupons();

      // 3. Verificação: Busca o documento no Firestore real
      final docSnapshot = await docRef.get();

      expect(docSnapshot.exists, isTrue, reason: 'O documento do cupom deveria ter sido criado');
      
      final data = docSnapshot.data();
      expect(data, isNotNull);
      expect(data!['codigo'], 'BEMVINDO');
      expect(data['tipo'], 'porcentagem');
      expect(data['valor'], 10.0);
      expect(data['ativo'], true);
      // Verifica se a validade é uma data futura
      expect((data['validade'] as Timestamp).toDate().isAfter(DateTime.now()), isTrue);
    });
  });
}