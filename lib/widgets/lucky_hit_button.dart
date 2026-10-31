import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Resposta do servidor a cada batida. Quem decide o prêmio é sempre o servidor.
class LuckyHitResult {
  const LuckyHitResult({
    required this.balanceAfter,
    required this.returnedCoins,
    this.message,
  });

  /// Saldo oficial de moedas compradas depois da batida.
  final int balanceAfter;

  /// Moedas devolvidas nesta batida (0 se nada voltou).
  final int returnedCoins;
  final String? message;
}

/// Botão de bater do presente da sorte: repete o presente sem voltar à caixa,
/// mostra o saldo subindo e descendo na hora e acende os combos em volta.
class LuckyHitButton extends StatefulWidget {
  const LuckyHitButton({
    super.key,
    required this.balance,
    required this.cost,
    required this.onHit,
    this.onShowOdds,
    this.milestones = const [7, 17, 77, 365, 777],
    this.comboTimeout = const Duration(seconds: 10),
    this.label = 'BATER',
  });

  final int balance;
  final int cost;
  final Future<LuckyHitResult> Function() onHit;
  final VoidCallback? onShowOdds;
  final List<int> milestones;
  final Duration comboTimeout;
  final String label;

  @override
  State<LuckyHitButton> createState() => _LuckyHitButtonState();
}

class _LuckyHitButtonState extends State<LuckyHitButton> {
  late int _balance = widget.balance;
  int _combo = 0;
  int _delta = 0;
  bool _busy = false;
  bool _showDelta = false;
  Timer? _comboTimer;
  Timer? _deltaTimer;

  @override
  void didUpdateWidget(LuckyHitButton old) {
    super.didUpdateWidget(old);
    if (old.balance != widget.balance && !_busy) {
      _balance = widget.balance;
    }
  }

  @override
  void dispose() {
    _comboTimer?.cancel();
    _deltaTimer?.cancel();
    super.dispose();
  }

  bool get _canHit => !_busy && _balance >= widget.cost;

  Future<void> _hit() async {
    if (!_canHit) return;
    HapticFeedback.lightImpact();
    // Resposta imediata na tela; o servidor confirma em seguida.
    setState(() {
      _busy = true;
      _balance -= widget.cost;
      _combo += 1;
      _delta = -widget.cost;
      _showDelta = true;
    });
    _restartComboTimer();
    try {
      final result = await widget.onHit();
      if (!mounted) return;
      setState(() {
        _balance = result.balanceAfter;
        _delta = result.returnedCoins - widget.cost;
        _showDelta = true;
        _busy = false;
      });
      if (result.returnedCoins > 0) HapticFeedback.mediumImpact();
    } catch (_) {
      if (!mounted) return;
      // Falhou: devolve o saldo mostrado e desfaz a batida.
      setState(() {
        _balance += widget.cost;
        _combo = math.max(0, _combo - 1);
        _delta = 0;
        _showDelta = false;
        _busy = false;
      });
    }
    _deltaTimer?.cancel();
    _deltaTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _showDelta = false);
    });
  }

  void _restartComboTimer() {
    _comboTimer?.cancel();
    _comboTimer = Timer(widget.comboTimeout, () {
      if (mounted) setState(() => _combo = 0);
    });
  }

  static String _fmt(int v) {
    final s = v.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return v < 0 ? '-$b' : b.toString();
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFC857);
    const ringSize = 96.0;
    final positive = _delta >= 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: gold.withValues(alpha: 0.7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: gold, size: 22),
                  const SizedBox(width: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: _balance.toDouble()),
                    duration: const Duration(milliseconds: 250),
                    builder: (_, v, _) => Text(
                      _fmt(v.round()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 22,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showDelta && _delta != 0 ? 1 : 0,
                child: Text(
                  '${positive ? '+' : ''}${_fmt(_delta)}',
                  style: TextStyle(
                    color: positive
                        ? const Color(0xFF69F0AE)
                        : const Color(0xFFFF5252),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (widget.onShowOdds != null)
              TextButton(
                onPressed: widget.onShowOdds,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  'Ver chances',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
          ],
        ),
        const SizedBox(width: 10),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _hit,
          child: SizedBox(
            width: ringSize,
            height: ringSize,
            child: CustomPaint(
              painter: _ComboRingPainter(
                combo: _combo,
                milestones: widget.milestones,
                enabled: _canHit || _busy,
              ),
              child: Center(
                child: AnimatedScale(
                  scale: _busy ? 0.92 : 1,
                  duration: const Duration(milliseconds: 90),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF2BD6), Color(0xFF7C4DFF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF2BD6).withValues(alpha: 0.6),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                        if (_combo > 0)
                          Text(
                            'x$_combo',
                            style: const TextStyle(
                              color: Color(0xFFFFE082),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Anel dividido em um trecho por combo (7, 17, 77, 365, 777).
/// Cada trecho enche conforme as batidas seguidas e acende ao ser atingido.
class _ComboRingPainter extends CustomPainter {
  _ComboRingPainter({
    required this.combo,
    required this.milestones,
    required this.enabled,
  });

  final int combo;
  final List<int> milestones;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 5;
    final n = milestones.length;
    if (n == 0) return;
    const gap = 0.12;
    final seg = (2 * math.pi - gap * n) / n;
    var prev = 0;
    for (var i = 0; i < n; i++) {
      final m = milestones[i];
      final start = -math.pi / 2 + i * (seg + gap);
      final track = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: enabled ? 0.18 : 0.08);
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, seg, false, track);
      final progress = ((combo - prev) / (m - prev)).clamp(0.0, 1.0);
      if (progress > 0) {
        final lit = combo >= m;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..color = lit ? const Color(0xFFFFC857) : const Color(0xFF38E8FF);
        if (lit) {
          canvas.drawArc(
            Rect.fromCircle(center: c, radius: r),
            start,
            seg,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 10
              ..color = const Color(0xFFFFC857).withValues(alpha: 0.55)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
        }
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, seg * progress, false, paint);
      }
      prev = m;
    }
  }

  @override
  bool shouldRepaint(_ComboRingPainter old) =>
      old.combo != combo || old.enabled != enabled || old.milestones != milestones;
}
