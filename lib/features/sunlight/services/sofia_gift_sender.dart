import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/features/auth/providers/auth_provider.dart';
import 'package:sofia/features/sunlight/catalog/sofia_gift_catalog.dart';
import 'package:sofia/features/sunlight/services/sofia_gift_effect_service.dart';
import 'package:sofia/providers/wallet_provider.dart';
import 'package:sofia/routes/app_routes.dart';
import 'package:sofia/services/api_client.dart';
import 'package:sofia/services/socket_service.dart';

Future<bool> sendSofiaGift(
  BuildContext context,
  SofiaGiftItem gift, {
  String? roomId,
  String? roomName,
  String? recipientId,
  bool isHost = false,
  int participantCount = 1,
  VoidCallback? onInsufficientBalance,
  int combo = 1,
  void Function(String message)? onError,
}) async {
  final auth = context.read<AuthProvider>();
  final wallet = context.read<WalletProvider>();
  final effect = context.read<SofiaGiftEffectService>();
  final user = auth.user;

  if (user == null ||
      roomId == null ||
      recipientId == null ||
      recipientId.isEmpty) {
    onError?.call('Entre em uma sala com um destinatário disponível para enviar presentes.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Entre em uma sala com um destinatário disponível para enviar presentes.',
        ),
      ),
    );
    return false;
  }

  Map<String, dynamic>? result;
  var delivered = 0;
  final total = combo < 1 ? 1 : combo;
  for (var i = 0; i < total; i++) {
    try {
      result = await ApiClient.postRaw('/api/gifts/send', {
        'senderId': user.id,
        'recipientId': recipientId,
        'giftId': gift.id,
        'roomId': roomId,
      });
    } catch (e) {
      result = {'error': e.toString().replaceFirst('Exception: ', '')};
      break;
    }
    if (result == null || result['success'] != true) break;
    delivered++;
  }

  if (delivered == 0) {
    if (context.mounted) {
      final rawMessage =
          result?['error']?.toString() ??
          'Falha ao enviar presente. Verifique sua conexão e saldo.';
      final message =
          (recipientId == user.id &&
              rawMessage.toLowerCase().contains('bloqueado'))
          ? 'Auto-presente bloqueado pelo servidor. Aguarde o deploy da liberação de teste ou use outro usuário na sala.'
          : rawMessage;
      final normalized = message.toLowerCase();
      final insufficient =
          normalized.contains('saldo') ||
          normalized.contains('insuficiente') ||
          normalized.contains('insufficient') ||
          normalized.contains('coins');
      if (insufficient) {
        onInsufficientBalance?.call();
      } else {
        onError?.call(message);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: insufficient
              ? SnackBarAction(
                  label: 'RECARREGAR',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.wallet);
                  },
                )
              : null,
        ),
      );
    }
    return false;
  }

  if (context.mounted) {
    context.read<SocketService>().emitGift(roomId, {
      'senderId': user.id,
      'senderName': user.name,
      'recipientId': recipientId,
      'giftId': gift.id,
      'giftName': gift.name,
      'amount': gift.coinCost * delivered,
      'count': delivered,
    });
  }
  unawaited(effect.playGift(giftId: gift.id, senderName: user.name));
  await wallet.loadTransactions();

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${gift.iconEmoji} ${gift.name}${delivered > 1 ? ' x$delivered' : ''} enviado por ${gift.coinCost * delivered} moedas!',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  return true;
}
