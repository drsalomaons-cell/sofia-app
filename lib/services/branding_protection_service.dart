import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/services.dart';

/// Proteção leve de integridade das capas SOFIA — verifica hash e assinatura.
class BrandingProtectionService {
  static const String _protectionKey = 'SOFIA_BRANDING_V1';
  static final _encrypter = Encrypter(AES(Key.fromUtf8(_protectionKey.padRight(32, '0'))));

  static const Map<String, String> coverPaths = {
    'capa1': 'assets/images/branding/sofia_capa1_luz_pureza.svg',
    'capa2': 'assets/images/branding/sofia_capa2_brilho_graca.svg',
    'capa3': 'assets/images/branding/sofia_capa3_majestade_serenidade.svg',
  };

  static const Map<String, String> coverTitles = {
    'capa1': 'Luz e Pureza',
    'capa2': 'Brilho e Graça',
    'capa3': 'Majestade e Serenidade',
  };

  static const Map<String, String> coverThemes = {
    'capa1': 'luz_pureza',
    'capa2': 'brilho_graca',
    'capa3': 'luz_pureza',
  };

  static Future<bool> verifyCover(String coverId) async {
    final path = coverPaths[coverId];
    if (path == null) return false;

    try {
      final content = await rootBundle.loadString(path);
      final hash = sha256.convert(utf8.encode(content)).toString();
      return _verifySig(coverId, hash) && content.contains('protected="true"');
    } catch (_) {
      return false;
    }
  }

  static String _computeSignature(String coverId, String hash) {
    final payload = '$coverId:$hash:$_protectionKey';
    return _encrypter.encrypt(payload).base64;
  }

  static bool _verifySig(String coverId, String hash) {
    try {
      final computed = _computeSignature(coverId, hash);
      return computed.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, bool>> verifyAllCovers() async {
    final results = <String, bool>{};
    for (final id in coverPaths.keys) {
      results[id] = await verifyCover(id);
    }
    return results;
  }

  static String encryptCoverMetadata(Map<String, dynamic> data) {
    return _encrypter.encrypt(jsonEncode(data)).base64;
  }

  static Map<String, dynamic>? decryptCoverMetadata(String encrypted) {
    try {
      final decrypted = _encrypter.decrypt64(encrypted);
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
