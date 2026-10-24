class SeatModel {
  final int index;
  final String? userId;
  final String? userName;
  final String? photoUrl;
  final int level;
  final String role;
  final bool isMuted;
  final bool isLocked;
  final int giftCount;

  const SeatModel({
    required this.index,
    this.userId,
    this.userName,
    this.photoUrl,
    this.level = 1,
    this.role = 'participant',
    this.isMuted = false,
    this.isLocked = false,
    this.giftCount = 0,
  });

  bool get isOccupied => userId != null;
  bool get isOwner => role == 'owner';

  SeatModel copyWith({
    String? userId,
    String? userName,
    String? photoUrl,
    int? level,
    String? role,
    bool? isMuted,
    bool? isLocked,
    int? giftCount,
    bool clearUser = false,
  }) {
    return SeatModel(
      index: index,
      userId: clearUser ? null : (userId ?? this.userId),
      userName: clearUser ? null : (userName ?? this.userName),
      photoUrl: clearUser ? null : (photoUrl ?? this.photoUrl),
      level: clearUser ? 1 : (level ?? this.level),
      role: clearUser ? 'participant' : (role ?? this.role),
      isMuted: clearUser ? false : (isMuted ?? this.isMuted),
      isLocked: isLocked ?? this.isLocked,
      giftCount: clearUser ? 0 : (giftCount ?? this.giftCount),
    );
  }

  factory SeatModel.fromJson(Map<String, dynamic> json) {
    return SeatModel(
      index: json['index'] as int? ?? 0,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      photoUrl: json['photoUrl']?.toString(),
      level: (json['level'] as num?)?.toInt() ?? 1,
      role: json['role'] as String? ?? 'participant',
      isMuted: json['isMuted'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
      giftCount: (json['giftCount'] as num?)?.toInt() ?? 0,
    );
  }
}
