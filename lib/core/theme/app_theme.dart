import 'package:flutter/material.dart';

class HamroFixTheme {
  static const Color darkGreen = Color(0xFF1A3D1A);
  static const Color mediumGreen = Color(0xFF2E6B2E);
  static const Color lightGreen = Color(0xFFB8D8B8);
  static const Color canvas = Color(0xFFF6FBF4);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: mediumGreen,
        primary: mediumGreen,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFC8E6C9),
        onPrimaryContainer: darkGreen,
        secondary: const Color(0xFF388E3C),
        surface: canvas,
      ),
      scaffoldBackgroundColor: canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: mediumGreen,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: mediumGreen,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
        ),
      ),
    );
  }
}
