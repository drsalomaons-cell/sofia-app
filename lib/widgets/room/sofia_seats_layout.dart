import 'package:flutter/material.dart';
import 'package:sofia/core/themes/app_theme.dart';
import 'package:sofia/features/sunlight/theme/sunlight_room_layout.dart';
import 'package:sofia/features/sunlight/widgets/sunlight_neon_glow.dart';
import 'package:sofia/models/seat_model.dart';

/// Layout de cadeiras Sunlight Live — trono + fileiras responsivas.
/// Suporta: 4, 6, 8, 10, 12, 15, 20
class SofiaSeatsLayout extends StatelessWidget {
  static const chairPresets = [4, 6, 8, 10, 12, 15, 20];

  final List<SeatModel> seats;
  final int chairCount;
  final String? currentUserId;
  final void Function(int index, SeatModel seat) onSeatTap;
  final void Function(int index, SeatModel seat)? onSeatLongPress;

  const SofiaSeatsLayout({
    super.key,
    required this.seats,
    required this.chairCount,
    this.currentUserId,
    required this.onSeatTap,
    this.onSeatLongPress,
  });

  static List<int> rowSizes(int total) {
    final rest = (total - 1).clamp(0, 64);
    if (rest == 0) return [];
    if (rest <= 4) return [rest];
    if (rest <= 8) return [4, rest - 4];
    if (rest <= 14) return [6, rest - 6];
    final rows = <int>[];
    var left = rest;
    while (left > 0) {
      final n = left > 6 ? 6 : left;
      rows.add(n);
      left -= n;
    }
    return rows;
  }

  SeatModel _seatAt(int index) {
    if (index < seats.length) return seats[index];
    return SeatModel(index: index);
  }

  @override
  Widget build(BuildContext context) {
    final count = chairCount.clamp(4, 20);
    final rows = rowSizes(count);
    final scale = SunlightRoomLayout.compactScale(context);
    final throneSize = 54.0 * scale;
    final seatSize = 42.0 * scale;
    final gap = 8.0 * scale;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _SeatBubble(
                seat: _seatAt(0),
                size: throneSize,
                isThrone: true,
                isLocal: _seatAt(0).userId == currentUserId,
                isMicLive: _seatAt(0).userId == currentUserId && !_seatAt(0).isMuted,
                onTap: () => onSeatTap(0, _seatAt(0)),
                onLongPress: onSeatLongPress != null ? () => onSeatLongPress!(0, _seatAt(0)) : null,
              ),
              SizedBox(height: gap),
              ...rows.asMap().entries.map((entry) {
                final rowCount = entry.value;
                final startIndex = 1 + rows.take(entry.key).fold<int>(0, (a, b) => a + b);
                return Padding(
                  padding: EdgeInsets.only(bottom: gap),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(rowCount, (i) {
                      final idx = startIndex + i;
                      final seat = _seatAt(idx);
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: gap * 0.5),
                        child: _SeatBubble(
                          seat: seat,
                          size: seatSize,
                          isThrone: false,
                          isLocal: seat.userId == currentUserId,
                          isMicLive: seat.userId == currentUserId && !seat.isMuted,
                          onTap: () => onSeatTap(idx, seat),
                          onLongPress: onSeatLongPress != null ? () => onSeatLongPress!(idx, seat) : null,
                        ),
                      );
                    }),
                  ),
                );
              }),
              SizedBox(height: 4 * scale),
            ],
          ),
        );
      },
    );
  }
}

class _SeatBubble extends StatelessWidget {
  final SeatModel seat;
  final double size;
  final bool isThrone;
  final bool isLocal;
  final bool isMicLive;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _SeatBubble({
    required this.seat,
    required this.size,
    required this.isThrone,
    required this.isLocal,
    required this.isMicLive,
    required this.onTap,
    this.onLongPress,
  });

  String get _roleLabel {
    switch (seat.role) {
      case 'owner':
      case 'host':
        return 'Dono';
      case 'moderator':
        return 'Mod';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final occupied = seat.isOccupied;
    final color = isThrone
        ? AppTheme.dourado
        : isLocal
            ? AppTheme.lilas
            : occupied
                ? AppTheme.roxo
                : AppTheme.cinzaMedio;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SunlightNeonGlow(
        color: color,
        borderRadius: size / 2,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: isThrone ? 0.55 : 0.35),
                AppTheme.preto.withValues(alpha: 0.94),
              ],
            ),
            border: Border.all(
              color: isMicLive ? AppTheme.dourado : color.withValues(alpha: 0.85),
              width: isThrone ? 2.5 : 1.5,
            ),
            boxShadow: isMicLive
                ? [BoxShadow(color: AppTheme.dourado.withValues(alpha: 0.45), blurRadius: 12)]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(isThrone ? '👑' : (occupied ? '🎤' : '＋'), style: TextStyle(fontSize: isThrone ? 20 : 15)),
              if (isThrone)
                const Text('TRONO', style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: AppTheme.dourado, letterSpacing: 0.5)),
              if (_roleLabel.isNotEmpty && occupied)
                Text(_roleLabel, style: const TextStyle(fontSize: 7, color: AppTheme.branco)),
              if (occupied && seat.userName != null)
                Text(
                  seat.userName!.split(' ').first,
                  style: const TextStyle(fontSize: 7, color: AppTheme.branco),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
