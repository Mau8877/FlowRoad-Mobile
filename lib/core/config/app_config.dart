class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080/api/v1',
    //defaultValue: 'http://192.168.0.127:8080/api/v1',
    // defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  static const String platform = 'ANDROID';
}
