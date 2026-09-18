import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sofia/services/api_client.dart';

class ZegoService {
  String? _token;
  int? _appId;
  bool _sandbox = true;

  String? get token => _token;
  int? get appId => _appId;
  bool get sandbox => _sandbox;
  bool get isConfigured => _appId != null && _appId! > 0 && _token != null;

  Future<bool> fetchRoomToken({required String userId, required String roomId}) async {
    final data = await ApiClient.get('/api/rtc/zego-token?userId=$userId&roomId=$roomId');
    if (data == null) return false;
    _token = data['token']?.toString();
    _appId = data['appId'] is int ? data['appId'] as int : int.tryParse('${data['appId']}');
    _sandbox = data['sandbox'] == true || (_appId ?? 0) == 0;
    return _token != null;
  }

  int get zegoAppIdFromEnv {
    final id = dotenv.env['ZEGO_APP_ID'];
    return int.tryParse(id ?? '') ?? 0;
  }
}
