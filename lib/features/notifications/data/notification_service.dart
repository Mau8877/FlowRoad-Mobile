import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';

class NotificationService {
  NotificationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<String?> requestAndGetDeviceToken() async {
    if (kIsWeb) {
      debugPrint('Firebase Messaging web notifications are disabled.');
      return null;
    }

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    return messaging.getToken();
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
