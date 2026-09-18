import 'package:flutter/foundation.dart';
import 'package:screen_protector/screen_protector.dart';

/// Proteção anti-captura de tela (Android/iOS). Web/desktop: noop seguro.
class ScreenProtectService {
  static bool _enabled = false;

  static Future<void> enable() async {
    if (kIsWeb || _enabled) return;
    try {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageOn();
      _enabled = true;
    } catch (_) {}
  }

  static Future<void> disable() async {
    if (!_enabled) return;
    try {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
    } catch (_) {}
    _enabled = false;
  }
}
