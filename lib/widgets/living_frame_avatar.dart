import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sofia/core/frames/living_frame_spec.dart';
import 'package:sofia/widgets/living_frame_painter.dart';

/// Avatar com moldura animada e plaqueta de nome em destaque.
/// [speaking] (0 a 1) acende o neon quando a pessoa fala.
class LivingFrameAvatar extends StatefulWidget {
  const LivingFrameAvatar({
    super.key,
    required this.spec,
    required this.photo,
    this.diameter = 64,
    this.speaking,
    this.animate = true,
    this.showPlaque = true,
    this.plaqueText,
    this.onTap,
  });

  final LivingFrameSpec spec;
  final Widget photo;
  final double diameter;
  final ValueListenable<double>? speaking;
  final bool animate;
  final bool showPlaque;
  final String? plaqueText;
  final VoidCallback? onTap;

  @override
  State<LivingFrameAvatar> createState() => _LivingFrameAvatarState();
}

class _LivingFrameAvatarState extends State<LivingFrameAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );
  final ValueNotifier<double> _silent = ValueNotifier<double>(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LivingFrameAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  /// Respeita "reduzir animações" do sistema e o parâmetro [animate].
  void _sync() {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final want = widget.animate && !reduce;
    if (want && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!want && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _silent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = math.max(48.0, widget.diameter);
    final stroke = (d * 0.07).clamp(3.0, 7.0).toDouble();
    final box = d + stroke * 2.4;
    final speaking = widget.speaking ?? _silent;
    final spec = widget.spec;

    final avatar = SizedBox(
      width: box,
      height: box,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: -box / 2,
            top: -box / 2,
            width: box * 2,
            height: box * 2,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_controller, speaking]),
                  builder: (_, _) => CustomPaint(
                    painter: LivingFramePainter(
                      spec: spec,
                      t: _controller.value,
                      speaking: speaking.value.clamp(0.0, 1.0).toDouble(),
                      avatarRadius: d / 2,
                      stroke: stroke,
                    ),
                  ),
                ),
              ),
            ),
          ),
          ClipOval(child: SizedBox(width: d, height: d, child: widget.photo)),
        ],
      ),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        if (widget.showPlaque) _Plaque(spec: spec, diameter: d, text: widget.plaqueText),
      ],
    );

    if (widget.onTap == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: content,
    );
  }
}

class _Plaque extends StatelessWidget {
  const _Plaque({required this.spec, required this.diameter, this.text});

  final LivingFrameSpec spec;
  final double diameter;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final colors = spec.colors;
    final fontSize = math.max(12.0, diameter * 0.18);
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 0.8),
        boxShadow: [
          BoxShadow(color: colors[0].withValues(alpha: 0.55), blurRadius: 10),
        ],
      ),
      child: Text(
        text ?? spec.plaque,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: spec.role.plaqueTextColor,
        ),
      ),
    );
  }
}
