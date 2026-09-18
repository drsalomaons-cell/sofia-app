import 'package:sofia/features/sunlight/catalog/gift_luxury_tier.dart';

class SofiaGiftItem {
  final String id;
  final String name;
  final String iconEmoji;
  final int coinCost;
  final GiftLuxuryTier tier;
  final bool isLucky;
  final String? soundAsset;

  const SofiaGiftItem({
    required this.id,
    required this.name,
    required this.iconEmoji,
    required this.coinCost,
    required this.tier,
    this.isLucky = false,
    this.soundAsset,
  });
}

class SofiaGiftCatalog {
  SofiaGiftCatalog._();

  static const catalog = <SofiaGiftItem>[
    SofiaGiftItem(id: 'rose', name: 'Rosa', iconEmoji: '🌹', coinCost: 10, tier: GiftLuxuryTier.common),
    SofiaGiftItem(id: 'heart', name: 'Coração', iconEmoji: '💖', coinCost: 30, tier: GiftLuxuryTier.common),
    SofiaGiftItem(id: 'star', name: 'Estrela', iconEmoji: '⭐', coinCost: 50, tier: GiftLuxuryTier.rare),
    SofiaGiftItem(id: 'frame', name: 'Moldura', iconEmoji: '🖼️', coinCost: 120, tier: GiftLuxuryTier.rare),
    SofiaGiftItem(id: 'crown', name: 'Coroa', iconEmoji: '👑', coinCost: 200, tier: GiftLuxuryTier.epic),
    SofiaGiftItem(id: 'car', name: 'Carro VIP', iconEmoji: '🚗', coinCost: 350, tier: GiftLuxuryTier.epic),
    SofiaGiftItem(id: 'rocket', name: 'Foguete', iconEmoji: '🚀', coinCost: 500, tier: GiftLuxuryTier.legendary, isLucky: true),
    SofiaGiftItem(id: 'trophy', name: 'Troféu', iconEmoji: '🏆', coinCost: 800, tier: GiftLuxuryTier.legendary),
    SofiaGiftItem(id: 'diamond', name: 'Diamante', iconEmoji: '💎', coinCost: 1000, tier: GiftLuxuryTier.mythic),
  ];

  static List<SofiaGiftItem> get gifts => catalog;

  static SofiaGiftItem? byId(String id) {
    for (final g in catalog) {
      if (g.id == id) return g;
    }
    return null;
  }
}
