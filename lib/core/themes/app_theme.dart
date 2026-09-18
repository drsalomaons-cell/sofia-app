import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_colors.dart';
import 'package:sofia/core/themes/sofia_theme_luz_pureza.dart';
import 'package:sofia/core/themes/sofia_theme_brilho_graca.dart';

/// Facade de temas SOFIA — dois estilos visuais para escolha.
class AppTheme {
  // Compatibilidade com código existente
  static const Color roxo = AppColors.roxo;
  static const Color dourado = AppColors.dourado;
  static const Color lilas = AppColors.lilas;
  static const Color branco = AppColors.branco;
  static const Color amarelo = AppColors.amarelo;
  static const Color preto = AppColors.preto;
  static const Color cinzaClaro = AppColors.cinzaClaro;
  static const Color cinzaMedio = AppColors.cinzaMedio;
  static const Color cinzaEscuro = AppColors.cinzaEscuro;
  static const Color verde = AppColors.verde;
  static const Color vermelho = AppColors.vermelho;

  static const LinearGradient gradienteRoxoDourado = AppColors.gradienteRoxoDourado;
  static const LinearGradient gradienteLilasRoxo = AppColors.gradienteLilasRoxo;
  static const LinearGradient gradienteDouradoLilas = AppColors.gradienteDouradoLilas;

  /// Tema 1 — Luz e Pureza (padrão)
  static ThemeData get lightTheme => SofiaThemeLuzPureza.light;
  static ThemeData get darkTheme => SofiaThemeLuzPureza.dark;

  /// Tema 2 — Brilho e Graça
  static ThemeData get brilhoLightTheme => SofiaThemeBrilhoGraca.light;
  static ThemeData get brilhoDarkTheme => SofiaThemeBrilhoGraca.dark;

  /// Seleciona tema conforme capa ativa do branding.
  static ThemeData themeForCover(String coverId, {required bool isDark}) {
    if (coverId == 'capa2') {
      return isDark ? brilhoDarkTheme : brilhoLightTheme;
    }
    return isDark ? darkTheme : lightTheme;
  }
}
