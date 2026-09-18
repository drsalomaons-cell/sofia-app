import 'package:flutter/material.dart';
import 'package:sofia/features/sunlight/catalog/sofia_gift_catalog.dart';
import 'package:sofia/features/sunlight/services/sofia_gift_sender.dart';
import 'package:sofia/features/sunlight/theme/sofia_premium_theme.dart';
import 'package:sofia/features/sunlight/theme/sunlight_room_layout.dart';
import 'package:sofia/features/sunlight/widgets/sofia_premium_gift_panel.dart';

/// Botão VIP fixo — foguete rápido + painel completo ao segurar (Sunlight Live).
class SofiaPremiumVipGiftButton extends StatelessWidget {
  final String? roomId;
  final String roomName;
  final bool isHost;
  final int participantCount;

  const SofiaPremiumVipGiftButton({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.isHost,
    required this.participantCount,
  });

  static SofiaGiftItem get _rocket => SofiaGiftCatalog.byId('rocket')!;

  @override
  Widget build(BuildContext context) {
    final scale = SunlightRoomLayout.compactScale(context);

    return Positioned(
      right: 12 * scale,
      bottom: 72 * scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onLongPress: () => showSofiaPremiumGiftPanel(
                context,
                roomId: roomId,
                roomName: roomName,
                isHost: isHost,
                participantCount: participantCount,
              ),
              onTap: () => sendSofiaGift(
                context,
                _rocket,
                roomId: roomId,
                roomName: roomName,
                isHost: isHost,
                participantCount: participantCount,
              ),
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 10 * scale),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(colors: [SofiaPremiumTheme.gold, SofiaPremiumTheme.pink]),
                  boxShadow: [BoxShadow(color: SofiaPremiumTheme.gold.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🚀', style: TextStyle(fontSize: 20 * scale)),
                    SizedBox(width: 6 * scale),
                    Text('500', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13 * scale)),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 4 * scale),
          Text('Toque: Foguete · Segure: VIP', style: TextStyle(color: Colors.white38, fontSize: 8 * scale)),
        ],
      ),
    );
  }
}
