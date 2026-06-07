import 'dart:convert';
import 'dart:typed_data';

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

  Future<dynamic> put(
    String path, {
    required Map<String, dynamic> body,
    bool withAuth = false,
  }) async {
    final response = await _client.put(
      buildUri(path),
      headers: await _headers(withAuth: withAuth),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  Future<dynamic> multipartPost(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    bool withAuth = true,
  }) async {
    final request = await _buildMultipartRequest(
      method: 'POST',
      path: path,
      fields: fields,
      fileField: fileField,
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
      withAuth: withAuth,
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  Future<dynamic> multipartPut(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    bool withAuth = true,
  }) async {
    final request = await _buildMultipartRequest(
      method: 'PUT',
      path: path,
      fields: fields,
      fileField: fileField,
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
      withAuth: withAuth,
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  Future<http.MultipartRequest> _buildMultipartRequest({
    required String method,
    required String path,
    required Map<String, String> fields,
    required String fileField,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required bool withAuth,
  }) async {
    final request = http.MultipartRequest(method, buildUri(path));
    request.headers['Accept'] = 'application/json';

    if (withAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    request.fields.addAll(fields);

    if (filePath != null && filePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
          fileField,
          filePath,
          filename: fileName,
        ),
      );
    } else if (fileBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(fileField, fileBytes, filename: fileName),
      );
    } else {
      throw ApiException(
        statusCode: 0,
        message: 'No se pudo acceder al archivo seleccionado.',
      );
    }

    return request;
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
