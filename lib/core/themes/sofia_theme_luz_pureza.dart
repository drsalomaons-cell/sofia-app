import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_colors.dart';

/// Tema 1 — Luz e Pureza (roxo + lilás + branco).
class SofiaThemeLuzPureza {
  static ThemeData get light => _base(
        brightness: Brightness.light,
        primary: AppColors.roxo,
        secondary: AppColors.lilas,
        scaffold: AppColors.branco,
        surface: AppColors.branco,
        background: AppColors.cinzaClaro,
        appBarBg: AppColors.roxo,
        inputFill: AppColors.cinzaClaro,
        gradient: AppColors.gradienteLilasRoxo,
      );

  static ThemeData get dark => _base(
        brightness: Brightness.dark,
        primary: AppColors.roxo,
        secondary: AppColors.lilas,
        scaffold: const Color(0xFF121212),
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
        appBarBg: const Color(0xFF1E1E1E),
        inputFill: const Color(0xFF2C2C2C),
        gradient: AppColors.gradienteRoxoDourado,
      );

  static ThemeData _base({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color scaffold,
    required Color surface,
    required Color background,
    required Color appBarBg,
    required Color inputFill,
    required LinearGradient gradient,
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
          foregroundColor: primary,
          side: BorderSide(color: primary),
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
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: isLight ? AppColors.branco : surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
