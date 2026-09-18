import 'package:sofia/models/seat_model.dart';

class RoomModel {
  final String id;
  final String name;
  final String description;
  final String theme;
  final String coverUrl;
  final int chairs;
  final int currentUsers;
  final bool isPrivate;
  final bool allowGuests;
  final String hostId;
  final String hostName;
  final List<String> participants;
  final List<String> bannedUsers;
  final List<SeatModel> seats;
  final double earnings;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? endedAt;

  RoomModel({
    required this.id,
    required this.name,
    required this.description,
    required this.theme,
    this.coverUrl = '',
    required this.chairs,
    this.currentUsers = 0,
    this.isPrivate = false,
    this.allowGuests = true,
    required this.hostId,
    required this.hostName,
    this.participants = const [],
    this.bannedUsers = const [],
    this.seats = const [],
    this.earnings = 0.0,
    this.isActive = true,
    required this.createdAt,
    this.endedAt,
  });

  RoomModel copyWith({
    String? id,
    String? name,
    String? description,
    String? theme,
    String? coverUrl,
    int? chairs,
    int? currentUsers,
    bool? isPrivate,
    bool? allowGuests,
    String? hostId,
    String? hostName,
    List<String>? participants,
    List<String>? bannedUsers,
    List<SeatModel>? seats,
    double? earnings,
    bool? isActive,
    DateTime? createdAt,
    DateTime? endedAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      theme: theme ?? this.theme,
      coverUrl: coverUrl ?? this.coverUrl,
      chairs: chairs ?? this.chairs,
      currentUsers: currentUsers ?? this.currentUsers,
      isPrivate: isPrivate ?? this.isPrivate,
      allowGuests: allowGuests ?? this.allowGuests,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      participants: participants ?? this.participants,
      bannedUsers: bannedUsers ?? this.bannedUsers,
      seats: seats ?? this.seats,
      earnings: earnings ?? this.earnings,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'theme': theme,
      'coverUrl': coverUrl,
      'chairs': chairs,
      'currentUsers': currentUsers,
      'isPrivate': isPrivate,
      'allowGuests': allowGuests,
      'hostId': hostId,
      'hostName': hostName,
      'participants': participants,
      'bannedUsers': bannedUsers,
      'seats': seats.map((s) => {
            'index': s.index,
            'userId': s.userId,
            'userName': s.userName,
            'role': s.role,
            'isMuted': s.isMuted,
            'isLocked': s.isLocked,
            'giftCount': s.giftCount,
          }).toList(),
      'earnings': earnings,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
    };
  }

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      theme: json['theme'],
      coverUrl: json['coverUrl'] ?? '',
      chairs: json['chairs'],
      currentUsers: json['currentUsers'] ?? 0,
      isPrivate: json['isPrivate'] ?? false,
      allowGuests: json['allowGuests'] ?? true,
      hostId: json['hostId'],
      hostName: json['hostName'],
      participants: List<String>.from(json['participants'] ?? []),
      bannedUsers: List<String>.from(json['bannedUsers'] ?? []),
      seats: (json['seats'] as List?)
              ?.map((s) => SeatModel.fromJson(Map<String, dynamic>.from(s as Map)))
              .toList() ??
          [],
      earnings: json['earnings']?.toDouble() ?? 0.0,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
    );
  }
}