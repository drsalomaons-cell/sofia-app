import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;

class FaceRecognitionService extends ChangeNotifier {
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  factory FaceRecognitionService() => _instance;
  FaceRecognitionService._internal();

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
      minFaceSize: 0.15,
    ),
  );

  bool _isScanning = false;
  String? _errorMessage;
  Map<String, dynamic>? _lastFaceData;

  bool get isScanning => _isScanning;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get lastFaceData => _lastFaceData;

  /// Verifica se há rosto na imagem
  Future<Map<String, dynamic>?> detectFace(CameraImage image) async {
    try {
      _errorMessage = null;
      
      // Converter CameraImage para InputImage
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _errorMessage = 'Erro ao processar imagem';
        notifyListeners();
        return null;
      }

      // Detectar rostos
      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) {
        _errorMessage = 'Nenhum rosto detectado';
        notifyListeners();
        return null;
      }

      // Pegar o primeiro rosto
      final face = faces.first;
      
      // Extrair dados do rosto
      final faceData = {
        'boundingBox': {
          'left': face.boundingBox.left,
          'top': face.boundingBox.top,
          'right': face.boundingBox.right,
          'bottom': face.boundingBox.bottom,
        },
        'hasSmiling': face.smilingProbability != null && face.smilingProbability! > 0.5,
        'hasLeftEye': face.leftEyeOpenProbability != null && face.leftEyeOpenProbability! > 0.5,
        'hasRightEye': face.rightEyeOpenProbability != null && face.rightEyeOpenProbability! > 0.5,
        'confidence': face.trackingId ?? 0,
      };

      _lastFaceData = faceData;
      notifyListeners();
      
      return faceData;
    } catch (e) {
      _errorMessage = 'Erro na detecção facial: $e';
      notifyListeners();
      return null;
    }
  }

  /// Verifica se o rosto é válido para cadastro
  Future<bool> validateFaceForRegistration(CameraImage image) async {
    try {
      _isScanning = true;
      notifyListeners();

      final faceData = await detectFace(image);
      
      if (faceData == null) {
        return false;
      }

      // Verificações de qualidade
      final hasEyes = faceData['hasLeftEye'] && faceData['hasRightEye'];
      final hasGoodSize = _isFaceSizeValid(faceData['boundingBox']);
      
      if (!hasEyes) {
        _errorMessage = 'Mantenha os olhos abertos e visíveis';
        notifyListeners();
        return false;
      }

      if (!hasGoodSize) {
        _errorMessage = 'Aproxime o rosto da câmera';
        notifyListeners();
        return false;
      }

      _isScanning = false;
      _errorMessage = null;
      notifyListeners();
      
      return true;
    } catch (e) {
      _errorMessage = 'Erro na validação: $e';
      _isScanning = false;
      notifyListeners();
      return false;
    }
  }

  /// Verifica identidade (modo teste - comparação simples)
  Future<bool> verifyIdentity(String userId, CameraImage image) async {
    try {
      _isScanning = true;
      notifyListeners();

      // Em modo de teste, apenas verifica se há um rosto válido
      final faceData = await detectFace(image);
      
      if (faceData == null) {
        return false;
      }

      // Aqui seria implementada a comparação com face salva
      // No modo teste, apenas retorna true se detectar rosto
      
      _isScanning = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _errorMessage = 'Erro na verificação: $e';
      _isScanning = false;
      notifyListeners();
      return false;
    }
  }

  /// Verifica se o tamanho do rosto é adequado
  bool _isFaceSizeValid(Map<String, dynamic> boundingBox) {
    final width = boundingBox['right'] - boundingBox['left'];
    final height = boundingBox['bottom'] - boundingBox['top'];
    
    // Verificar se o rosto ocupa pelo menos 20% da imagem
    // (valores aproximados para imagem de 640x480)
    return width > 80 && height > 80;
  }

  /// Converte CameraImage para InputImage (formato ML Kit)
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      
      final bytes = allBytes.done().buffer.asUint8List();
      
      final ui.Size imageSize = ui.Size(image.width.toDouble(), image.height.toDouble());
      
      final camera = image.planes.first;
      final plane = camera;
      
      // Rotação da imagem (ajustar conforme necessidade)
      const rotation = InputImageRotation.rotation0deg;
      
      // Formato de cor
      const format = InputImageFormat.nv21;
      
      // Converter para InputImage
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );

      return inputImage;
    } catch (e) {
      _errorMessage = 'Erro ao converter imagem: $e';
      return null;
    }
  }

  /// Limpa dados
  void clearData() {
    _lastFaceData = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }
}