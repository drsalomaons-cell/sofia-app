import 'package:flutter/foundation.dart';
import 'package:sofia/models/room_model.dart';
import 'package:sofia/services/room_service.dart';

class RoomProvider extends ChangeNotifier {
  final RoomService _roomService = RoomService();
  
  List<RoomModel> _rooms = [];
  RoomModel? _currentRoom;
  bool _isLoading = false;
  String? _errorMessage;

  List<RoomModel> get rooms => _rooms;
  RoomModel? get currentRoom => _currentRoom;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  RoomProvider() {
    loadActiveRooms();
  }

  Future<void> loadActiveRooms() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rooms = await _roomService.getActiveRooms();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao carregar salas: $e';
      notifyListeners();
    }
  }

  Future<void> loadRoomById(String roomId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentRoom = await _roomService.getRoomById(roomId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao carregar sala: $e';
      notifyListeners();
    }
  }

  Future<bool> createRoom({
    required String name,
    required String description,
    required String theme,
    required int chairs,
    required String hostId,
    required String hostName,
    bool isPrivate = false,
    bool allowGuests = true,
    String? region,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newRoom = await _roomService.createRoom(
        name: name,
        description: description,
        theme: theme,
        chairs: chairs,
        hostId: hostId,
        hostName: hostName,
        isPrivate: isPrivate,
        allowGuests: allowGuests,
        region: region,
      );

      _rooms.insert(0, newRoom);
      _currentRoom = newRoom;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao criar sala: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> joinRoom(String roomId, String userId, {String? userName}) async {
    try {
      final room = await _roomService.joinRoom(roomId, userId, userName ?? 'Usuário');
      if (room != null) {
        _currentRoom = room;
        final listIdx = _rooms.indexWhere((r) => r.id == roomId);
        if (listIdx >= 0) _rooms[listIdx] = room;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Erro ao entrar na sala: $e';
      notifyListeners();
    }
  }

  Future<void> leaveRoom(String roomId, String userId) async {
    try {
      await _roomService.leaveRoom(roomId, userId);
      
      // Atualizar sala atual
      if (_currentRoom != null && _currentRoom!.id == roomId) {
        _currentRoom = _currentRoom!.copyWith(
          currentUsers: _currentRoom!.currentUsers - 1,
          participants: _currentRoom!.participants.where((id) => id != userId).toList(),
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Erro ao sair da sala: $e';
      notifyListeners();
    }
  }

  Future<void> banUser(String roomId, String userId, String bannedBy) async {
    try {
      await _roomService.banUser(roomId, userId, bannedBy);
      
      // Atualizar sala atual
      if (_currentRoom != null && _currentRoom!.id == roomId) {
        _currentRoom = _currentRoom!.copyWith(
          bannedUsers: [..._currentRoom!.bannedUsers, userId],
          participants: _currentRoom!.participants.where((id) => id != userId).toList(),
          currentUsers: _currentRoom!.currentUsers - 1,
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Erro ao banir usuário: $e';
      notifyListeners();
    }
  }

  Future<void> unbanUser(String roomId, String userId) async {
    try {
      await _roomService.unbanUser(roomId, userId);
      
      // Atualizar sala atual
      if (_currentRoom != null && _currentRoom!.id == roomId) {
        _currentRoom = _currentRoom!.copyWith(
          bannedUsers: _currentRoom!.bannedUsers.where((id) => id != userId).toList(),
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Erro ao desbanir usuário: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}