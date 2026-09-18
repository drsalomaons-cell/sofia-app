enum GiftLuxuryTier { common, rare, epic, legendary, mythic }

extension GiftLuxuryTierX on GiftLuxuryTier {
  String get label => switch (this) {
        GiftLuxuryTier.common => 'Comum',
        GiftLuxuryTier.rare => 'Raro',
        GiftLuxuryTier.epic => 'Épico',
        GiftLuxuryTier.legendary => 'Lendário',
        GiftLuxuryTier.mythic => 'Mítico',
      };
}
