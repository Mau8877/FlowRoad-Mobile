import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../models/auth_response.dart';

class AuthService {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
    );

    final authResponse = AuthResponse.fromJson(
      response as Map<String, dynamic>,
    );
    await saveToken(authResponse.token);
    return authResponse;
  }

  Future<AuthResponse> registerClient({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String telefono,
    required String direccion,
  }) async {
    final response = await _apiClient.post(
      '/auth/register-client',
      body: {
        'email': email.trim(),
        'password': password,
        'profile': {
          'nombre': nombre.trim(),
          'apellido': apellido.trim(),
          'telefono': telefono.trim(),
          'direccion': direccion.trim(),
          'avatarUrl': null,
        },
      },
    );

    final authResponse = AuthResponse.fromJson(
      response as Map<String, dynamic>,
    );
    await saveToken(authResponse.token);
    return authResponse;
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
