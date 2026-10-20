import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static String get baseUrl {
    if (kDebugMode) {
      final local = dotenv.env['API_URL_LOCAL'];
      if (local != null && local.isNotEmpty) {
        return local.replaceAll(RegExp(r'/+$'), '');
      }
      return 'https://sofia-app-yhzb.onrender.com';
    }
    final fromEnv = dotenv.env['API_URL'];
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return fromEnv.replaceAll(RegExp(r'/+$'), '');
    }
    return 'https://sofia-app-yhzb.onrender.com';
  }

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static String get clientToken =>
      dotenv.env['SOFIA_CLIENT_TOKEN'] ?? 'sofia-app-v1';

  static Future<Map<String, String>> get _headers async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-Sofia-Client': clientToken,
    };
    final token = await _secureStorage.read(key: 'auth_token');
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>?> get(String path) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl$path'), headers: await _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: await _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> postRaw(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: await _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        return {...data, '_status': res.statusCode};
      }
      throw Exception('Resposta inesperada do servidor. Tente novamente.');
    } catch (_) {
      throw Exception(
        'Falha de comunicação com o servidor. Verifique sua conexão e tente novamente.',
      );
    }
  }
  static Future<Map<String, dynamic>?> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl$path'),
            headers: await _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        return {...data, '_status': res.statusCode};
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
