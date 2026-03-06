import 'package:flutter_test/flutter_test.dart';
import 'package:agenda/controller/transacao_model.dart';

void main() {
  group('TransacaoFinanceira', () {
    test('Deve instanciar corretamente e validar o cálculo do valor líquido', () {
      // Cenário: Venda de R$ 100,00 com R$ 10,00 de desconto
      const double valorBruto = 100.00;
      const double valorDesconto = 10.00;
      const double valorLiquidoEsperado = 90.00;

      final transacao = TransacaoFinanceira(
        clienteUid: 'cliente_123',
        valorBruto: valorBruto,
        valorDesconto: valorDesconto,
        valorLiquido: valorBruto - valorDesconto, // Simulando o cálculo que ocorre na View/Controller
        metodoPagamento: 'pix',
        dataPagamento: DateTime.now(),
        criadoPorUid: 'admin_user',
      );

      // Verificações
      expect(transacao.valorBruto, 100.00);
      expect(transacao.valorDesconto, 10.00);
      expect(transacao.valorLiquido, valorLiquidoEsperado);
      
      // Garante que o líquido não é maior que o bruto (regra de negócio básica)
      expect(transacao.valorLiquido, lessThanOrEqualTo(transacao.valorBruto));
    });

    test('Deve converter para Map e voltar (Serialização Firestore)', () {
      final dataPagamento = DateTime(2023, 10, 25, 14, 30);
      final transacao = TransacaoFinanceira(
        id: 'transacao_abc',
        clienteUid: 'cliente_123',
        valorBruto: 150.0,
        valorLiquido: 150.0,
        metodoPagamento: 'cartao',
        dataPagamento: dataPagamento,
        criadoPorUid: 'admin',
      );

      final map = transacao.toMap();
      final novaTransacao = TransacaoFinanceira.fromMap(map, id: 'transacao_abc');

      expect(novaTransacao.valorLiquido, 150.0);
      expect(novaTransacao.metodoPagamento, 'cartao');
      // Nota: Timestamp do Firestore perde precisão de microsegundos, então comparamos segundos ou usamos matchers flexíveis se necessário
      expect(novaTransacao.dataPagamento.millisecondsSinceEpoch, dataPagamento.millisecondsSinceEpoch);
    });

    test('Deve calcular valor líquido via método estático (com proteção contra negativo)', () {
      // Cálculo normal
      expect(TransacaoFinanceira.calcularValorLiquido(100.0, 10.0), 90.0);
      
      // Cálculo onde desconto é maior que o valor (deve retornar 0)
      expect(TransacaoFinanceira.calcularValorLiquido(50.0, 60.0), 0.0);
    });
  });
}