import '../../../core/network/api_client.dart';
import '../models/public_tracking.dart';

class TrackingService {
  TrackingService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PublicTracking> getTrackingByCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    final response = await _apiClient.get('/public/tracking/$normalizedCode');

    return PublicTracking.fromJson(response as Map<String, dynamic>);
  }
}
