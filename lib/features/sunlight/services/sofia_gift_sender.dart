import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/features/sunlight/catalog/sofia_gift_catalog.dart';
import 'package:sofia/features/sunlight/services/sofia_gift_effect_service.dart';
import 'package:sofia/providers/wallet_provider.dart';

Future<void> sendSofiaGift(
  BuildContext context,
  SofiaGiftItem gift, {
  String? roomId,
  String? roomName,
  bool isHost = false,
  int participantCount = 1,
}) async {
  final auth = context.read<AuthProvider>();
  final wallet = context.read<WalletProvider>();
  final effect = context.read<SofiaGiftEffectService>();
  final sender = auth.user?.name ?? 'Você';

  await effect.playGift(giftId: gift.id, senderName: sender);

  if (roomId != null && auth.user != null) {
    await wallet.addEarning(
      roomId: roomId,
      roomName: roomName ?? 'Sala',
      totalAmount: gift.coinCost.toDouble(),
      participantCount: participantCount.clamp(1, 20),
      isHost: isHost,
      roomGoalMet: false,
      isOpeningEvent: false,
    );
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${gift.iconEmoji} ${gift.name} enviado!'), duration: const Duration(seconds: 2)),
    );
  }
}
