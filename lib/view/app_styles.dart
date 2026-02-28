import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Colors.teal;
  static const Color secondary = Colors.orange;
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Colors.red;
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.grey;
  static const Color accent = Colors.pink;

  // Cores Dark Mode
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Colors.white70;

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    secondary: secondary,
    onSecondary: Colors.white,
    error: error,
    onError: Colors.white,
    surface: surface,
    onSurface: textPrimary,
  );

  static const ColorScheme darkScheme = ColorScheme.dark(
    primary: primary,
    secondary: secondary,
    surface: surfaceDark,
    onSurface: textPrimaryDark,
  );
}

class AppStyles {
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle error = TextStyle(
    fontSize: 12,
    color: AppColors.error,
  );

  static final ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}