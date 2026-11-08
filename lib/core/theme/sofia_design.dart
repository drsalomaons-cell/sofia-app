import 'dart:ui';

import 'package:flutter/material.dart';

/// Sistema visual da Sofia (extraído do DESIGN.md do Stitch "VIP Live Audio").
class SofiaColors {
  SofiaColors._();
  static const Color canvasTop = Color(0xFF16082F);
  static const Color canvasMid = Color(0xFF0A0B1E);
  static const Color canvasBottom = Color(0xFF05050B);
  static const Color surface = Color(0xFF111225);
  static const Color surfaceContainer = Color(0xFF1D1E32);
  static const Color surfaceHigh = Color(0xFF27283D);
  static const Color onSurface = Color(0xFFE1E0FB);
  static const Color onSurfaceVariant = Color(0xFFB9CACB);
  static const Color cyan = Color(0xFF00F2FE);
  static const Color purple = Color(0xFF7928CA);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldSoft = Color(0xFFFFE16D);
  static const Color success = Color(0xFF00F5A0);
  static const Color danger = Color(0xFFFF0055);
}

class SofiaSpacing {
  SofiaSpacing._();
  static const double xs = 4, sm = 8, md = 12, lg = 20, xl = 32, margin = 16;
}

class SofiaRadii {
  SofiaRadii._();
  static const double sm = 8, base = 16, md = 24, lg = 32, pill = 9999;
}

/// Outfit nos títulos e Plus Jakarta Sans no texto. Mínimo legível: 12 sp.
class SofiaText {
  SofiaText._();
  static const _h = 'Outfit';
  static const _b = 'PlusJakartaSans';
  static const TextStyle displayLg = TextStyle(fontFamily: _h, fontSize: 32, height: 1.25, fontWeight: FontWeight.w700, color: Colors.white);
  static const TextStyle headlineMd = TextStyle(fontFamily: _h, fontSize: 22, height: 1.3, fontWeight: FontWeight.w600, color: Colors.white);
  static const TextStyle titleMd = TextStyle(fontFamily: _b, fontSize: 16, height: 1.4, fontWeight: FontWeight.w600, color: Colors.white);
  static const TextStyle bodyMd = TextStyle(fontFamily: _b, fontSize: 14, height: 1.45, color: Colors.white);
  static const TextStyle bodySm = TextStyle(fontFamily: _b, fontSize: 12, height: 1.35, color: Colors.white);
  static const TextStyle labelMd = TextStyle(fontFamily: _b, fontSize: 12, height: 1.3, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: Colors.white);
}

/// Fundo da tela: gradiente radial do roxo real para o preto.
class SofiaBackground extends StatelessWidget {
  const SofiaBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1),
            radius: 1.4,
            colors: [SofiaColors.canvasTop, SofiaColors.canvasMid, SofiaColors.canvasBottom],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: child,
      );
}

enum SofiaGlassLevel { card, dock, modal }

/// Vidro fosco: card (cartões), dock (barras e folhas), modal (janelas).
class SofiaGlass extends StatelessWidget {
  const SofiaGlass({super.key, required this.child, this.level = SofiaGlassLevel.card, this.radius = SofiaRadii.md, this.padding, this.glow});
  final Widget child;
  final SofiaGlassLevel level;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    final Color tint;
    final double blur;
    final Color border;
    switch (level) {
      case SofiaGlassLevel.card:
        tint = Colors.white.withValues(alpha: 0.04);
        blur = 16;
        border = Colors.white.withValues(alpha: 0.08);
        break;
      case SofiaGlassLevel.dock:
        tint = SofiaColors.canvasMid.withValues(alpha: 0.75);
        blur = 28;
        border = SofiaColors.cyan.withValues(alpha: 0.2);
        break;
      case SofiaGlassLevel.modal:
        tint = const Color(0xFF100C26).withValues(alpha: 0.92);
        blur = 36;
        border = SofiaColors.purple.withValues(alpha: 0.35);
        break;
    }
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [if (glow != null) BoxShadow(color: glow!.withValues(alpha: 0.5), blurRadius: 20)],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(color: tint, borderRadius: shape, border: Border.all(color: border)),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Botão principal em pílula (ciano para roxo), altura mínima 52 dp.
class SofiaPrimaryButton extends StatelessWidget {
  const SofiaPrimaryButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: onPressed != null ? 1 : 0.45,
        child: GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SofiaRadii.pill),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [SofiaColors.cyan, SofiaColors.purple]),
              boxShadow: [BoxShadow(color: SofiaColors.purple.withValues(alpha: 0.5), blurRadius: 18)],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
              Text(label, style: SofiaText.titleMd),
            ]),
          ),
        ),
      );
}

/// Selo de nível dourado (VIP, SVIP, HOST, ADM).
class SofiaLevelBadge extends StatelessWidget {
  const SofiaLevelBadge({super.key, required this.text, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? SofiaColors.gold;
    return Container(
      constraints: const BoxConstraints(minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SofiaRadii.pill),
        gradient: LinearGradient(colors: [c, SofiaColors.goldSoft]),
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 8)],
      ),
      child: Text(text, style: SofiaText.labelMd.copyWith(color: const Color(0xFF221B00))),
    );
  }
}

ThemeData buildSofiaTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SofiaColors.canvasMid,
      colorScheme: const ColorScheme.dark(
        surface: SofiaColors.surface,
        primary: SofiaColors.cyan,
        secondary: SofiaColors.purple,
        tertiary: SofiaColors.gold,
        error: SofiaColors.danger,
        onSurface: SofiaColors.onSurface,
      ),
      fontFamily: 'PlusJakartaSans',
    );
