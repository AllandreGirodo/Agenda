import 'package:flutter_test/flutter_test.dart';
import 'package:agenda/controller/agendamento_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('AgendamentoModel - Testes de Serialização', () {
    test('Deve converter objeto para Map (toMap) corretamente', () {
      final dataHora = DateTime(2023, 12, 25, 14, 30);
      final agendamento = Agendamento(
        id: '123',
        clienteId: 'user_001',
        dataHora: dataHora,
        tipo: 'Massagem Relaxante',
        status: 'pendente',
        valorFinal: 120.0,
        avaliacao: 0,
        comentarioAvaliacao: '',
        clienteNomeSnapshot: 'Maria',
        clienteTelefoneSnapshot: '11999999999',
      );

      final map = agendamento.toMap();

      expect(map['cliente_id'], 'user_001');
      expect(map['tipo_massagem'], 'Massagem Relaxante');
      expect(map['preco'], 120.0);
      expect(map['status'], 'pendente');
      // Verifica se a data foi mantida (seja como DateTime ou Timestamp, dependendo da implementação)
      expect(map['data_hora'], isNotNull);
    });

    test('Deve criar objeto a partir do Map (fromMap) lidando com Timestamp', () {
      final dataHora = DateTime(2023, 12, 25, 14, 30);
      final timestamp = Timestamp.fromDate(dataHora);

      final mapFirestore = {
        'cliente_id': 'user_002',
        'data_hora': timestamp, // Simula o retorno do Firestore
        'tipo_massagem': 'Drenagem',
        'status': 'aprovado',
        'preco': 150.0,
        'avaliacao': 5,
        'comentario_avaliacao': 'Excelente',
      };

      final agendamento = Agendamento.fromMap(mapFirestore, id: '999');

      expect(agendamento.id, '999');
      expect(agendamento.dataHora, dataHora); // Verifica se converteu Timestamp -> DateTime
      expect(agendamento.tipo, 'Drenagem');
    });
  });
}