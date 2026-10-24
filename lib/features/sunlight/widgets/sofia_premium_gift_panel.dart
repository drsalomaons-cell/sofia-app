import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sofia/features/sunlight/catalog/gift_luxury_tier.dart';
import 'package:sofia/features/sunlight/catalog/sofia_gift_catalog.dart';
import 'package:sofia/features/sunlight/services/sofia_gift_sender.dart';
import 'package:sofia/features/sunlight/theme/sofia_premium_theme.dart';
import 'package:sofia/features/sunlight/widgets/sunlight_neon_glow.dart';
import 'package:sofia/providers/wallet_provider.dart';
import 'package:sofia/routes/app_routes.dart';

void showSofiaPremiumGiftPanel(
  BuildContext context, {
  required String? roomId,
  required String roomName,
  required bool isHost,
  required int participantCount,
  String? recipientId,
  void Function(SofiaGiftItem gift, int combo)? onGiftSent,
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
      recipientId: recipientId,
      onGiftSent: onGiftSent,
    ),
  );
}

class _SofiaGiftPanelSheet extends StatefulWidget {
  final String? roomId;
  final String roomName;
  final bool isHost;
  final int participantCount;
  final String? recipientId;
  final void Function(SofiaGiftItem gift, int combo)? onGiftSent;

  const _SofiaGiftPanelSheet({
    required this.roomId,
    required this.roomName,
    required this.isHost,
    required this.participantCount,
    required this.recipientId,
    this.onGiftSent,
  });

  @override
  State<_SofiaGiftPanelSheet> createState() => _SofiaGiftPanelSheetState();
}

class _SofiaGiftPanelSheetState extends State<_SofiaGiftPanelSheet> {
  SofiaGiftItem? _selectedGift;
  bool _sending = false;
  bool _sentSuccessfully = false;
  bool _insufficientBalance = false;
  int _combo = 1;

  Future<void> _sendSelectedGift() async {
    final gift = _selectedGift;
    if (gift == null || _sending) return;

    final wallet = context.read<WalletProvider>();
    if (wallet.coins < gift.coinCost * _combo) {
      setState(() => _insufficientBalance = true);
      return;
    }

    setState(() {
      _sending = true;
      _sentSuccessfully = false;
      _insufficientBalance = false;
    });

    var sent = false;
    try {
      sent = await sendSofiaGift(
        context,
        gift,
        roomId: widget.roomId,
        roomName: widget.roomName,
        recipientId: widget.recipientId,
        isHost: widget.isHost,
        participantCount: widget.participantCount,
        combo: _combo,
        onInsufficientBalance: () {
          if (mounted) setState(() => _insufficientBalance = true);
        },
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível enviar. Verifique a conexão e o saldo.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }

    if (mounted && sent) {
      widget.onGiftSent?.call(gift, _combo);
      setState(() {
        _sentSuccessfully = true;
        _insufficientBalance = false;
      });
    }
  }

  void _continueSending() {
    setState(() {
      _selectedGift = null;
      _sentSuccessfully = false;
      _insufficientBalance = false;
    });
  }

  Color _accentFor(SofiaGiftItem gift) => switch (gift.tier) {
    GiftLuxuryTier.mythic => SofiaPremiumTheme.gold,
    GiftLuxuryTier.legendary => SofiaPremiumTheme.pink,
    GiftLuxuryTier.epic => SofiaPremiumTheme.purple,
    GiftLuxuryTier.rare => const Color(0xFF4F8CFF),
    GiftLuxuryTier.common => SofiaPremiumTheme.pink,
  };

  @override
  Widget build(BuildContext context) {
    final gifts = SofiaGiftCatalog.gifts;
    final maxH = MediaQuery.sizeOf(context).height * 0.78;

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
                SofiaPremiumTheme.purpleDeep.withValues(alpha: 0.97),
                SofiaPremiumTheme.darkBg.withValues(alpha: 0.99),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: SofiaPremiumTheme.gold.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Presentes VIP SOFIA',
                    style: TextStyle(
                      color: SofiaPremiumTheme.goldSoft,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Consumer<WalletProvider>(
                    builder: (_, wallet, __) => Text(
                      '${wallet.coins.toStringAsFixed(0)} 🪙 disponíveis',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (_sentSuccessfully) ...[
                    const SizedBox(height: 12),
                    AnimatedScale(
                      scale: _sentSuccessfully ? 1 : 0.7,
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.elasticOut,
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF55E69A),
                        size: 54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedGift?.iconEmoji ?? '🎁'} Presente enviado com sucesso!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF55E69A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Flexible(
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.82,
                          ),
                      itemCount: gifts.length,
                      itemBuilder: (context, index) {
                        final gift = gifts[index];
                        final accent = _accentFor(gift);
                        final selected = _selectedGift?.id == gift.id;
                        return GestureDetector(
                          onTap: _sending
                              ? null
                              : () => setState(() {
                                  _selectedGift = gift;
                                  _sentSuccessfully = false;
                                }),
                          child: SunlightNeonGlow(
                            color: accent,
                            borderRadius: 14,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: [
                                    accent.withValues(
                                      alpha: selected ? 0.48 : 0.25,
                                    ),
                                    Colors.white.withValues(alpha: 0.06),
                                  ],
                                ),
                                border: Border.all(
                                  color: selected
                                      ? Colors.white
                                      : accent.withValues(alpha: 0.5),
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    gift.iconEmoji,
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    gift.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                    ),
                                  ),
                                  Text(
                                    '${gift.coinCost} 🪙',
                                    style: const TextStyle(
                                      color: SofiaPremiumTheme.goldSoft,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_sentSuccessfully && !_insufficientBalance)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Combo',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          for (final n in const [1, 5, 10, 30])
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: ChoiceChip(
                                label: Text('x$n'),
                                selected: _combo == n,
                                onSelected: _sending
                                    ? null
                                    : (_) => setState(() => _combo = n),
                                selectedColor: SofiaPremiumTheme.gold,
                                backgroundColor: Colors.white10,
                                labelStyle: TextStyle(
                                  color: _combo == n
                                      ? SofiaPremiumTheme.darkBg
                                      : Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (_insufficientBalance)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Saldo insuficiente para este presente.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFFF7777),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            final navigator = Navigator.of(context);
                            navigator.pop();
                            navigator.pushNamed(AppRoutes.wallet);
                          },
                          icon: const Icon(
                            Icons.account_balance_wallet_rounded,
                          ),
                          label: const Text('Recarregar carteira'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SofiaPremiumTheme.gold,
                            foregroundColor: SofiaPremiumTheme.darkBg,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    )
                  else if (_sentSuccessfully)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _continueSending,
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Continuar Enviando'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SofiaPremiumTheme.gold,
                          foregroundColor: SofiaPremiumTheme.darkBg,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Consumer<WalletProvider>(
                          builder: (_, wallet, __) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: SofiaPremiumTheme.gold.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 17,
                                  color: SofiaPremiumTheme.goldSoft,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  wallet.coins.toStringAsFixed(0),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _selectedGift == null || _sending
                                ? null
                                : _sendSelectedGift,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SofiaPremiumTheme.gold,
                              foregroundColor: SofiaPremiumTheme.darkBg,
                              disabledBackgroundColor: Colors.white12,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _selectedGift == null
                                        ? 'Escolher'
                                        : 'Enviar${_combo > 1 ? ' x$_combo' : ''} • ${_selectedGift!.coinCost * _combo} 🪙',
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        ),
                      ],
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
