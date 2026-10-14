import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/features/sunlight/catalog/sofia_gift_catalog.dart';
import 'package:sofia/features/sunlight/services/sofia_gift_effect_service.dart';
import 'package:sofia/providers/wallet_provider.dart';
import 'package:sofia/services/api_client.dart';
import 'package:sofia/services/socket_service.dart';

Future<void> sendSofiaGift(
  BuildContext context,
  SofiaGiftItem gift, {
  String? roomId,
  String? roomName,
  String? recipientId,
  bool isHost = false,
  int participantCount = 1,
}) async {
  final auth = context.read<AuthProvider>();
  final wallet = context.read<WalletProvider>();
  final effect = context.read<SofiaGiftEffectService>();
  final user = auth.user;

  if (user == null ||
      roomId == null ||
      recipientId == null ||
      recipientId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Entre em uma sala com um destinatário disponível para enviar presentes.',
        ),
      ),
    );
    return;
  }

  final result = await ApiClient.postRaw('/api/gifts/send', {
    'senderId': user.id,
    'recipientId': recipientId,
    'giftId': gift.id,
    'roomId': roomId,
  });

  if (result == null || result['success'] != true) {
    if (context.mounted) {
      final message =
          result?['error']?.toString() ??
          'Falha ao enviar presente. Verifique sua conexão e saldo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
    return;
  }

  if (context.mounted) {
    context.read<SocketService>().emitGift(roomId, {
      'senderId': user.id,
      'senderName': user.name,
      'recipientId': recipientId,
      'giftId': gift.id,
      'giftName': gift.name,
      'amount': gift.coinCost,
    });
  }
  await effect.playGift(giftId: gift.id, senderName: user.name);
  await wallet.loadTransactions();

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${gift.iconEmoji} ${gift.name} enviado por ${gift.coinCost} moedas!',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
