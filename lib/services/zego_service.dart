import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sofia/services/api_client.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

/// Adaptador de mídia ZEGO. Sinais Socket.IO não são usados como transporte de áudio.
class ZegoService {
  String? _token;
  int? _appId;
  bool _sandbox = true;
  String? _roomId;
  String? _streamId;
  bool _joined = false;
  bool _microphoneMuted = true;
  static bool _engineCreated = false;

  String? get token => _token;
  int? get appId => _appId;
  bool get sandbox => _sandbox;
  bool get isConfigured =>
      _appId != null && _appId! > 0 && _token != null && !_sandbox;
  bool get isJoined => _joined;
  bool get isMicrophoneMuted => _microphoneMuted;

  Future<bool> fetchRoomToken({
    required String userId,
    required String roomId,
  }) async {
    final data = await ApiClient.get(
      '/api/rtc/zego-token?userId=$userId&roomId=$roomId',
    );
    if (data == null) return false;
    _token = data['token']?.toString();
    _appId = data['appId'] is int
        ? data['appId'] as int
        : int.tryParse('${data['appId']}');
    _sandbox = data['sandbox'] == true || (_appId ?? 0) == 0;
    return _token != null;
  }

  Future<bool> joinAudioRoom({
    required String userId,
    required String userName,
    required String roomId,
  }) async {
    if (!isConfigured || _token == null || _appId == null) {
      debugPrint(
        '[SOFIA RTC] ZEGO sem configuração ativa; áudio remoto não será simulado.',
      );
      return false;
    }
    try {
      if (!_engineCreated) {
        await ZegoExpressEngine.createEngineWithProfile(
          ZegoEngineProfile(_appId!, ZegoScenario.Default),
        );
        _engineCreated = true;
      }

      _roomId = roomId;
      ZegoExpressEngine.onRoomStreamUpdate =
          (updatedRoomId, updateType, streams, extendedData) {
            if (updatedRoomId != _roomId) return;
            for (final stream in streams) {
              if (updateType == ZegoUpdateType.Add) {
                ZegoExpressEngine.instance.startPlayingStream(stream.streamID);
              } else {
                ZegoExpressEngine.instance.stopPlayingStream(stream.streamID);
              }
            }
          };

      final config = ZegoRoomConfig.defaultConfig()..token = _token!;
      final result = await ZegoExpressEngine.instance.loginRoom(
        roomId,
        ZegoUser(userId, userName),
        config: config,
      );
      if (result.errorCode != 0) {
        debugPrint(
          '[SOFIA RTC] Falha ao entrar na sala ZEGO: ${result.errorCode}',
        );
        _roomId = null;
        return false;
      }
      _joined = true;
      // Esta sessão é exclusivamente de áudio; nenhuma câmera é ativada.
      await ZegoExpressEngine.instance.enableCamera(false);
      return true;
    } catch (e) {
      debugPrint('[SOFIA RTC] Erro ao conectar áudio ZEGO: $e');
      _joined = false;
      _roomId = null;
      return false;
    }
  }

  Future<bool> publishAudio({required String userId}) async {
    if (!_joined || _roomId == null) return false;
    try {
      if (_streamId == null) {
        await ZegoExpressEngine.instance.enableCamera(false);
        _streamId = '${_roomId}_${userId}_audio';
        await ZegoExpressEngine.instance.startPublishingStream(_streamId!);
      }
      await setMicrophoneMuted(false);
      return true;
    } catch (e) {
      debugPrint('[SOFIA RTC] Falha ao publicar áudio: $e');
      return false;
    }
  }

  /// Ativa/desativa o microfone real no motor ZEGO sem destruir a sessão.
  Future<void> setMicrophoneMuted(bool muted) async {
    if (!_joined) throw StateError('A sala ZEGO não está conectada.');
    await ZegoExpressEngine.instance.muteMicrophone(muted);
    _microphoneMuted = muted;
  }

  Future<void> stopAudio() async {
    if (_streamId == null) return;
    try {
      await ZegoExpressEngine.instance.stopPublishingStream();
    } catch (e) {
      debugPrint('[SOFIA RTC] Falha ao parar áudio: $e');
    }
    _streamId = null;
  }

  /// Silencia apenas o áudio recebido neste aparelho, sem desligar a live.
  Future<void> muteRemoteAudio(bool muted) async {
    if (!_joined) return;
    await ZegoExpressEngine.instance.muteAllPlayStreamAudio(muted);
  }

  Future<void> leaveAudioRoom() async {
    await stopAudio();
    if (_joined && _roomId != null) {
      try {
        await ZegoExpressEngine.instance.logoutRoom(_roomId!);
      } catch (e) {
        debugPrint('[SOFIA RTC] Falha ao sair da sala ZEGO: $e');
      }
    }
    _joined = false;
    _roomId = null;
    ZegoExpressEngine.onRoomStreamUpdate = null;
  }

  int get zegoAppIdFromEnv {
    final id = dotenv.env['ZEGO_APP_ID'];
    return int.tryParse(id ?? '') ?? 0;
  }
}
