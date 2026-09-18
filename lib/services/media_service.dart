import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:sofia/services/zego_service.dart';

class MediaService extends ChangeNotifier {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final ZegoService _zego = ZegoService();
  CameraController? _cameraController;
  bool _isCameraActive = false;
  bool _isMicActive = false;
  bool _isLiveConnected = false;
  String? _errorMessage;
  String? _roomId;
  void Function(String type, Map<String, dynamic> data)? _rtcEmitter;

  bool get isCameraActive => _isCameraActive;
  bool get isMicActive => _isMicActive;
  bool get isLiveConnected => _isLiveConnected;
  String? get errorMessage => _errorMessage;
  ZegoService get zego => _zego;

  void bindRtcEmitter(void Function(String type, Map<String, dynamic> data) emitter) {
    _rtcEmitter = emitter;
  }

  void handleRemoteSignal(Map<String, dynamic> payload) {
    if (payload['signal'] != null) {
      _isLiveConnected = true;
      notifyListeners();
    }
  }

  Future<bool> requestPermissions() async {
    try {
      _errorMessage = null;
      if (kIsWeb) return true;

      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      if (cameraStatus.isDenied || micStatus.isDenied) {
        _errorMessage = 'Permissões de câmera e microfone são necessárias';
        notifyListeners();
        return false;
      }

      if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
        _errorMessage = 'Habilite as permissões nas configurações do app';
        notifyListeners();
        return false;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao solicitar permissões: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> initializeCamera() async {
    try {
      _errorMessage = null;
      if (kIsWeb) {
        _isCameraActive = true;
        notifyListeners();
        return true;
      }

      final hasPermission = await requestPermissions();
      if (!hasPermission) return false;

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _errorMessage = 'Nenhuma câmera encontrada';
        notifyListeners();
        return false;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      _isCameraActive = true;
      _emitRtc('camera-on', {'active': true});
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao inicializar câmera: $e';
      _isCameraActive = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> startAudioStream() async {
    try {
      _errorMessage = null;
      final hasPermission = await requestPermissions();
      if (!hasPermission) return false;

      _isMicActive = true;
      _emitRtc('mic-on', {'active': true});
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao iniciar microfone: $e';
      _isMicActive = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> stopAudioStream() async {
    _isMicActive = false;
    _emitRtc('mic-off', {'active': false});
    notifyListeners();
  }

  Future<void> stopCamera() async {
    try {
      await _cameraController?.dispose();
      _cameraController = null;
      _isCameraActive = false;
      _emitRtc('camera-off', {'active': false});
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao parar câmera: $e';
      notifyListeners();
    }
  }

  Future<bool> toggleCamera() async {
    if (kIsWeb || _cameraController == null) {
      return await initializeCamera();
    }
    try {
      final cameras = await availableCameras();
      final currentCamera = _cameraController!.description;
      CameraDescription newCamera;
      if (currentCamera.lensDirection == CameraLensDirection.front) {
        newCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
      } else {
        newCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
      }
      await _cameraController!.dispose();
      _cameraController = CameraController(newCamera, ResolutionPreset.medium, enableAudio: false);
      await _cameraController!.initialize();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao trocar câmera: $e';
      notifyListeners();
      return false;
    }
  }

  CameraController? get cameraController => _cameraController;

  Future<bool> joinLiveRoom({required String roomId, required String userId}) async {
    _roomId = roomId;
    final ok = await _zego.fetchRoomToken(userId: userId, roomId: roomId);
    if (!ok) {
      _errorMessage = 'Falha ao obter token ZEGO/RTC';
      notifyListeners();
      return false;
    }
    await initializeCamera();
    await startAudioStream();
    _emitRtc('join', {
      'roomId': roomId,
      'userId': userId,
      'token': _zego.token,
      'appId': _zego.appId,
      'sandbox': _zego.sandbox,
    });
    _isLiveConnected = true;
    notifyListeners();
    return true;
  }

  Future<bool> autoEnableMedia({String? roomId, String? userId}) async {
    if (roomId != null && userId != null) {
      return joinLiveRoom(roomId: roomId, userId: userId);
    }
    final hasPermission = await requestPermissions();
    if (!hasPermission) return false;
    await initializeCamera();
    await startAudioStream();
    return _isCameraActive || _isMicActive;
  }

  Future<void> disposeAll() async {
    _emitRtc('leave', {'roomId': _roomId});
    await stopCamera();
    await stopAudioStream();
    _isLiveConnected = false;
    _roomId = null;
  }

  void _emitRtc(String type, Map<String, dynamic> data) {
    _rtcEmitter?.call(type, {'type': type, ...data});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
