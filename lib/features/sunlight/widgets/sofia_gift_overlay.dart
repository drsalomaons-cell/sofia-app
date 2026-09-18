import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/features/sunlight/services/sofia_gift_effect_service.dart';
import 'package:sofia/features/sunlight/theme/sofia_premium_theme.dart';

/// Overlay animado de presentes — foguetes, carros, coroas (Sunlight Live).
class SofiaGiftOverlay extends StatelessWidget {
  const SofiaGiftOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final effect = context.watch<SofiaGiftEffectService>().activeEffect;
    if (effect == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: Center(child: _GiftBurst(effect: effect)),
    );
  }
}

class _GiftBurst extends StatefulWidget {
  final ActiveGiftEffect effect;
  const _GiftBurst({required this.effect});

  @override
  State<_GiftBurst> createState() => _GiftBurstState();
}

class _GiftBurstState extends State<_GiftBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.effect.giftId == 'rocket' || widget.effect.giftId == 'car' ? 2200 : 1600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBig = widget.effect.giftId == 'rocket' || widget.effect.giftId == 'car';
    final size = isBig ? 160.0 : 120.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final scale = t < 0.35 ? 0.2 + t * 2.7 : (t < 0.6 ? 1.15 - (t - 0.35) * 0.6 : 1.0 - (t - 0.6) * 0.375);
        final opacity = t < 0.2 ? t * 5 : (t > 0.75 ? (1 - t) * 4 : 1.0);

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              SofiaPremiumTheme.gold.withValues(alpha: 0.5),
              SofiaPremiumTheme.purple.withValues(alpha: 0.2),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(color: SofiaPremiumTheme.gold.withValues(alpha: 0.6), blurRadius: 30, spreadRadius: 8),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.effect.emoji, style: TextStyle(fontSize: isBig ? 64 : 48)),
            const SizedBox(height: 4),
            Text(
              widget.effect.senderName,
              style: const TextStyle(color: SofiaPremiumTheme.goldSoft, fontSize: 11, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
