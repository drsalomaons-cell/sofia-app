import 'package:flutter/material.dart';

/// Escala compacta Sunlight — otimizada para 390×667 (Moto G86 / 6.7").
class SunlightRoomLayout {
  SunlightRoomLayout._();

  static const double designWidth = 390;
  static const double designHeight = 667;

  /// Escala responsiva sem reduzir as cadeiras a ícones minúsculos.
  /// A largura continua a ser respeitada pelo LayoutBuilder do painel.
  static double compactScale(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    if (shortest <= 360) return 0.88;
    if (shortest <= 390) return 0.94;
    if (shortest <= 430) return 1.0;
    return 1.0;
  }

  static const int throneSeatIndex = 0;
}
