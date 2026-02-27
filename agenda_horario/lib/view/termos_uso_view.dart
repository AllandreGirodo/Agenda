import 'package:flutter/material.dart';

class TermosUsoView extends StatefulWidget {
  final VoidCallback onAceitar;

  const TermosUsoView({super.key, required this.onAceitar});

  @override
  State<TermosUsoView> createState() => _TermosUsoViewState();
}

class _TermosUsoViewState extends State<TermosUsoView> {
  bool _aceito = false;
  
  // Texto padrão dos termos.
  final String _textoTermos = """
1. Aceitação dos Termos
Ao utilizar este aplicativo para agendamento de serviços de massoterapia, você concorda com os termos descritos abaixo.

2. Agendamentos e Cancelamentos
Os cancelamentos devem ser feitos respeitando a antecedência mínima configurada no sistema. Cancelamentos tardios ou não comparecimento podem estar sujeitos a restrições em agendamentos futuros.

3. Saúde e Anamnese
É responsabilidade do cliente informar condições de saúde, alergias, cirurgias recentes e uso de medicamentos na ficha de anamnese. A omissão de dados pode acarretar riscos à saúde durante o procedimento.

4. Privacidade e Dados (LGPD)
Seus dados pessoais são coletados para fins de cadastro e histórico de atendimento. Você tem o direito de solicitar a anonimização da sua conta a qualquer momento através das configurações do perfil.

5. Pagamentos
Os valores dos serviços e pacotes estão sujeitos a alteração. O pagamento deve ser realizado conforme combinado com a profissional.
""";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos de Uso'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Impede voltar sem aceitar se for modal obrigatório
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                _textoTermos,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ),
          const Divider(height: 1),
          Container(
            color: Colors.grey.shade50,
            child: CheckboxListTile(
              title: const Text('Li e concordo com os Termos de Uso e Política de Privacidade.'),
              value: _aceito,
              onChanged: (val) => setState(() => _aceito = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Colors.teal,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _aceito ? widget.onAceitar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text('Confirmar e Continuar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}