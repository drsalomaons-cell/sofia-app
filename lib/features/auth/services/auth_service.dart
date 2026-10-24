import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sofia/models/user_model.dart';
import 'package:sofia/services/api_client.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _keySession = 'user_session';
  static const String _keyUser = 'user_data';
  static const String _keyToken = 'auth_token';

  Future<UserModel?> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Preencha todos os campos');
    }

    final data = await ApiClient.postRaw('/api/auth/login', {
      'email': email,
      'password': password,
    });
    if (data != null && data['_status'] == 403) {
      throw Exception(
        'Acesso admin somente pelo painel web: https://sofia-app-yhzb.onrender.com/admin',
      );
    }
    final status = data?['_status'] as int?;
    if (status != null && status >= 500) {
      throw Exception(
        'O servidor apresentou erro (HTTP $status). Tente novamente mais tarde.',
      );
    }
    if (status != null && status >= 400 && status != 401) {
      throw Exception(
        data?['error']?.toString() ?? 'Falha na autenticação (HTTP $status).',
      );
    }
    if (data != null && data['user'] != null) {
      final user = UserModel.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );
      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        throw Exception('O servidor não retornou token de autenticação.');
      }
      await _saveSession(user, token: token);
      return user;
    }

    await Future.delayed(const Duration(milliseconds: 500));
    throw Exception('E-mail ou senha inválidos');
  }

  Future<UserModel?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String gender,
    required String interestedIn,
    required String region,
  }) async {
    final data = await ApiClient.postRaw('/api/auth/register', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'gender': gender,
      'interestedIn': interestedIn,
      'region': region,
    });
    if (data != null && (data['_status'] as int? ?? 200) >= 400) {
      throw Exception(
        data['error']?.toString() ?? 'O servidor recusou o cadastro.',
      );
    }
    if (data != null && data['user'] != null) {
      final user = UserModel.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );
      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        throw Exception('O servidor não retornou token de autenticação.');
      }
      await _saveSession(user, token: token);
      return user;
    }
    throw Exception('Erro ao criar conta');
  }

  Future<UserModel?> restoreSession() async {
    final userJson = await _storage.read(key: _keyUser);
    if (userJson != null) {
      try {
        return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {}
    }
    final userId = await _storage.read(key: _keySession);
    if (userId == null) return null;
    final data = await ApiClient.get('/api/auth/me/$userId');
    if (data != null && data['user'] != null) {
      final user = UserModel.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );
      await _saveSession(user);
      return user;
    }
    return null;
  }

  Future<void> _saveSession(UserModel user, {String? token}) async {
    await _storage.write(key: _keySession, value: user.id);
    if (token != null && token.isNotEmpty) {
      await _storage.write(key: _keyToken, value: token);
    }
    await _storage.write(key: _keyUser, value: jsonEncode(user.toJson()));
  }

  Future<void> logout() async {
    await _storage.delete(key: _keySession);
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUser);
  }

  Future<bool> isLoggedIn() async {
    final userId = await _storage.read(key: _keySession);
    return userId != null;
  }

  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  /// Atualiza o perfil completo no servidor e no cache local.
  Future<UserModel?> updateProfile(UserModel user) async {
    try {
      final res = await ApiClient.put('/api/users/profile', {
        'userId': user.id,
        'name': user.name,
        'bio': user.bio,
        'gender': user.gender,
        'age': user.age,
        'interestedIn': user.interestedIn,
        'coverUrl': user.coverUrl,
        'photoUrl': user.photoUrl,
        'frameId': user.effectiveFrameId,
      });
      if (res != null && res['user'] != null) {
        final serverUser = UserModel.fromJson(
          Map<String, dynamic>.from(res['user'] as Map),
        );
        await _saveSession(serverUser);
        return serverUser;
      }
    } catch (_) {}
    await _saveSession(user);
    return user;
  }

  /// Envia foto de perfil ao backend e salva permanentemente.
  Future<UserModel?> uploadAvatar(UserModel currentUser, File file) async {
    final bytes = await file.readAsBytes();
    final ext = file.path.split('.').last.toLowerCase();
    final mime = (ext == 'png') ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
    final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';

    final res = await ApiClient.post('/api/users/avatar', {
      'userId': currentUser.id,
      'image': dataUri,
    });

    if (res != null && res['user'] != null) {
      final updated = UserModel.fromJson(Map<String, dynamic>.from(res['user'] as Map));
      await _saveSession(updated);
      return updated;
    } else if (res != null && res['photoUrl'] != null) {
      final updated = currentUser.copyWith(photoUrl: res['photoUrl'].toString());
      await _saveSession(updated);
      return updated;
    }
    return currentUser;
  }

  /// Envia foto de capa ao backend e salva permanentemente.
  Future<UserModel?> uploadCover(UserModel currentUser, File file) async {
    final bytes = await file.readAsBytes();
    final ext = file.path.split('.').last.toLowerCase();
    final mime = (ext == 'png') ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
    final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';

    final res = await ApiClient.post('/api/users/cover', {
      'userId': currentUser.id,
      'image': dataUri,
    });

    if (res != null && res['user'] != null) {
      final updated = UserModel.fromJson(Map<String, dynamic>.from(res['user'] as Map));
      await _saveSession(updated);
      return updated;
    } else if (res != null && res['coverUrl'] != null) {
      final updated = currentUser.copyWith(coverUrl: res['coverUrl'].toString());
      await _saveSession(updated);
      return updated;
    }
    return currentUser;
  }

  /// Equipa uma nova moldura no servidor.
  Future<UserModel?> equipFrame(UserModel currentUser, String frameId) async {
    final res = await ApiClient.put('/api/users/frame', {
      'userId': currentUser.id,
      'frameId': frameId,
    });

    if (res != null && res['user'] != null) {
      final updated = UserModel.fromJson(Map<String, dynamic>.from(res['user'] as Map));
      await _saveSession(updated);
      return updated;
    } else {
      final updated = currentUser.copyWith(frameId: frameId, frame: frameId);
      await _saveSession(updated);
      return updated;
    }
  }

  /// Envia uma imagem para a galeria do usuário como URL persistente.
  Future<UserModel?> uploadGalleryPhoto(UserModel currentUser, File file) async {
    final bytes = await file.readAsBytes();
    final ext = file.path.split('.').last.toLowerCase();
    final mime = (ext == 'png') ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
    final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';

    final res = await ApiClient.post('/api/users/gallery-upload', {
      'userId': currentUser.id,
      'image': dataUri,
    });

    if (res != null && res['gallery'] is List) {
      final newGallery = (res['gallery'] as List).map((e) => e.toString()).toList();
      final updated = currentUser.copyWith(gallery: newGallery);
      await _saveSession(updated);
      return updated;
    } else if (res != null && res['url'] != null) {
      final newGallery = [...currentUser.gallery, res['url'].toString()];
      final updated = currentUser.copyWith(gallery: newGallery);
      await _saveSession(updated);
      return updated;
    }
    return currentUser;
  }

  /// Remove uma foto da galeria.
  Future<UserModel?> removeGalleryPhoto(UserModel currentUser, String photoUrl) async {
    final updatedList = currentUser.gallery.where((url) => url != photoUrl).toList();
    await ApiClient.put('/api/users/gallery', {
      'userId': currentUser.id,
      'gallery': updatedList,
    });

    final updated = currentUser.copyWith(gallery: updatedList);
    await _saveSession(updated);
    return updated;
  }
}
