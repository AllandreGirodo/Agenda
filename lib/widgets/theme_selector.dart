import 'package:flutter/material.dart';
import 'package:agenda/widgets/theme_preview_dialog.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.palette),
      tooltip: 'Alterar Tema',
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const ThemePreviewDialog(),
        );
      },
    );
  }
}