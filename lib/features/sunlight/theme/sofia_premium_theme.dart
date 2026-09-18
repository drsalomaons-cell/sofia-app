import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_theme.dart';

/// Tema premium Sunlight com cores SOFIA.
class SofiaPremiumTheme {
  SofiaPremiumTheme._();

  static const Color darkBg = AppTheme.preto;
  static const Color purpleDeep = Color(0xFF1A0F3A);
  static const Color purple = AppTheme.roxo;
  static const Color pink = AppTheme.lilas;
  static const Color gold = AppTheme.dourado;
  static const Color goldSoft = AppTheme.amarelo;

  static const LinearGradient roomBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF12082A), Color(0xFF05030F), Color(0xFF1A1030)],
  );

  static const String communityRules =
      '✨ SOFIA — Live social saudável • Respeito mútuo • Divisão 50/50 • VIP e agências ativos • Divirta-se com responsabilidade';
}
