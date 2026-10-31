import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sofia/core/frames/living_frame_spec.dart';

/// Desenha o anel e os efeitos (brilho, órbita, trovão, fogo, asas).
/// [t] vai de 0 a 1 e se repete; [speaking] vai de 0 a 1 (nível da voz).
class LivingFramePainter extends CustomPainter {
  LivingFramePainter({
    required this.spec,
    required this.t,
    required this.speaking,
    required this.avatarRadius,
    required this.stroke,
  });

  final LivingFrameSpec spec;
  final double t;
  final double speaking;
  final double avatarRadius;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ringR = avatarRadius + stroke * 0.6;
    final path = _ringPath(center, ringR);
    final colors = spec.colors;

    final base = spec.tier == FrameTier.normal
        ? 0.25
        : (spec.tier == FrameTier.luxury ? 0.4 : 0.55);
    final glow = (base + 0.45 * speaking).clamp(0.0, 1.0);

    // Neon que acende com a voz.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 2.2
        ..color = colors[0].withValues(alpha: glow)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          stroke * 1.4 + 8 * speaking,
        ),
    );

    final shader = SweepGradient(
      colors: [colors[0], colors[1], colors[0]],
      transform: GradientRotation(t * 2 * math.pi),
    ).createShader(Rect.fromCircle(center: center, radius: ringR));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round
        ..shader = shader,
    );

    if (spec.tier != FrameTier.normal) {
      canvas.drawPath(
        _ringPath(center, ringR - stroke * 0.9),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.55),
      );
    }

    switch (spec.effect) {
      case FrameEffect.none:
        break;
      case FrameEffect.shimmer:
        _shimmer(canvas, path);
        break;
      case FrameEffect.orbit:
        _shimmer(canvas, path);
        _orbit(canvas, center, ringR);
        break;
      case FrameEffect.lightning:
        _lightning(canvas, center, ringR);
        break;
      case FrameEffect.fire:
        _fire(canvas, center, ringR);
        break;
      case FrameEffect.wings:
        _wings(canvas, center, ringR);
        break;
    }
  }

  Path _ringPath(Offset c, double r) {
    switch (spec.shape) {
      case FrameShape.circle:
        return Path()..addOval(Rect.fromCircle(center: c, radius: r));
      case FrameShape.hexagon:
        return _polygon(c, r, 6);
      case FrameShape.octagon:
        return _polygon(c, r, 8);
    }
  }

  Path _polygon(Offset c, double r, int n) {
    final rr = r / math.cos(math.pi / n);
    final p = Path();
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + math.pi / n + i * 2 * math.pi / n;
      final o = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
      if (i == 0) {
        p.moveTo(o.dx, o.dy);
      } else {
        p.lineTo(o.dx, o.dy);
      }
    }
    p.close();
    return p;
  }

  void _shimmer(Canvas canvas, Path path) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final m = metrics.first;
    final len = m.length;
    final start = (t * len) % len;
    final seg = len * 0.14;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.55
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.9);
    if (start + seg <= len) {
      canvas.drawPath(m.extractPath(start, start + seg), paint);
    } else {
      canvas.drawPath(m.extractPath(start, len), paint);
      canvas.drawPath(m.extractPath(0, start + seg - len), paint);
    }
  }

  void _orbit(Canvas canvas, Offset c, double r) {
    final colors = spec.colors;
    for (var i = 0; i < 8; i++) {
      final dir = i.isEven ? 1.0 : -1.0;
      final a = t * 2 * math.pi * dir + i * 2 * math.pi / 8;
      final rad = r + stroke * (1.6 + 0.5 * (i % 3));
      final o = Offset(c.dx + rad * math.cos(a), c.dy + rad * math.sin(a));
      canvas.drawCircle(
        o,
        stroke * 0.55,
        Paint()
          ..color = colors[i % 2].withValues(alpha: 0.95)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  void _lightning(Canvas canvas, Offset c, double r) {
    final colors = spec.colors;
    final step = (t * 12).floor();
    final phase = t * 12 - step;
    if (phase > 0.7) return;
    final rnd = math.Random(step * 7919 + (spec.id.hashCode % 1000));
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    final halo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 1.2
      ..strokeCap = StrokeCap.round
      ..color = colors[1].withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    for (var b = 0; b < 5; b++) {
      var a = rnd.nextDouble() * 2 * math.pi;
      var p = Offset(
        c.dx + (r + stroke * 0.5) * math.cos(a),
        c.dy + (r + stroke * 0.5) * math.sin(a),
      );
      final bolt = Path()..moveTo(p.dx, p.dy);
      for (var s = 0; s < 4; s++) {
        a += (rnd.nextDouble() - 0.5) * 0.9;
        final len = stroke * (1.4 + rnd.nextDouble() * 1.6) + avatarRadius * 0.08;
        p = Offset(p.dx + len * math.cos(a), p.dy + len * math.sin(a));
        bolt.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(bolt, halo);
      canvas.drawPath(bolt, core);
    }
  }

  void _fire(Canvas canvas, Offset c, double r) {
    const n = 18;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      final wob = math.sin(t * 2 * math.pi * 3 + i * 1.7);
      final h = stroke * (3.2 + 2.2 * (0.5 + 0.5 * wob)) + avatarRadius * 0.1;
      final sway = math.sin(t * 2 * math.pi * 2 + i) * 0.18;
      final dir = Offset(math.cos(a + sway), math.sin(a + sway));
      final nrm = Offset(-math.sin(a), math.cos(a));
      final baseP = Offset(
        c.dx + (r + stroke * 0.2) * math.cos(a),
        c.dy + (r + stroke * 0.2) * math.sin(a),
      );
      _flame(canvas, baseP, dir, nrm, h, stroke * 1.1, const Color(0xFFFF6D00));
      _flame(canvas, baseP, dir, nrm, h * 0.58, stroke * 0.6, const Color(0xFFFFEA00));
    }
  }

  void _flame(Canvas canvas, Offset b, Offset dir, Offset nrm, double h,
      double w, Color color) {
    final tip = Offset(b.dx + dir.dx * h, b.dy + dir.dy * h);
    final mid = Offset(b.dx + dir.dx * h * 0.55, b.dy + dir.dy * h * 0.55);
    final p = Path()
      ..moveTo(b.dx - nrm.dx * w, b.dy - nrm.dy * w)
      ..quadraticBezierTo(
          mid.dx - nrm.dx * w * 0.9, mid.dy - nrm.dy * w * 0.9, tip.dx, tip.dy)
      ..quadraticBezierTo(
          mid.dx + nrm.dx * w * 0.9, mid.dy + nrm.dy * w * 0.9,
          b.dx + nrm.dx * w, b.dy + nrm.dy * w)
      ..close();
    canvas.drawPath(
      p,
      Paint()
        ..color = color.withValues(alpha: 0.88)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
  }

  void _wings(Canvas canvas, Offset c, double r) {
    final colors = spec.colors;
    final flap = math.sin(t * 2 * math.pi * 2) * 0.28;
    for (final side in const [1.0, -1.0]) {
      canvas.save();
      canvas.translate(c.dx + side * r * 0.92, c.dy - r * 0.05);
      canvas.scale(side, 1);
      for (var i = 0; i < 6; i++) {
        final ang = -0.15 - i * 0.26 + flap * (1 + i * 0.12);
        final len = r * (1.15 - i * 0.11);
        final w = stroke * 2.1;
        canvas.save();
        canvas.rotate(ang);
        final feather = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(len * 0.5, -w, len, 0)
          ..quadraticBezierTo(len * 0.5, w, 0, 0)
          ..close();
        canvas.drawPath(
          feather,
          Paint()
            ..shader = LinearGradient(
              colors: [
                colors[0].withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.9),
              ],
            ).createShader(Rect.fromLTWH(0, -w, len, 2 * w)),
        );
        canvas.drawPath(
          feather,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1
            ..color = colors[1].withValues(alpha: 0.9),
        );
        canvas.restore();
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(LivingFramePainter old) =>
      old.t != t ||
      old.speaking != speaking ||
      old.spec != spec ||
      old.avatarRadius != avatarRadius ||
      old.stroke != stroke;
}
