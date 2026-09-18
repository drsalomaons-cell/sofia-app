class SeatModel {
  final int index;
  final String? userId;
  final String? userName;
  final String role;
  final bool isMuted;
  final bool isLocked;
  final int giftCount;

  const SeatModel({
    required this.index,
    this.userId,
    this.userName,
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
      role: role ?? this.role,
      isMuted: isMuted ?? this.isMuted,
      isLocked: isLocked ?? this.isLocked,
      giftCount: giftCount ?? this.giftCount,
    );
  }

  factory SeatModel.fromJson(Map<String, dynamic> json) {
    return SeatModel(
      index: json['index'] as int,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      role: json['role'] as String? ?? 'participant',
      isMuted: json['isMuted'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
      giftCount: json['giftCount'] as int? ?? 0,
    );
  }
}
