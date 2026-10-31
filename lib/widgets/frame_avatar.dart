import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sofia/core/frames/frame_catalog.dart';
import 'package:sofia/services/api_client.dart';

/// Tamanhos padronizados de FrameAvatar (P, M, G).
enum FrameAvatarSize {
  small, // P (~44px avatar)
  medium, // M (~62px avatar)
  large, // G (~104px avatar)
}

extension FrameAvatarSizeExtension on FrameAvatarSize {
  double get avatarDiameter {
    switch (this) {
      case FrameAvatarSize.small:
        return 48.0;
      case FrameAvatarSize.medium:
        return 62.0;
      case FrameAvatarSize.large:
        return 104.0;
    }
  }

  double get strokeWidth {
    switch (this) {
      case FrameAvatarSize.small:
        return 2.5;
      case FrameAvatarSize.medium:
        return 3.5;
      case FrameAvatarSize.large:
        return 4.5;
    }
  }

  double get plaqueFontSize {
    switch (this) {
      case FrameAvatarSize.small:
        return 11.0;
      case FrameAvatarSize.medium:
        return 12.0;
      case FrameAvatarSize.large:
        return 14.0;
    }
  }

  EdgeInsets get plaquePadding {
    switch (this) {
      case FrameAvatarSize.small:
        return const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5);
      case FrameAvatarSize.medium:
        return const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5);
      case FrameAvatarSize.large:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5);
    }
  }
}

/// Widget reutilizável que desenha a moldura via CustomPainter + brilho animado leve
/// e a plaqueta com o nome da moldura na parte inferior.
class FrameAvatar extends StatefulWidget {
  final String? frameId;
  final String? gender;
  final String? photoUrl;
  final File? localPhotoFile;
  final String? name;
  final FrameAvatarSize size;
  final double? customDiameter;
  final bool showPlaque;
  final bool animate;
  final VoidCallback? onTap;

  const FrameAvatar({
    super.key,
    this.frameId,
    this.gender,
    this.photoUrl,
    this.localPhotoFile,
    this.name,
    this.size = FrameAvatarSize.medium,
    this.customDiameter,
    this.showPlaque = true,
    this.animate = true,
    this.onTap,
  });

  @override
  State<FrameAvatar> createState() => _FrameAvatarState();
}

class _FrameAvatarState extends State<FrameAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(FrameAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = FrameCatalog.resolve(widget.frameId, gender: widget.gender);
    final frame = resolved.frame;
    final palette = resolved.palette;

    final avatarDiameter = widget.customDiameter ?? widget.size.avatarDiameter;
    final stroke = widget.size.strokeWidth;
    final framePadding = stroke * 2.6;
    final totalDiameter = avatarDiameter + framePadding * 2;
    final totalHeight = widget.showPlaque
        ? totalDiameter + (widget.size.plaqueFontSize + 6)
        : totalDiameter;

    final resolvedUrl = ApiClient.resolveUrl(widget.photoUrl);

    Widget avatarContent;
    if (widget.localPhotoFile != null && widget.localPhotoFile!.existsSync()) {
      avatarContent = Image.file(
        widget.localPhotoFile!,
        fit: BoxFit.cover,
        width: avatarDiameter,
        height: avatarDiameter,
      );
    } else if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
      avatarContent = Image.network(
        resolvedUrl,
        fit: BoxFit.cover,
        width: avatarDiameter,
        height: avatarDiameter,
        errorBuilder: (_, _, _) => _buildFallback(avatarDiameter),
      );
    } else {
      avatarContent = _buildFallback(avatarDiameter);
    }

    final avatarWidget = SizedBox(
      width: totalDiameter,
      height: totalHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // 1. Moldura desenhada via CustomPainter com neon e rotação suave
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size(totalDiameter, totalDiameter),
                painter: _FramePainter(
                  frame: frame,
                  palette: palette,
                  strokeWidth: stroke,
                  animationValue: widget.animate ? _controller.value : 0.0,
                ),
              );
            },
          ),

          // 2. Foto do usuário recortada em círculo
          Positioned(
            top: framePadding,
            left: framePadding,
            child: ClipOval(
              child: Container(
                width: avatarDiameter,
                height: avatarDiameter,
                color: const Color(0xFF13172E),
                child: avatarContent,
              ),
            ),
          ),

          // 3. Plaqueta metálica estilizada com o nome da moldura
          if (widget.showPlaque)
            Positioned(
              bottom: 0,
              child: _FramePlaque(
                title: frame.displayName,
                palette: palette,
                size: widget.size,
              ),
            ),
        ],
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildFallback(double diameter) {
    final initial = (widget.name != null && widget.name!.trim().isNotEmpty)
        ? widget.name!.trim().characters.first.toUpperCase()
        : '';

    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF202646), Color(0xFF101328)],
        ),
      ),
      child: initial.isNotEmpty
          ? Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: diameter * 0.42,
              ),
            )
          : Icon(
              Icons.person_rounded,
              color: Colors.white.withValues(alpha: 0.75),
              size: diameter * 0.52,
            ),
    );
  }
}

/// Plaqueta com o nome da moldura desenhada em Flutter com gradiente e borda metálica.
class _FramePlaque extends StatelessWidget {
  final String title;
  final FramePalette palette;
  final FrameAvatarSize size;

  const _FramePlaque({
    required this.title,
    required this.palette,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: size.plaquePadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.plaqueGradient,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: palette.plaqueBorderColor,
          width: size == FrameAvatarSize.large ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.glowColor.withValues(alpha: 0.5),
            blurRadius: 6,
            spreadRadius: 0.5,
            offset: const Offset(0, 1),
          ),
          const BoxShadow(
            color: Color(0x66000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        title.toUpperCase(),
        maxLines: 1,
        style: TextStyle(
          color: palette.plaqueTextColor,
          fontSize: size.plaqueFontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter em Flutter puro que desenha a moldura personalizada para cada tipo e estilo.
class _FramePainter extends CustomPainter {
  final FrameItem frame;
  final FramePalette palette;
  final double strokeWidth;
  final double animationValue;

  _FramePainter({
    required this.frame,
    required this.palette,
    required this.strokeWidth,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth * 2) / 2;
    final angle = animationValue * 2 * math.pi;

    // 1. Brilho neon de fundo
    final glowPaint = Paint()
      ..color = palette.glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2.2
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 2);

    canvas.drawCircle(center, radius, glowPaint);

    // 2. Anel principal com gradiente em rotação leve
    final gradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: math.pi * 2,
      transform: GradientRotation(angle),
      colors: [
        ...palette.borderGradient,
        palette.borderGradient.first,
      ],
    );

    final framePaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, framePaint);

    // 3. Detalhes ornamentais específicos para o tipo e estilo
    switch (frame.type) {
      case FrameType.baby:
        _drawBabyDetails(canvas, center, radius, angle);
        break;
      case FrameType.official:
        _drawOfficialDetails(canvas, center, radius, angle);
        break;
      case FrameType.officialAdmin:
        _drawAdminDetails(canvas, center, radius, angle);
        break;
      case FrameType.room:
        _drawRoomDetails(canvas, center, radius, angle);
        break;
      case FrameType.face:
        _drawFaceDetails(canvas, center, radius, angle);
        break;
      case FrameType.host:
        _drawHostDetails(canvas, center, radius, angle);
        break;
      case FrameType.vip:
        _drawVipDetails(canvas, center, radius, angle);
        break;
    }
  }

  void _drawBabyDetails(Canvas canvas, Offset center, double radius, double angle) {
    final dotPaint = Paint()
      ..color = palette.accentColor
      ..style = PaintingStyle.fill;

    // Micro-esferas luminosas orbitando suavemente
    final count = frame.style == FrameStyle.a ? 6 : 8;
    for (int i = 0; i < count; i++) {
      final a = angle * (frame.style == FrameStyle.a ? 0.6 : -0.6) + (i * 2 * math.pi / count);
      final r = radius + (i.isEven ? strokeWidth * 0.7 : -strokeWidth * 0.4);
      final x = center.dx + r * math.cos(a);
      final y = center.dy + r * math.sin(a);
      canvas.drawCircle(Offset(x, y), strokeWidth * 0.4, dotPaint);
    }
  }

  void _drawOfficialDetails(Canvas canvas, Offset center, double radius, double angle) {
    final notchPaint = Paint()
      ..color = palette.accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.75;

    // Entalhes metálicos nos 4 quadrantes
    final count = frame.style == FrameStyle.a ? 4 : 8;
    for (int i = 0; i < count; i++) {
      final a = i * 2 * math.pi / count;
      final p1 = Offset(center.dx + (radius - strokeWidth) * math.cos(a),
          center.dy + (radius - strokeWidth) * math.sin(a));
      final p2 = Offset(center.dx + (radius + strokeWidth * 1.2) * math.cos(a),
          center.dy + (radius + strokeWidth * 1.2) * math.sin(a));
      canvas.drawLine(p1, p2, notchPaint);
    }

    // Segundo anel interno sutil
    final innerPaint = Paint()
      ..color = palette.accentColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - strokeWidth * 0.9, innerPaint);
  }

  void _drawAdminDetails(Canvas canvas, Offset center, double radius, double angle) {
    final accentPaint = Paint()
      ..color = palette.accentColor
      ..style = PaintingStyle.fill;

    // Asas superiores e brasão
    final topY = center.dy - radius - strokeWidth * 0.8;
    final path = Path()
      ..moveTo(center.dx, topY - strokeWidth * 1.6)
      ..lineTo(center.dx + strokeWidth * 1.4, topY)
      ..lineTo(center.dx, topY + strokeWidth * 0.8)
      ..lineTo(center.dx - strokeWidth * 1.4, topY)
      ..close();
    canvas.drawPath(path, accentPaint);

    // Asas laterais
    final wingPaint = Paint()
      ..color = palette.borderGradient.first
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.9
      ..strokeCap = StrokeCap.round;

    final leftP1 = Offset(center.dx - radius - strokeWidth * 0.4, center.dy);
    final leftP2 = Offset(center.dx - radius - strokeWidth * 1.5, center.dy - strokeWidth * 1.2);
    canvas.drawLine(leftP1, leftP2, wingPaint);

    final rightP1 = Offset(center.dx + radius + strokeWidth * 0.4, center.dy);
    final rightP2 = Offset(center.dx + radius + strokeWidth * 1.5, center.dy - strokeWidth * 1.2);
    canvas.drawLine(rightP1, rightP2, wingPaint);
  }

  void _drawRoomDetails(Canvas canvas, Offset center, double radius, double angle) {
    // Ondas acústicas concêntricas
    final arcPaint = Paint()
      ..color = palette.accentColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final a = (i * math.pi / 2) + math.pi / 8;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + strokeWidth * 0.8),
        a,
        math.pi / 5,
        false,
        arcPaint,
      );
    }
  }

  void _drawFaceDetails(Canvas canvas, Offset center, double radius, double angle) {
    final cornerPaint = Paint()
      ..color = palette.accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.85
      ..strokeCap = StrokeCap.square;

    // 4 cantos cyber / mira biométrica
    final corners = [
      math.pi / 4,
      3 * math.pi / 4,
      5 * math.pi / 4,
      7 * math.pi / 4,
    ];

    for (final a in corners) {
      final cx = center.dx + (radius + strokeWidth * 0.6) * math.cos(a);
      final cy = center.dy + (radius + strokeWidth * 0.6) * math.sin(a);
      canvas.drawCircle(Offset(cx, cy), strokeWidth * 0.4, cornerPaint);
    }
  }

  void _drawHostDetails(Canvas canvas, Offset center, double radius, double angle) {
    final starPaint = Paint()
      ..color = palette.accentColor
      ..style = PaintingStyle.fill;

    // Estrela dourada no topo
    final topCenter = Offset(center.dx, center.dy - radius - strokeWidth * 0.5);
    _drawMiniStar(canvas, topCenter, strokeWidth * 1.1, starPaint);

    if (frame.style == FrameStyle.b) {
      // 2 estrelas menores nos lados
      final leftCenter = Offset(center.dx - radius * 0.8, center.dy - radius * 0.6);
      final rightCenter = Offset(center.dx + radius * 0.8, center.dy - radius * 0.6);
      _drawMiniStar(canvas, leftCenter, strokeWidth * 0.7, starPaint);
      _drawMiniStar(canvas, rightCenter, strokeWidth * 0.7, starPaint);
    }
  }

  void _drawVipDetails(Canvas canvas, Offset center, double radius, double angle) {
    final jewelPaint = Paint()
      ..color = palette.accentColor
      ..style = PaintingStyle.fill;

    // Coroa de diamante no topo
    final topCenter = Offset(center.dx, center.dy - radius - strokeWidth * 0.9);
    final crownPath = Path()
      ..moveTo(topCenter.dx - strokeWidth * 1.8, topCenter.dy + strokeWidth * 0.5)
      ..lineTo(topCenter.dx - strokeWidth * 1.2, topCenter.dy - strokeWidth * 1.2)
      ..lineTo(topCenter.dx, topCenter.dy - strokeWidth * 0.4)
      ..lineTo(topCenter.dx + strokeWidth * 1.2, topCenter.dy - strokeWidth * 1.2)
      ..lineTo(topCenter.dx + strokeWidth * 1.8, topCenter.dy + strokeWidth * 0.5)
      ..close();
    canvas.drawPath(crownPath, jewelPaint);

    // Cristais facetados inferiores
    final gemPaint = Paint()
      ..color = palette.borderGradient.last
      ..style = PaintingStyle.fill;
    final gem1 = Offset(center.dx - radius * 0.6, center.dy + radius * 0.7);
    final gem2 = Offset(center.dx + radius * 0.6, center.dy + radius * 0.7);
    canvas.drawCircle(gem1, strokeWidth * 0.4, gemPaint);
    canvas.drawCircle(gem2, strokeWidth * 0.4, gemPaint);
  }

  void _drawMiniStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final a = (i * 4 * math.pi / 5) - math.pi / 2;
      final x = center.dx + r * math.cos(a);
      final y = center.dy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.frame.id != frame.id ||
        oldDelegate.palette != palette ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

