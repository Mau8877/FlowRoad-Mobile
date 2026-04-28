import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';

class NotificationService {
  NotificationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> requestAndGetDeviceToken() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    return _messaging.getToken();
  }

  Future<void> subscribeToTracking({required String trackingCode}) async {
    final deviceToken = await requestAndGetDeviceToken();

    if (deviceToken == null || deviceToken.isEmpty) {
      throw Exception('No se pudo obtener el token del dispositivo.');
    }

    await _apiClient.post(
      '/mobile/notifications/subscribe',
      withAuth: true,
      body: {
        'trackingCode': trackingCode.trim().toUpperCase(),
        'deviceToken': deviceToken,
        'platform': AppConfig.platform,
      },
    );
  }
}
