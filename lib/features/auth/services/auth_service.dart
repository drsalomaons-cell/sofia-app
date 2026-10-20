import 'dart:convert';
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

  Future<UserModel?> updateProfile(UserModel user) async {
    await _saveSession(user);
    return user;
  }
}
