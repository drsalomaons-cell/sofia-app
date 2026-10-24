import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sofia/services/api_client.dart';

/// Converte URLs relativas do servidor (/uploads/...) em URL absoluta.
String? sofiaMediaUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('/')) return '${ApiClient.baseUrl}$url';
  return url;
}

/// Foguete lançado em tela cheia. O avatar de quem enviou o presente aparece
/// dentro da janela (vigia) do foguete e sobe junto com ele.
class RocketLaunchOverlay extends StatefulWidget {
  final VoidCallback onFinished;
  final int level;
  final String? avatarUrl;
  final String senderName;
  const RocketLaunchOverlay({
    super.key,
    required this.onFinished,
    this.level = 1,
    this.avatarUrl,
    this.senderName = '',
  });

  @override
  State<RocketLaunchOverlay> createState() => _RocketLaunchOverlayState();
}

class _RocketLaunchOverlayState extends State<RocketLaunchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final AudioPlayer _audio = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) widget.onFinished();
      })
      ..forward();
    unawaited(_playLaunchSound());
  }

  Future<void> _playLaunchSound() async {
    try {
      await _audio.play(AssetSource('animations/rocket_launch.wav'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    unawaited(_audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final rocketW = screen.width * 0.48;
    final rocketH = rocketW * 1.9;
    final name = widget.senderName.trim();
    return Positioned.fill(
      child: Material(
        color: const Color(0xF2080A1A),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeInCubic.transform(_controller.value);
            final flame = (math.sin(_controller.value * 70) + 1) / 2;
            final top = screen.height * 1.02 - (screen.height * 1.25 + rocketH * 0.4) * t;
            return Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1D1E32), Color(0xFF111225)],
                    ),
                  ),
                ),
                Positioned(
                  left: (screen.width - rocketW) / 2,
                  top: top,
                  width: rocketW,
                  height: rocketH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _RocketPainter(flame)),
                      ),
                      // Avatar dentro da janela do foguete.
                      Positioned(
                        left: rocketW * 0.5 - rocketW * 0.19,
                        top: rocketH * 0.40 - rocketW * 0.19,
                        width: rocketW * 0.38,
                        height: rocketW * 0.38,
                        child: SenderAvatar(url: widget.avatarUrl, name: name),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name.isEmpty ? 'FOGUETE' : '${name.toUpperCase()} LANÇOU UM FOGUETE',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFFD76A),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _controller.value,
                              minHeight: 4,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation(Color(0xFF00F2FE)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Avatar redondo com foto (se houver) ou inicial do nome como fallback.
class SenderAvatar extends StatelessWidget {
  final String? url;
  final String name;
  const SenderAvatar({super.key, this.url, this.name = ''});

  Widget _fallback() => Container(
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF00F2FE), Color(0xFF6807BA)],
      ),
    ),
    child: name.isEmpty
        ? const Icon(Icons.person_rounded, color: Colors.white, size: 28)
        : Text(
            name.characters.first.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
  );

  @override
  Widget build(BuildContext context) {
    final resolved = sofiaMediaUrl(url);
    return ClipOval(
      child: resolved == null
          ? _fallback()
          : Image.network(
              resolved,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => _fallback(),
            ),
    );
  }
}

class _RocketPainter extends CustomPainter {
  final double flame;
  const _RocketPainter(this.flame);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Chama.
    final y0 = h * 0.80;
    final fl = h * (0.12 + 0.06 * flame);
    final flamePath = Path()
      ..moveTo(w * 0.34, y0)
      ..cubicTo(w * 0.36, y0 + fl * 0.8, w * 0.5, y0 + fl * 1.1, w * 0.5, y0 + fl * 1.5)
      ..cubicTo(w * 0.5, y0 + fl * 1.1, w * 0.64, y0 + fl * 0.8, w * 0.66, y0)
      ..close();
    canvas.drawPath(
      flamePath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF3C4), Color(0xFFFFB300), Color(0x00FF6B3D)],
        ).createShader(Rect.fromLTWH(w * 0.3, y0, w * 0.4, fl * 1.5)),
    );

    // Aletas.
    final finPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF00F2FE), Color(0xFF6807BA)],
      ).createShader(Rect.fromLTWH(0, h * 0.45, w, h * 0.45));
    final leftFin = Path()
      ..moveTo(w * 0.20, h * 0.48)
      ..lineTo(0, h * 0.78)
      ..lineTo(0, h * 0.85)
      ..lineTo(w * 0.22, h * 0.74)
      ..close();
    final rightFin = Path()
      ..moveTo(w * 0.80, h * 0.48)
      ..lineTo(w, h * 0.78)
      ..lineTo(w, h * 0.85)
      ..lineTo(w * 0.78, h * 0.74)
      ..close();
    canvas.drawPath(leftFin, finPaint);
    canvas.drawPath(rightFin, finPaint);

    // Bocal.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.30, h * 0.74, w * 0.70, h * 0.80),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF39405A),
    );

    // Corpo.
    final body = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.92, h * 0.14, w * 0.86, h * 0.50, w * 0.80, h * 0.74)
      ..lineTo(w * 0.20, h * 0.74)
      ..cubicTo(w * 0.14, h * 0.50, w * 0.08, h * 0.14, w * 0.5, 0)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFC9D6F2), Color(0xFFFFFFFF), Color(0xFF9FB1D6)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.17),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF6B3D), Color(0xFFFFB300)],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.17)),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.64, w, h * 0.035),
      Paint()..color = const Color(0xFF00F2FE),
    );
    canvas.restore();

    // Janela (vigia) onde fica o avatar.
    final c = Offset(w * 0.5, h * 0.40);
    canvas.drawCircle(
      c,
      w * 0.235,
      Paint()
        ..color = const Color(0x8800F2FE)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(c, w * 0.225, Paint()..color = const Color(0xFF0B1030));
    canvas.drawCircle(
      c,
      w * 0.215,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03
        ..color = const Color(0xFF00F2FE),
    );
  }

  @override
  bool shouldRepaint(covariant _RocketPainter old) => old.flame != flame;
}