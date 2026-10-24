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
    // O primeiro lugar é sempre o trono do dono. As fileiras seguintes
    // mantêm no máximo quatro cadeiras: 1 + 4 + 4 para a sala de 9 lugares.
    var left = (total - 1).clamp(0, 64);
    final rows = <int>[];
    while (left > 0) {
      final count = left > 4 ? 4 : left;
      rows.add(count);
      left -= count;
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
    final scale = SunlightRoomLayout.compactScale(context);
    final seatSize = 62.0 * scale;

    // Grade uniforme de três colunas: os primeiros nove lugares formam
    // exatamente o 3x3 do design; salas com mais lugares continuam roláveis.
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(2, 8 * scale, 2, 12 * scale),
          physics: const BouncingScrollPhysics(),
          itemCount: count,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4 * scale,
            mainAxisSpacing: 10 * scale,
            mainAxisExtent: 104 * scale,
          ),
          itemBuilder: (context, index) {
            final seat = _seatAt(index);
            final isThrone = index == 0;
            return Center(
              child: _SeatBubble(
                seat: seat,
                size: isThrone ? 68.0 * scale : seatSize,
                photoUrl: seat.photoUrl,
                level: seat.level,
                isThrone: isThrone,
                isLocal: seat.userId == currentUserId,
                isMicLive: seat.userId == currentUserId && !seat.isMuted,
                onTap: () => onSeatTap(index, seat),
                onLongPress: onSeatLongPress != null
                    ? () => onSeatLongPress!(index, seat)
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

class _SeatBubble extends StatelessWidget {
  final SeatModel seat;
  final double size;
  final String? photoUrl;
  final int level;
  final bool isThrone;
  final bool isLocal;
  final bool isMicLive;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _SeatBubble({
    required this.seat,
    required this.size,
    this.photoUrl,
    this.level = 1,
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

  Widget _seatFallbackIcon({required bool occupied, required bool isThrone}) {
    return Container(
      color: const Color(0xFF27283D),
      alignment: Alignment.center,
      child: Icon(
        isThrone
            ? Icons.workspace_premium_rounded
            : occupied
            ? Icons.person_rounded
            : Icons.add_circle_outline_rounded,
        color: isThrone ? const Color(0xFFFFD81D) : const Color(0xFF00DCE6),
        size: isThrone ? 25 : 22,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final occupied = seat.isOccupied;
    const cyan = Color(0xFF00F2FE);
    const violet = Color(0xFFDBB8FF);
    const gold = Color(0xFFFFD81D);
    const muted = Color(0xFF3A494B);
    final color = isThrone
        ? gold
        : isLocal
        ? cyan
        : occupied
        ? violet
        : muted;

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
                const Color(0xFF0B0C1F).withValues(alpha: 0.96),
              ],
            ),
            border: Border.all(
              color: isMicLive
                  ? AppTheme.dourado
                  : color.withValues(alpha: 0.85),
              width: isThrone ? 2.5 : 1.5,
            ),
            boxShadow: isMicLive
                ? [
                    BoxShadow(
                      color: AppTheme.dourado.withValues(alpha: 0.45),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: size * 0.64,
                height: size * 0.64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipOval(
                      child:
                          occupied &&
                              photoUrl != null &&
                              (photoUrl!.startsWith('https://') ||
                                  photoUrl!.startsWith('http://'))
                          ? Image.network(
                              photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _seatFallbackIcon(
                                occupied: occupied,
                                isThrone: isThrone,
                              ),
                            )
                          : _seatFallbackIcon(
                              occupied: occupied,
                              isThrone: isThrone,
                            ),
                    ),
                    if (isThrone || (occupied && level > 1))
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Icon(
                          isThrone
                              ? Icons.workspace_premium_rounded
                              : Icons.military_tech_rounded,
                          color: AppTheme.dourado,
                          size: 13,
                        ),
                      ),
                  ],
                ),
              ),
              if (occupied)
                Text(
                  'Lv $level',
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppTheme.dourado,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              if (isThrone)
                const Text(
                  'TRONO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dourado,
                    letterSpacing: 0.5,
                  ),
                ),
              if (_roleLabel.isNotEmpty && occupied) const SizedBox(height: 1),
              if (_roleLabel.isNotEmpty && occupied)
                Text(
                  _roleLabel,
                  style: const TextStyle(fontSize: 9, color: AppTheme.branco),
                ),
              if (occupied && seat.userName != null)
                Text(
                  seat.userName!.split(' ').first,
                  style: const TextStyle(fontSize: 9, color: AppTheme.branco),
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
