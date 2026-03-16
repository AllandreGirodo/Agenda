import 'package:flutter/material.dart';
import 'package:agenda/core/utils/app_strings.dart';

class TermosUsoView extends StatefulWidget {
  const TermosUsoView({super.key});

  @override
  State<TermosUsoView> createState() => _TermosUsoViewState();
}

class _TermosUsoViewState extends State<TermosUsoView> {
  bool _aceito = false;

  // Texto padrão dos termos.
  final String _textoTermos = AppStrings.termosUsoTexto;

  List<TextSpan> _parseMarkdownBold(String text, TextStyle boldStyle) {
    final spans = <TextSpan>[];
    // Aceita negrito no formato **texto** e ***texto***.
    final matches = RegExp(r'(\*{2,3})(.+?)\1').allMatches(text).toList();

    if (matches.isEmpty) {
      spans.add(TextSpan(text: text));
      return spans;
    }

    var currentIndex = 0;
    for (final match in matches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }

      spans.add(TextSpan(text: match.group(2), style: boldStyle));
      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return spans;
  }

  Widget _buildTermosComNegrito(BuildContext context) {
    final baseStyle =
        Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.5) ??
        const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87);
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);

    final spans = <TextSpan>[];
    final linhas = _textoTermos.split('\n');

    for (final linha in linhas) {
      spans.addAll(_parseMarkdownBold(linha, boldStyle));
      spans.add(const TextSpan(text: '\n'));
    }

    return SelectableText.rich(TextSpan(style: baseStyle, children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: AppStrings.voltar,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          AppStrings.termosUsoTitulo,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, height: 1.2),
        ),
        centerTitle: true,
        titleSpacing: 8,
        toolbarHeight: 72,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildTermosComNegrito(context),
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
                onPressed: _aceito
                    ? () => Navigator.of(context).pop(true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: Text(
                  AppStrings.termosUsoBotao,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
