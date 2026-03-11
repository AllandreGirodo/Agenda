import 'package:flutter/material.dart';
import 'package:agenda/core/utils/app_strings.dart';
import 'package:agenda/main.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLocale = Localizations.localeOf(context);

    final options = <_LanguageMenuOption>[
      _LanguageMenuOption(
        locale: const Locale('pt', 'BR'),
        label: AppStrings.idiomaPortugues,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      _LanguageMenuOption(
        locale: const Locale('en', 'US'),
        label: AppStrings.idiomaIngles,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.2),
      ),
      _LanguageMenuOption(
        locale: const Locale('es', 'ES'),
        label: AppStrings.idiomaEspanhol,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
      ),
      _LanguageMenuOption(
        locale: const Locale('ja', 'JP'),
        label: AppStrings.idiomaJapones,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamilyFallback: ['Noto Sans JP', 'Noto Sans CJK JP'],
        ),
      ),
    ];

    return PopupMenuButton<Locale>(
      initialValue: _closestLocale(currentLocale, options),
      icon: const Icon(Icons.flag, size: 24), // Bandeirinha
      tooltip: AppStrings.tooltipAlterarIdioma,
      onSelected: (Locale locale) {
        MyApp.setLocale(context, locale);
        AppStrings.setLocale(locale); // Atualiza as strings estáticas
      },
      itemBuilder: (BuildContext context) {
        return options.map((option) {
          final isSelected = _sameLanguage(currentLocale, option.locale);
          final textStyle = option.style.copyWith(
            fontSize: (option.style.fontSize ?? 14) + (isSelected ? 2 : 0),
            fontWeight: isSelected ? FontWeight.w700 : option.style.fontWeight,
            color: isSelected ? theme.colorScheme.primary : null,
          );

          return PopupMenuItem<Locale>(
            value: option.locale,
            child: Row(
              children: [
                Expanded(
                  child: Text(option.label, style: textStyle),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Locale _closestLocale(Locale current, List<_LanguageMenuOption> options) {
    for (final option in options) {
      if (_sameLanguage(current, option.locale)) {
        return option.locale;
      }
    }
    return options.first.locale;
  }

  bool _sameLanguage(Locale a, Locale b) {
    return a.languageCode == b.languageCode;
  }
}

class _LanguageMenuOption {
  final Locale locale;
  final String label;
  final TextStyle style;

  const _LanguageMenuOption({
    required this.locale,
    required this.label,
    required this.style,
  });
}