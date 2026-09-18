import 'package:sofia/models/room_model.dart';
import 'package:sofia/models/seat_model.dart';
import 'package:sofia/services/api_client.dart';

class RoomService {
  Future<List<RoomModel>> getActiveRooms({String? region}) async {
    final path = region != null ? '/api/rooms?region=$region' : '/api/rooms';
    final data = await ApiClient.get(path);
    if (data != null && data['rooms'] is List) {
      return (data['rooms'] as List)
          .map((r) => RoomModel.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    }
    return _fallbackRooms();
  }

  Future<RoomModel?> getRoomById(String roomId) async {
    final data = await ApiClient.get('/api/rooms/$roomId');
    if (data != null && data['room'] != null) {
      return RoomModel.fromJson(Map<String, dynamic>.from(data['room'] as Map));
    }
    return null;
  }

  Future<RoomModel> createRoom({
    required String name,
    required String description,
    required String theme,
    required int chairs,
    required String hostId,
    required String hostName,
    bool isPrivate = false,
    bool allowGuests = true,
    String? region,
    String? coverUrl,
  }) async {
    final data = await ApiClient.post('/api/rooms', {
      'name': name,
      'description': description,
      'theme': theme,
      'chairs': chairs,
      'hostId': hostId,
      'hostName': hostName,
      'isPrivate': isPrivate,
      'allowGuests': allowGuests,
      'region': region,
      'coverUrl': coverUrl,
    });
    if (data != null && data['room'] != null) {
      return RoomModel.fromJson(Map<String, dynamic>.from(data['room'] as Map));
    }
    throw Exception('Erro ao criar sala');
  }

  Future<RoomModel?> joinRoom(String roomId, String userId, String userName) async {
    final data = await ApiClient.post('/api/rooms/$roomId/join', {
      'userId': userId,
      'userName': userName,
    });
    if (data != null && data['room'] != null) {
      return RoomModel.fromJson(Map<String, dynamic>.from(data['room'] as Map));
    }
    return null;
  }

  Future<RoomModel?> leaveRoom(String roomId, String userId) async {
    final data = await ApiClient.post('/api/rooms/$roomId/leave', {'userId': userId});
    if (data != null && data['room'] != null) {
      return RoomModel.fromJson(Map<String, dynamic>.from(data['room'] as Map));
    }
    return null;
  }

  Future<RoomModel?> takeSeat(String roomId, int seatIndex, String userId, String userName) async {
    final data = await ApiClient.post('/api/rooms/$roomId/seats/$seatIndex/take', {
      'userId': userId,
      'userName': userName,
    });
    if (data != null && data['room'] != null) {
      return RoomModel.fromJson(Map<String, dynamic>.from(data['room'] as Map));
    }
    return null;
  }

  Future<void> muteSeat(String roomId, int seatIndex, String actorId, bool muted) async {
    await ApiClient.post('/api/rooms/$roomId/seats/$seatIndex/mute', {
      'actorId': actorId,
      'muted': muted,
    });
  }

  Future<RoomModel?> lockSeat(String roomId, int seatIndex, String actorId, bool locked) async {
    final data = await ApiClient.post('/api/rooms/$roomId/seats/$seatIndex/lock', {
      'actorId': actorId,
      'locked': locked,
    });
    if (data != null && data['room'] != null) {
      return RoomModel.fromJson(Map<String, dynamic>.from(data['room'] as Map));
    }
    return null;
  }

  Future<void> banUser(String roomId, String targetUserId, String actorId) async {
    await ApiClient.post('/api/rooms/$roomId/ban', {
      'targetUserId': targetUserId,
      'actorId': actorId,
    });
  }

  List<SeatModel> parseSeats(RoomModel room) {
    // seats come from API in room JSON - extend RoomModel if needed
    return List.generate(room.chairs, (i) {
      final occupied = i < room.participants.length;
      return SeatModel(
        index: i,
        userId: occupied ? room.participants[i] : null,
        userName: i == 0 ? room.hostName : (occupied ? 'Participante' : null),
        role: i == 0 ? 'owner' : 'participant',
      );
    });
  }

  Future<void> unbanUser(String roomId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  List<RoomModel> _fallbackRooms() {
    return [
      RoomModel(
        id: 'room-1',
        name: 'Festa na Praia',
        description: 'Venha curtir!',
        theme: 'Festa',
        chairs: 12,
        currentUsers: 3,
        hostId: 'user-demo',
        hostName: 'Demo',
        participants: ['user-demo'],
        createdAt: DateTime.now(),
      ),
    ];
  }
}
