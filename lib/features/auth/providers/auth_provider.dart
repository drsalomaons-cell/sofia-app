import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sofia/models/user_model.dart';
import 'package:sofia/features/auth/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    restoreSession();
  }

  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.restoreSession();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.login(email, password);
      _isLoading = false;
      
      if (_user != null) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'E-mail ou senha inválidos';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao fazer login: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String gender,
    required String interestedIn,
    required String region,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        gender: gender,
        interestedIn: interestedIn,
        region: region,
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao criar conta: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao fazer logout: $e';
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.updateProfile(updatedUser);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao atualizar perfil: $e';
      notifyListeners();
    }
  }

  /// Faz upload da foto de perfil ao backend e atualiza o estado imediatamente.
  Future<bool> uploadAvatar(File imageFile) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.uploadAvatar(_user!, imageFile);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Falha ao salvar foto de perfil: $e';
      notifyListeners();
      return false;
    }
  }

  /// Faz upload da foto de capa ao backend e atualiza o estado imediatamente.
  Future<bool> uploadCover(File imageFile) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.uploadCover(_user!, imageFile);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Falha ao salvar capa: $e';
      notifyListeners();
      return false;
    }
  }

  /// Equipa uma nova moldura no servidor e atualiza o estado.
  Future<bool> equipFrame(String frameId) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.equipFrame(_user!, frameId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Falha ao equipar moldura: $e';
      notifyListeners();
      return false;
    }
  }

  /// Adiciona uma foto à galeria salvando como URL no backend.
  Future<bool> uploadGalleryPhoto(File imageFile) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.uploadGalleryPhoto(_user!, imageFile);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Falha ao adicionar à galeria: $e';
      notifyListeners();
      return false;
    }
  }

  /// Remove uma foto da galeria no backend.
  Future<bool> removeGalleryPhoto(String photoUrl) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.removeGalleryPhoto(_user!, photoUrl);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Falha ao remover foto: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  bool isAdmin() {
    return _user?.isAdmin ?? false;
  }

  bool isRegionalAdmin() {
    return _user?.isRegionalAdmin ?? false;
  }

  String? getRegion() {
    return _user?.region;
  }
}
