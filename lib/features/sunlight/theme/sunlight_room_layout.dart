import 'package:flutter/material.dart';

/// Escala compacta Sunlight — otimizada para 390×667 (Moto G86 / 6.7").
class SunlightRoomLayout {
  SunlightRoomLayout._();

  static const double designWidth = 390;
  static const double designHeight = 667;

  /// Fator 0.55–0.75 conforme largura útil.
  static double compactScale(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    if (shortest <= 360) return 0.55;
    if (shortest <= 390) return 0.62;
    if (shortest <= 430) return 0.68;
    return 0.75;
  }

  static const int throneSeatIndex = 0;
}
