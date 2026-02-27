import 'package:flutter/material.dart';
import 'package:agenda/utils/app_strings.dart';

class TermosUsoView extends StatefulWidget {
  final VoidCallback onAceitar;

  const TermosUsoView({super.key, required this.onAceitar});

  @override
  State<TermosUsoView> createState() => _TermosUsoViewState();
}

class _TermosUsoViewState extends State<TermosUsoView> {
  bool _aceito = false;
  
  // Texto padrão dos termos.
  final String _textoTermos = AppStrings.termosUsoTexto;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.termosUsoTitulo),
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
              title: Text(AppStrings.termosUsoAceite),
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
                child: Text(AppStrings.termosUsoBotao, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}