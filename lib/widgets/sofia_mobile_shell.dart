import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_theme.dart';

/// Shell Sunlight Live — 390×667 centralizado, sem distorção.
class SofiaMobileShell extends StatelessWidget {
  static const double mobileWidth = 390;
  static const double mobileHeight = 667;

  final Widget child;

  const SofiaMobileShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : mobileWidth;
        final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : mobileHeight;
        final scaleW = maxW / mobileWidth;
        final scaleH = maxH / mobileHeight;
        final fitScale = (scaleW < scaleH ? scaleW : scaleH).clamp(0.55, 1.0);

        return ColoredBox(
          color: const Color(0xFF12082A),
          child: Center(
            child: Transform.scale(
              scale: fitScale,
              child: SizedBox(
                width: mobileWidth,
                height: mobileHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(fitScale < 1 ? 14 : 0),
                  child: Material(
                    color: AppTheme.preto,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
