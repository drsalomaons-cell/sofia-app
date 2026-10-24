import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Overlay animado usando os PNGs reais exportados do Stitch.
class RocketLaunchOverlay extends StatefulWidget {
  final VoidCallback onFinished;
  final int level;
  final String? avatarUrl;
  const RocketLaunchOverlay({super.key, required this.onFinished, this.level = 1, this.avatarUrl});
  @override
  State<RocketLaunchOverlay> createState() => _RocketLaunchOverlayState();
}

class _RocketLaunchOverlayState extends State<RocketLaunchOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final AudioPlayer _audio = AudioPlayer();
  String get _asset => 'assets/images/rockets/lv${widget.level.clamp(1, 3)}.png';
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2900))
      ..addStatusListener((status) { if (status == AnimationStatus.completed && mounted) widget.onFinished(); })
      ..forward();
    unawaited(_playLaunchSound());
  }
  Future<void> _playLaunchSound() async { try { await _audio.play(AssetSource('animations/rocket_launch.wav')); } catch (_) {} }
  @override
  void dispose() { _controller.dispose(); unawaited(_audio.dispose()); super.dispose(); }
  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Material(color: const Color(0xF5080A1A), child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInCubic.transform(_controller.value);
        final screen = MediaQuery.sizeOf(context);
        return Stack(fit: StackFit.expand, children: [
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF251044), Color(0xFF10152F), Color(0xFF050713)]))),
          Positioned(left: 0, right: 0, top: screen.height * (1.15 - 1.55 * t), height: screen.height * .62,
            child: Center(child: Stack(alignment: Alignment.center, children: [
              if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) Positioned(top: 0, child: CircleAvatar(radius: 27, backgroundImage: NetworkImage(widget.avatarUrl!))),
              Image.asset(_asset, fit: BoxFit.contain, width: screen.width * .92, height: screen.height * .60,
                errorBuilder: (context, error, stack) => const Icon(Icons.rocket_launch, color: Color(0xFFFFD76A), size: 120)),
            ]))),
          if (t > .78) Center(child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFD76A), width: 3), boxShadow: const [BoxShadow(color: Color(0xAA31D7FF), blurRadius: 45, spreadRadius: 15)]))),
          SafeArea(child: Align(alignment: Alignment.topCenter, child: Padding(padding: const EdgeInsets.fromLTRB(24, 22, 24, 0), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('META ATINGIDA', style: TextStyle(color: Color(0xFFFFD76A), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3)), const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: _controller.value, minHeight: 4, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation(Color(0xFF31D7FF)))),
          ])))),
          Positioned(left: 0, right: 0, bottom: screen.height * .12, child: const Text('SOFIA • CELEBRE A CONQUISTA', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6))),
        ]);
      },
    )),
  );
}
