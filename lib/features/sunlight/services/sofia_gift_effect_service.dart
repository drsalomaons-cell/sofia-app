import 'package:flutter/foundation.dart';
import 'package:sofia/features/sunlight/catalog/sofia_gift_catalog.dart';

class ActiveGiftEffect {
  final String giftId;
  final String senderName;
  final String emoji;

  const ActiveGiftEffect({
    required this.giftId,
    required this.senderName,
    required this.emoji,
  });
}

/// Animações de presentes (foguetes, coroas, etc.) — padrão Sunlight Live.
class SofiaGiftEffectService extends ChangeNotifier {
  ActiveGiftEffect? _activeEffect;

  ActiveGiftEffect? get activeEffect => _activeEffect;

  Future<void> playGift({required String giftId, required String senderName}) async {
    final def = SofiaGiftCatalog.byId(giftId);
    _activeEffect = ActiveGiftEffect(
      giftId: giftId,
      senderName: senderName,
      emoji: def?.iconEmoji ?? '🎁',
    );
    notifyListeners();

    final duration = giftId == 'rocket' || giftId == 'car'
        ? const Duration(milliseconds: 2200)
        : const Duration(milliseconds: 1600);
    await Future<void>.delayed(duration);

    if (_activeEffect?.giftId == giftId) {
      _activeEffect = null;
      notifyListeners();
    }
  }
}
