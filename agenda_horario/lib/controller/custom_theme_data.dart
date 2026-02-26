import 'package:flutter/material.dart';

enum AppThemeType {
  sistema,
  claro,
  escuro,
  flores,
  aurora,
  junina,
  natal,
  pascoaCoelho,
  pascoaCristo,
  halloween,
  manha,
  tarde,
  noite
}

class CustomThemeData {
  final AppThemeType type;
  final String label;
  final List<Color> gradientColors;
  final IconData? iconAsset;
  final Color iconColor;

  const CustomThemeData({
    required this.type,
    required this.label,
    required this.gradientColors,
    this.iconAsset,
    this.iconColor = Colors.white24,
  });

  static CustomThemeData getData(AppThemeType type) {
    switch (type) {
      case AppThemeType.flores:
        return const CustomThemeData(
          type: AppThemeType.flores,
          label: 'Primavera / Flores',
          gradientColors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)], // Rosa claro
          iconAsset: Icons.local_florist,
          iconColor: Colors.pinkAccent,
        );
      case AppThemeType.aurora:
        return const CustomThemeData(
          type: AppThemeType.aurora,
          label: 'Aurora Boreal',
          gradientColors: [Color(0xFF4A148C), Color(0xFF00695C)], // Roxo e Verde
          iconAsset: Icons.auto_awesome,
          iconColor: Colors.cyanAccent,
        );
      case AppThemeType.junina:
        return const CustomThemeData(
          type: AppThemeType.junina,
          label: 'Festa Junina',
          gradientColors: [Color(0xFFFFF3E0), Color(0xFFFFCC80)], // Laranja/Amarelo
          iconAsset: Icons.whatshot, // Fogueira
          iconColor: Colors.orange,
        );
      case AppThemeType.natal:
        return const CustomThemeData(
          type: AppThemeType.natal,
          label: 'Natal',
          gradientColors: [Color(0xFFB71C1C), Color(0xFF1B5E20)], // Vermelho e Verde
          iconAsset: Icons.ac_unit, // Neve
          iconColor: Colors.white,
        );
      case AppThemeType.pascoaCoelho:
        return const CustomThemeData(
          type: AppThemeType.pascoaCoelho,
          label: 'Páscoa (Coelho)',
          gradientColors: [Color(0xFFE1F5FE), Color(0xFFB3E5FC)], // Azul Bebê
          iconAsset: Icons.pets, // Patinha de coelho
          iconColor: Colors.white,
        );
      case AppThemeType.pascoaCristo:
        return const CustomThemeData(
          type: AppThemeType.pascoaCristo,
          label: 'Páscoa (Cristã)',
          gradientColors: [Color(0xFFFFFDE7), Color(0xFFFFF59D)], // Dourado/Branco
          iconAsset: Icons.wb_sunny, // Luz
          iconColor: Colors.amber,
        );
      case AppThemeType.halloween:
        return const CustomThemeData(
          type: AppThemeType.halloween,
          label: 'Halloween',
          gradientColors: [Color(0xFF212121), Color(0xFFFF6F00)], // Preto e Laranja
          iconAsset: Icons.nightlight_round,
          iconColor: Colors.orangeAccent,
        );
      default:
        // Retorna um tema neutro para Claro/Escuro/Sistema
        return const CustomThemeData(type: AppThemeType.sistema, label: 'Padrão', gradientColors: [], iconAsset: null);
    }
  }
}