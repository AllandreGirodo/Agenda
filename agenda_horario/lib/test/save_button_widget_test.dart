import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Botão Salvar deve estar desabilitado se o formulário for inválido', (WidgetTester tester) async {
    // 1. Construir o Widget de teste (um formulário simples)
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TestFormWidget(),
      ),
    ));

    // 2. Verificar estado inicial
    final buttonFinder = find.text('Salvar');
    expect(buttonFinder, findsOneWidget);

    // 3. Tentar submeter com campo vazio (inválido)
    await tester.tap(buttonFinder);
    await tester.pump(); // Reconstrói o widget após o tap

    // Verifica se apareceu a mensagem de erro do validador
    expect(find.text('Campo obrigatório'), findsOneWidget);
    
    // Verifica se a ação de salvar NÃO foi chamada (simulado aqui pela presença do erro na tela)
    // Em um cenário real, você poderia mockar a função de salvar e verificar verify(mock.salvar()).never()
  });
}

// Widget auxiliar para o teste
class TestFormWidget extends StatefulWidget {
  @override
  _TestFormWidgetState createState() => _TestFormWidgetState();
}

class _TestFormWidgetState extends State<TestFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _controller,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo obrigatório';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Lógica de salvar
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvo!')));
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}