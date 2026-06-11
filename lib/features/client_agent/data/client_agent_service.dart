import '../../../core/network/api_client.dart';
import '../models/client_agent_chat.dart';

class ClientAgentService {
  ClientAgentService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ClientAgentChatResponse> sendMessage({
    String? chatId,
    required String message,
  }) async {
    final request = ClientAgentChatRequest(chatId: chatId, message: message);
    final response = await _apiClient.post(
      '/client/agent/chat',
      body: request.toJson(),
      withAuth: true,
    );

    return ClientAgentChatResponse.fromJson(response as Map<String, dynamic>);
  }
}
