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
  final String? coverUrl;
  final String? bio;
  final List<String> gallery;
  final double balance;
  final double coins;
  final double diamonds;
  final int level;
  final String? levelTitle;
  final String? frame;
  final String? frameId;
  final String? vipTier;
  final String? vipTag;
  final int hostLevel;
  final int points;
  final int referrals;
  final int followersCount;
  final int followingCount;
  final int visitorsCount;
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
    this.coverUrl,
    this.bio,
    this.gallery = const [],
    this.balance = 0.0,
    this.coins = 0.0,
    this.diamonds = 0.0,
    this.level = 1,
    this.levelTitle,
    this.frame,
    this.frameId,
    this.vipTier,
    this.vipTag,
    this.hostLevel = 0,
    this.points = 0,
    this.referrals = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.visitorsCount = 0,
    this.isAdmin = false,
    this.isRegionalAdmin = false,
    this.region,
    required this.createdAt,
    this.lastLogin,
  });

  /// Identificador único da moldura equipada
  String get effectiveFrameId => frameId ?? frame ?? 'host_a';

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
    String? coverUrl,
    String? bio,
    List<String>? gallery,
    double? balance,
    double? coins,
    double? diamonds,
    int? level,
    String? levelTitle,
    String? frame,
    String? frameId,
    String? vipTier,
    String? vipTag,
    int? hostLevel,
    int? points,
    int? referrals,
    int? followersCount,
    int? followingCount,
    int? visitorsCount,
    bool? isAdmin,
    bool? isRegionalAdmin,
    String? region,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    final newFrame = frame ?? frameId ?? this.frame;
    final newFrameId = frameId ?? frame ?? this.frameId;

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
      coverUrl: coverUrl ?? this.coverUrl,
      bio: bio ?? this.bio,
      gallery: gallery ?? this.gallery,
      balance: balance ?? this.balance,
      coins: coins ?? this.coins,
      diamonds: diamonds ?? this.diamonds,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      frame: newFrame,
      frameId: newFrameId,
      vipTier: vipTier ?? this.vipTier,
      vipTag: vipTag ?? this.vipTag,
      hostLevel: hostLevel ?? this.hostLevel,
      points: points ?? this.points,
      referrals: referrals ?? this.referrals,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      visitorsCount: visitorsCount ?? this.visitorsCount,
      isAdmin: isAdmin ?? this.isAdmin,
      isRegionalAdmin: isRegionalAdmin ?? this.isRegionalAdmin,
      region: region ?? this.region,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  Map<String, dynamic> toJson() {
    final activeFrame = frameId ?? frame;
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
      'coverUrl': coverUrl,
      'cover_url': coverUrl,
      'bio': bio,
      'gallery': gallery,
      'balance': balance,
      'coins': coins,
      'diamonds': diamonds,
      'level': level,
      'levelTitle': levelTitle,
      'frame': activeFrame,
      'frameId': activeFrame,
      'frame_id': activeFrame,
      'vipTier': vipTier,
      'vipTag': vipTag,
      'hostLevel': hostLevel,
      'points': points,
      'referrals': referrals,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'visitorsCount': visitorsCount,
      'isAdmin': isAdmin,
      'isRegionalAdmin': isRegionalAdmin,
      'region': region,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawFrame = (json['frame'] ?? json['frameId'] ?? json['frame_id'])?.toString();
    final rawCover = (json['coverUrl'] ?? json['cover_url'])?.toString();

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'Não informado',
      age: int.tryParse(json['age']?.toString() ?? ''),
      wealthLevel: json['wealthLevel']?.toString(),
      charmLevel:
          int.tryParse(json['charmLevel']?.toString() ?? '') ??
          int.tryParse(json['points']?.toString() ?? '') ??
          0,
      interestedIn: json['interestedIn']?.toString() ?? 'Todos',
      photoUrl: json['photoUrl']?.toString(),
      coverUrl: rawCover,
      bio: json['bio']?.toString() ?? '',
      gallery: (json['gallery'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      coins: (json['coins'] as num?)?.toDouble() ??
          (json['balance'] as num?)?.toDouble() ??
          0.0,
      diamonds: (json['diamonds'] as num?)?.toDouble() ?? 0.0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      levelTitle: json['levelTitle']?.toString(),
      frame: rawFrame,
      frameId: rawFrame,
      vipTier: json['vipTier']?.toString(),
      vipTag: json['vipTag']?.toString(),
      hostLevel: (json['hostLevel'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      referrals: (json['referrals'] as num?)?.toInt() ?? 0,
      followersCount: int.tryParse(json['followersCount']?.toString() ?? '') ??
          int.tryParse(json['followers']?.toString() ?? '') ??
          0,
      followingCount: int.tryParse(json['followingCount']?.toString() ?? '') ??
          int.tryParse(json['following']?.toString() ?? '') ??
          0,
      visitorsCount: int.tryParse(json['visitorsCount']?.toString() ?? '') ??
          int.tryParse(json['visitors']?.toString() ?? '') ??
          0,
      isAdmin: json['isAdmin'] == true,
      isRegionalAdmin: json['isRegionalAdmin'] == true,
      region: json['region']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null
          ? DateTime.tryParse(json['lastLogin'].toString())
          : null,
    );
  }
}
