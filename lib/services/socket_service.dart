import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:sofia/services/api_client.dart';

class SocketService extends ChangeNotifier {
  io.Socket? _socket;
  bool _connected = false;
  String? _roomId;

  bool get connected => _connected;
  String? get roomId => _roomId;

  static String get _socketUrl {
    if (kDebugMode) {
      return dotenv.env['SOCKET_URL_LOCAL'] ?? dotenv.env['API_URL_LOCAL'] ?? ApiClient.baseUrl;
    }
    final fromEnv = dotenv.env['SOCKET_URL'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv.replaceAll(RegExp(r'/+$'), '');
    return ApiClient.baseUrl;
  }
  void connect() {
    if (_socket != null) return;
    _socket = io.io(
      _socketUrl,
      io.OptionBuilder().setTransports(['websocket']).enableAutoConnect().build(),
    );    _socket!.onConnect((_) {
      _connected = true;
      notifyListeners();
    });
    _socket!.onDisconnect((_) {
      _connected = false;
      notifyListeners();
    });
  }

  void joinRoom(String roomId, String userId, String userName) {
    connect();
    _roomId = roomId;
    _socket?.emit('room:join', {'roomId': roomId, 'userId': userId, 'userName': userName});
  }

  void leaveRoom(String roomId, String userId) {
    _socket?.emit('room:leave', {'roomId': roomId, 'userId': userId});
    _roomId = null;
  }

  void sendChat(String roomId, Map<String, dynamic> message) {
    _socket?.emit('room:chat', {'roomId': roomId, 'message': message});
  }

  void emitGift(String roomId, Map<String, dynamic> gift) {
    _socket?.emit('room:gift', {'roomId': roomId, ...gift});
  }

  void emitMicToggle(String roomId, String userId, bool active) {
    _socket?.emit('room:mic_toggle', {'roomId': roomId, 'userId': userId, 'active': active});
  }

  void onChat(void Function(Map<String, dynamic>) handler) {
    _socket?.on('room:chat', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data['message'] ?? data));
    });
  }

  void onGift(void Function(Map<String, dynamic>) handler) {
    _socket?.on('room:gift', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void onRoomState(void Function(Map<String, dynamic>) handler) {
    _socket?.on('room:state', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void onUserJoined(void Function(Map<String, dynamic>) handler) {
    _socket?.on('room:user_joined', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void onMicToggle(void Function(Map<String, dynamic>) handler) {
    _socket?.on('room:mic_toggle', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void emitRtcSignal(String roomId, Map<String, dynamic> signal, {String? targetUserId}) {
    _socket?.emit('rtc:signal', {
      'roomId': roomId,
      'targetUserId': targetUserId,
      'signal': signal,
    });
  }

  void onRtcSignal(void Function(Map<String, dynamic>) handler) {
    _socket?.on('rtc:signal', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void disconnect() {    _socket?.dispose();
    _socket = null;
    _connected = false;
    _roomId = null;
    notifyListeners();
  }
}
