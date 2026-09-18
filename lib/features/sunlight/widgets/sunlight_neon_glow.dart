import 'package:flutter/material.dart';

/// Brilho neon estilo Sunlight Live.
class SunlightNeonGlow extends StatelessWidget {
  final Widget child;
  final Color color;
  final double borderRadius;

  const SunlightNeonGlow({
    super.key,
    required this.child,
    required this.color,
    this.borderRadius = 999,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12),
          BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 24),
        ],
      ),
      child: child,
    );
  }
}
