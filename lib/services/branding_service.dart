import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sofia/services/branding_protection_service.dart';

class SofiaCover {
  final String id;
  final String title;
  final String assetPath;
  final bool isProtected;

  const SofiaCover({
    required this.id,
    required this.title,
    required this.assetPath,
    this.isProtected = true,
  });
}

class CoverVariantContent {
  final String contentType;
  final String? svgContent;
  final Uint8List? imageBytes;

  const CoverVariantContent({
    required this.contentType,
    this.svgContent,
    this.imageBytes,
  });

  bool get isPng => contentType.contains('png');
  bool get isSvg => contentType.contains('svg');
  bool get hasContent => svgContent != null || imageBytes != null;
}

class BrandingService extends ChangeNotifier {
  static const String _prefKey = 'sofia_active_cover';
  static const String _adminApiUrl = 'http://192.168.0.248:3000/api/branding';
  static const String _coverApiBase = 'http://192.168.0.248:3000/api/covers';
  static const String _clientToken = 'sofia-app-v1';

  static const variants = ['icon', 'splash', 'background'];

  String _activeCoverId = 'capa1';
  bool _isLoading = false;
  final Map<String, Map<String, CoverVariantContent>> _coverCache = {};

  String get activeCoverId => _activeCoverId;
  bool get isLoading => _isLoading;

  CoverVariantContent? coverVariant(String coverId, String variant) =>
      _coverCache[coverId]?[variant];

  CoverVariantContent? get activeSplash =>
      coverVariant(_activeCoverId, 'splash') ?? coverVariant(_activeCoverId, 'background');

  CoverVariantContent? get activeBackground =>
      coverVariant(_activeCoverId, 'background') ?? coverVariant(_activeCoverId, 'splash');

  CoverVariantContent? get activeIcon =>
      coverVariant(_activeCoverId, 'icon');

  String? get activeCoverSvg {
    final splash = activeSplash;
    if (splash?.isSvg == true) return splash!.svgContent;
    return null;
  }

  List<SofiaCover> get allCovers => BrandingProtectionService.coverPaths.entries
      .map((e) => SofiaCover(
            id: e.key,
            title: BrandingProtectionService.coverTitles[e.key] ?? e.key,
            assetPath: e.value,
          ))
      .toList();

  SofiaCover get activeCover =>
      allCovers.firstWhere((c) => c.id == _activeCoverId, orElse: () => allCovers.first);

  String get activeCoverPath => activeCover.assetPath;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await _loadFromPreferences();
    await _syncFromAdminApi();
    await _loadAllCoverContent();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAllCoverContent() async {
    for (final id in BrandingProtectionService.coverPaths.keys) {
      for (final variant in variants) {
        await _fetchCoverContent(id, variant);
      }
    }
  }

  Future<CoverVariantContent?> _fetchCoverContent(String coverId, String variant) async {
    try {
      final response = await http.get(
        Uri.parse('$_coverApiBase/$coverId/content?variant=$variant'),
        headers: {'X-Sofia-Client': _clientToken},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['content'] as String?;
      final contentType = data['contentType'] as String? ?? 'image/png';
      if (content == null || content.isEmpty) return null;

      final parsed = _parseCoverPayload(content, contentType);
      _coverCache.putIfAbsent(coverId, () => {})[variant] = parsed;
      return parsed;
    } catch (_) {
      return null;
    }
  }

  CoverVariantContent _parseCoverPayload(String content, String contentType) {
    if (contentType.contains('svg')) {
      try {
        final decoded = utf8.decode(base64Decode(content));
        return CoverVariantContent(contentType: contentType, svgContent: decoded);
      } catch (_) {
        return CoverVariantContent(contentType: contentType, svgContent: content);
      }
    }
    return CoverVariantContent(
      contentType: contentType,
      imageBytes: base64Decode(content),
    );
  }

  Future<void> _loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && BrandingProtectionService.coverPaths.containsKey(saved)) {
      _activeCoverId = saved;
    }
  }

  Future<void> _syncFromAdminApi() async {
    try {
      final response = await http.get(Uri.parse(_adminApiUrl)).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final coverId = data['activeCoverId'] as String?;
        if (coverId != null && BrandingProtectionService.coverPaths.containsKey(coverId)) {
          _activeCoverId = coverId;
          await _saveToPreferences(coverId);
        }
      }
    } catch (_) {
      // Admin API offline — usa preferência local
    }
  }

  Future<bool> setActiveCover(String coverId) async {
    if (!BrandingProtectionService.coverPaths.containsKey(coverId)) return false;

    try {
      await http.post(
        Uri.parse(_adminApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'activeCoverId': coverId}),
      );
    } catch (_) {}

    _activeCoverId = coverId;
    await _saveToPreferences(coverId);
    for (final variant in variants) {
      await _fetchCoverContent(coverId, variant);
    }
    notifyListeners();
    return true;
  }

  Future<void> refreshFromServer() async {
    await _syncFromAdminApi();
    await _loadAllCoverContent();
    notifyListeners();
  }

  Future<void> _saveToPreferences(String coverId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, coverId);
  }

  Map<String, dynamic> toJson() => {
        'activeCoverId': _activeCoverId,
        'covers': allCovers
            .map((c) => {
                  'id': c.id,
                  'title': c.title,
                  'path': c.assetPath,
                  'cached': _coverCache.containsKey(c.id),
                })
            .toList(),
      };
}
