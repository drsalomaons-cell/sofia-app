import 'package:sofia/services/api_client.dart';

class EconomyRules {
  final Map<String, dynamic> config;
  final List<dynamic> levelTable;
  final List<dynamic> vipTiers;
  final Map<String, dynamic> summary;

  EconomyRules({
    required this.config,
    required this.levelTable,
    required this.vipTiers,
    required this.summary,
  });

  factory EconomyRules.fromJson(Map<String, dynamic> json) {
    return EconomyRules(
      config: Map<String, dynamic>.from(json['config'] as Map? ?? {}),
      levelTable: json['levelTable'] as List? ?? [],
      vipTiers: json['vipTiers'] as List? ?? [],
      summary: Map<String, dynamic>.from(json['summary'] as Map? ?? {}),
    );
  }
}

class WalletProfile {
  final double balance;
  final double coins;
  final double diamonds;
  final int level;
  final String? levelTitle;
  final String? frame;
  final String? vipTier;
  final String? vipTag;
  final int points;
  final int hostLevel;
  final Map<String, dynamic>? hostSalary;

  WalletProfile({
    required this.balance,
    required this.coins,
    required this.diamonds,
    required this.level,
    this.levelTitle,
    this.frame,
    this.vipTier,
    this.vipTag,
    this.points = 0,
    this.hostLevel = 0,
    this.hostSalary,
  });

  factory WalletProfile.fromJson(Map<String, dynamic> json) {
    return WalletProfile(
      balance: json['balance']?.toDouble() ?? 0,
      coins: json['coins']?.toDouble() ?? json['balance']?.toDouble() ?? 0,
      diamonds: json['diamonds']?.toDouble() ?? 0,
      level: json['level'] ?? 1,
      levelTitle: json['levelTitle']?.toString(),
      frame: json['frame']?.toString(),
      vipTier: json['vipTier']?.toString(),
      vipTag: json['vipTag']?.toString(),
      points: json['points'] ?? 0,
      hostLevel: json['hostLevel'] ?? 0,
      hostSalary: json['hostSalary'] != null
          ? Map<String, dynamic>.from(json['hostSalary'] as Map)
          : null,
    );
  }
}

class EconomyService {
  EconomyRules? _cached;

  Future<EconomyRules> getRules({bool refresh = false}) async {
    if (_cached != null && !refresh) return _cached!;
    final data = await ApiClient.get('/api/economy/rules');
    if (data == null) throw Exception('Regras econômicas indisponíveis');
    _cached = EconomyRules.fromJson(Map<String, dynamic>.from(data));
    return _cached!;
  }

  Future<WalletProfile> getWalletProfile(String userId) async {
    final data = await ApiClient.get('/api/wallet/$userId/balance');
    if (data == null) throw Exception('Perfil da carteira indisponível');
    return WalletProfile.fromJson(Map<String, dynamic>.from(data));
  }
}
