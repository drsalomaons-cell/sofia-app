import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/features/sunlight/catalog/gift_luxury_tier.dart';
import 'package:sofia/features/sunlight/catalog/sofia_gift_catalog.dart';
import 'package:sofia/features/sunlight/services/sofia_gift_sender.dart';
import 'package:sofia/features/sunlight/theme/sofia_premium_theme.dart';
import 'package:sofia/features/sunlight/widgets/sunlight_neon_glow.dart';
import 'package:sofia/providers/wallet_provider.dart';

void showSofiaPremiumGiftPanel(
  BuildContext context, {
  required String? roomId,
  required String roomName,
  required bool isHost,
  required int participantCount,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _SofiaGiftPanelSheet(
      roomId: roomId,
      roomName: roomName,
      isHost: isHost,
      participantCount: participantCount,
    ),
  );
}

class _SofiaGiftPanelSheet extends StatelessWidget {
  final String? roomId;
  final String roomName;
  final bool isHost;
  final int participantCount;

  const _SofiaGiftPanelSheet({
    required this.roomId,
    required this.roomName,
    required this.isHost,
    required this.participantCount,
  });

  @override
  Widget build(BuildContext context) {
    final gifts = SofiaGiftCatalog.gifts;
    final maxH = MediaQuery.sizeOf(context).height * 0.55;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxH),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                SofiaPremiumTheme.purpleDeep.withValues(alpha: 0.95),
                SofiaPremiumTheme.darkBg.withValues(alpha: 0.98),
              ],
            ),
            border: Border(top: BorderSide(color: SofiaPremiumTheme.gold.withValues(alpha: 0.5))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  const Text('Presentes VIP SOFIA', style: TextStyle(color: SofiaPremiumTheme.goldSoft, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Consumer<WalletProvider>(
                    builder: (_, wallet, __) => Text(
                      '${wallet.coins.toStringAsFixed(0)} 🪙 disponíveis',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: gifts.length,
                      itemBuilder: (context, index) => _GiftTile(
                        gift: gifts[index],
                        roomId: roomId,
                        roomName: roomName,
                        isHost: isHost,
                        participantCount: participantCount,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GiftTile extends StatelessWidget {
  final SofiaGiftItem gift;
  final String? roomId;
  final String roomName;
  final bool isHost;
  final int participantCount;

  const _GiftTile({
    required this.gift,
    required this.roomId,
    required this.roomName,
    required this.isHost,
    required this.participantCount,
  });

  Color get _accent => switch (gift.tier) {
        GiftLuxuryTier.mythic => SofiaPremiumTheme.gold,
        GiftLuxuryTier.legendary => SofiaPremiumTheme.pink,
        GiftLuxuryTier.epic => SofiaPremiumTheme.purple,
        GiftLuxuryTier.rare => const Color(0xFF4F8CFF),
        GiftLuxuryTier.common => SofiaPremiumTheme.pink,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        await sendSofiaGift(context, gift, roomId: roomId, roomName: roomName, isHost: isHost, participantCount: participantCount);
      },
      child: SunlightNeonGlow(
        color: _accent,
        borderRadius: 14,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: [_accent.withValues(alpha: 0.25), Colors.white.withValues(alpha: 0.06)]),
            border: Border.all(color: _accent.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(gift.iconEmoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 4),
              Text('${gift.coinCost}', style: const TextStyle(color: SofiaPremiumTheme.goldSoft, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
