import 'package:flutter/material.dart';
import 'package:agenda/core/utils/app_strings.dart';
import 'package:agenda/main.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.flag, size: 24), // Bandeirinha
      tooltip: 'Alterar Idioma / Change Language',
      onSelected: (Locale locale) {
        MyApp.setLocale(context, locale);
        AppStrings.setLocale(locale); // Atualiza as strings estáticas
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
        const PopupMenuItem<Locale>(
          value: Locale('pt', 'BR'),
          child: Text('🇧🇷 Português'),
        ),
        const PopupMenuItem<Locale>(
          value: Locale('en', 'US'),
          child: Text('🇺🇸 English'),
        ),
        const PopupMenuItem<Locale>(
          value: Locale('es', 'ES'),
          child: Text('🇪🇸 Español'),
        ),
        const PopupMenuItem<Locale>(
          value: Locale('ja', 'JP'),
          child: Text('🇯🇵 日本語'),
        ),
      ],
    );
  }
}