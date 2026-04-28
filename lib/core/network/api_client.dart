import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri buildUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${AppConfig.apiBaseUrl}$normalizedPath');
  }

  Future<Map<String, String>> _headers({bool withAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String path, {bool withAuth = false}) async {
    final response = await _client.get(
      buildUri(path),
      headers: await _headers(withAuth: withAuth),
    );

    return _handleResponse(response);
  }

  Future<dynamic> post(
    String path, {
    required Map<String, dynamic> body,
    bool withAuth = false,
  }) async {
    final response = await _client.post(
      buildUri(path),
      headers: await _headers(withAuth: withAuth),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    final rawBody = response.body;

    dynamic decoded;

    try {
      decoded = rawBody.isNotEmpty ? jsonDecode(rawBody) : null;
    } catch (_) {
      decoded = rawBody;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    String message = 'Ocurrió un error inesperado';

    if (decoded is Map<String, dynamic>) {
      message =
          decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          decoded['detail']?.toString() ??
          message;
    } else if (decoded is String && decoded.isNotEmpty) {
      message = decoded;
    }

    throw ApiException(statusCode: response.statusCode, message: message);
  }
}

class ApiException implements Exception {
  ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}
