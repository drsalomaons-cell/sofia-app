import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_colors.dart';

/// Tema 2 — Brilho e Graça (dourado metálico + lilás + branco).
class SofiaThemeBrilhoGraca {
  static const Color douradoMetalico = Color(0xFFFFD700);
  static const Color lilasSuave = Color(0xFFC8A2FF);

  static ThemeData get light => _base(
        brightness: Brightness.light,
        primary: douradoMetalico,
        secondary: lilasSuave,
        scaffold: AppColors.branco,
        surface: const Color(0xFFFFFDF7),
        appBarBg: douradoMetalico,
        inputFill: const Color(0xFFFFF8E7),
      );

  static ThemeData get dark => _base(
        brightness: Brightness.dark,
        primary: douradoMetalico,
        secondary: lilasSuave,
        scaffold: const Color(0xFF1A1520),
        surface: const Color(0xFF2A2235),
        appBarBg: const Color(0xFF2A2235),
        inputFill: const Color(0xFF352D42),
      );

  static ThemeData _base({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color scaffold,
    required Color surface,
    required Color appBarBg,
    required Color inputFill,
  }) {
    final isLight = brightness == Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: scaffold,
      colorScheme: isLight
          ? ColorScheme.light(
              primary: primary,
              secondary: secondary,
              tertiary: AppColors.lilas,
              surface: surface,
              error: AppColors.vermelho,
            )
          : ColorScheme.dark(
              primary: primary,
              secondary: secondary,
              tertiary: AppColors.lilas,
              surface: surface,
              error: AppColors.vermelho,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: AppColors.branco,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.branco,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondary,
          side: BorderSide(color: secondary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: isLight ? surface : surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
