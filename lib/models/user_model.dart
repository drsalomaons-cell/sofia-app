class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String gender;
  final int? age;
  final String? wealthLevel;
  final int charmLevel;
  final String interestedIn;
  final String? photoUrl;
  final List<String> gallery;
  final double balance;
  final double coins;
  final double diamonds;
  final int level;
  final String? levelTitle;
  final String? frame;
  final String? vipTier;
  final String? vipTag;
  final int hostLevel;
  final int points;
  final int referrals;
  final bool isAdmin;
  final bool isRegionalAdmin;
  final String? region;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.gender,
    this.age,
    this.wealthLevel,
    this.charmLevel = 0,
    required this.interestedIn,
    this.photoUrl,
    this.gallery = const [],
    this.balance = 0.0,
    this.coins = 0.0,
    this.diamonds = 0.0,
    this.level = 1,
    this.levelTitle,
    this.frame,
    this.vipTier,
    this.vipTag,
    this.hostLevel = 0,
    this.points = 0,
    this.referrals = 0,
    this.isAdmin = false,
    this.isRegionalAdmin = false,
    this.region,
    required this.createdAt,
    this.lastLogin,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? gender,
    int? age,
    String? wealthLevel,
    int? charmLevel,
    String? interestedIn,
    String? photoUrl,
    List<String>? gallery,
    double? balance,
    double? coins,
    double? diamonds,
    int? level,
    String? levelTitle,
    String? frame,
    String? vipTier,
    String? vipTag,
    int? hostLevel,
    int? points,
    int? referrals,
    bool? isAdmin,
    bool? isRegionalAdmin,
    String? region,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      wealthLevel: wealthLevel ?? this.wealthLevel,
      charmLevel: charmLevel ?? this.charmLevel,
      interestedIn: interestedIn ?? this.interestedIn,
      photoUrl: photoUrl ?? this.photoUrl,
      gallery: gallery ?? this.gallery,
      balance: balance ?? this.balance,
      coins: coins ?? this.coins,
      diamonds: diamonds ?? this.diamonds,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      frame: frame ?? this.frame,
      vipTier: vipTier ?? this.vipTier,
      vipTag: vipTag ?? this.vipTag,
      hostLevel: hostLevel ?? this.hostLevel,
      points: points ?? this.points,
      referrals: referrals ?? this.referrals,
      isAdmin: isAdmin ?? this.isAdmin,
      isRegionalAdmin: isRegionalAdmin ?? this.isRegionalAdmin,
      region: region ?? this.region,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'gender': gender,
      'age': age,
      'wealthLevel': wealthLevel,
      'charmLevel': charmLevel,
      'interestedIn': interestedIn,
      'photoUrl': photoUrl,
      'gallery': gallery,
      'balance': balance,
      'coins': coins,
      'diamonds': diamonds,
      'level': level,
      'levelTitle': levelTitle,
      'frame': frame,
      'vipTier': vipTier,
      'vipTag': vipTag,
      'hostLevel': hostLevel,
      'points': points,
      'referrals': referrals,
      'isAdmin': isAdmin,
      'isRegionalAdmin': isRegionalAdmin,
      'region': region,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      gender: json['gender'],
      age: int.tryParse(json['age']?.toString() ?? ''),
      wealthLevel: json['wealthLevel']?.toString(),
      charmLevel:
          int.tryParse(json['charmLevel']?.toString() ?? '') ??
          int.tryParse(json['points']?.toString() ?? '') ??
          0,
      interestedIn: json['interestedIn'],
      photoUrl: json['photoUrl']?.toString(),
      gallery: (json['gallery'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
      balance: json['balance']?.toDouble() ?? 0.0,
      coins: json['coins']?.toDouble() ?? json['balance']?.toDouble() ?? 0.0,
      diamonds: json['diamonds']?.toDouble() ?? 0.0,
      level: json['level'] ?? 1,
      levelTitle: json['levelTitle']?.toString(),
      frame: json['frame']?.toString(),
      vipTier: json['vipTier']?.toString(),
      vipTag: json['vipTag']?.toString(),
      hostLevel: json['hostLevel'] ?? 0,
      points: json['points'] ?? 0,
      referrals: json['referrals'] ?? 0,
      isAdmin: json['isAdmin'] ?? false,
      isRegionalAdmin: json['isRegionalAdmin'] ?? false,
      region: json['region'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
    );
  }
}
