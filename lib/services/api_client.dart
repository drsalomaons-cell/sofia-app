import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static String get baseUrl {
    if (kDebugMode) {
      final local = dotenv.env['API_URL_LOCAL'];
      if (local != null && local.isNotEmpty) {
        return local.replaceAll(RegExp(r'/+$'), '');
      }
      return 'http://192.168.0.248:3000';
    }
    final fromEnv = dotenv.env['API_URL'];
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return fromEnv.replaceAll(RegExp(r'/+$'), '');
    }
    return 'http://192.168.0.248:3000';
  }

  static String get clientToken => dotenv.env['SOFIA_CLIENT_TOKEN'] ?? 'sofia-app-v1';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Sofia-Client': clientToken,
      };

  static Future<Map<String, dynamic>?> get(String path) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers).timeout(const Duration(seconds: 8));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> postRaw(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        return {...data, '_status': res.statusCode};
      }
    } catch (_) {}
    return null;
  }
}
