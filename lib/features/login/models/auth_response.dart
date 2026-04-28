class AuthResponse {
  AuthResponse({required this.token, required this.message});

  final String token;
  final String message;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }
}
