import 'package:flutter/material.dart';

enum AppThemeType {
  sistema,
  claro,
  escuro,
  natal,
  cyberpunk,
  tempestade,
  carnaval,
  diaDaMulher,
  outubroRosa,
  ferias
}

class CustomThemeData {
  final String label;
  final IconData? iconAsset;
  final Color iconColor;
  final List<Color> gradientColors;
  final String? soundAsset;
  final bool isAvailable;

  const CustomThemeData({
    required this.label,
    this.iconAsset,
    this.iconColor = Colors.white,
    this.gradientColors = const [],
    this.soundAsset,
    this.isAvailable = true,
  });

  static CustomThemeData getData(AppThemeType type) {
    switch (type) {
      case AppThemeType.sistema:
        return const CustomThemeData(label: 'Sistema');
      case AppThemeType.claro:
        return const CustomThemeData(label: 'Claro');
      case AppThemeType.escuro:
        return const CustomThemeData(label: 'Escuro');
      case AppThemeType.natal:
        return const CustomThemeData(
          label: 'Natal',
          iconAsset: Icons.ac_unit,
          gradientColors: [Color(0xFF16222A), Color(0xFF3A6073)],
        );
      case AppThemeType.cyberpunk:
        return const CustomThemeData(
          label: 'Cyberpunk',
          iconAsset: Icons.electrical_services,
          gradientColors: [Color(0xFF2b1055), Color(0xFF7597de)],
        );
      case AppThemeType.tempestade:
        return const CustomThemeData(
          label: 'Tempestade',
          iconAsset: Icons.flash_on,
          gradientColors: [Color(0xFF232526), Color(0xFF414345)],
        );
      case AppThemeType.carnaval:
        return const CustomThemeData(
          label: 'Carnaval',
          iconAsset: Icons.celebration,
          gradientColors: [Color(0xFFDA22FF), Color(0xFF9733EE)],
        );
      case AppThemeType.diaDaMulher:
        return const CustomThemeData(
          label: 'Dia da Mulher',
          iconAsset: Icons.favorite,
          gradientColors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
        );
      case AppThemeType.outubroRosa:
        return const CustomThemeData(
          label: 'Outubro Rosa',
          iconAsset: Icons.volunteer_activism,
          gradientColors: [Color(0xFFFF5F6D), Color(0xFFFFC371)],
        );
      case AppThemeType.ferias:
        return const CustomThemeData(
          label: 'Férias',
          iconAsset: Icons.beach_access,
          gradientColors: [Color(0xFF2980B9), Color(0xFF6DD5FA)],
        );
    }
  }
}