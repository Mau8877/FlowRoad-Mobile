import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../models/client_document_download_url.dart';
import '../models/client_document_expedient.dart';
import '../models/client_process_instance.dart';

class ClientProcessService {
  ClientProcessService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ClientProcessInstance>> getClientProcessInstances() async {
    final response = await _apiClient.get(
      '/client/process-instances',
      withAuth: true,
    );

    if (response is! List) {
      return [];
    }

    return response.whereType<Map>().map((item) {
      return ClientProcessInstance.fromJson(
        item.map((key, value) => MapEntry(key.toString(), value)),
      );
    }).toList();
  }

  Future<ClientProcessInstance> getClientProcessInstanceDetail(
    String processInstanceId,
  ) async {
    final response = await _apiClient.get(
      '/client/process-instances/$processInstanceId',
      withAuth: true,
    );

    return ClientProcessInstance.fromJson(response as Map<String, dynamic>);
  }

  Future<ClientDocumentExpedient> getClientDocuments(
    String processInstanceId,
  ) async {
    final response = await _apiClient.get(
      '/client/process-instances/$processInstanceId/documents',
      withAuth: true,
    );

    return ClientDocumentExpedient.fromJson(response as Map<String, dynamic>);
  }

  Future<void> uploadClientDocument({
    required String processInstanceId,
    required String documentRequirementId,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
  }) async {
    await _apiClient.multipartPost(
      '/client/process-instances/$processInstanceId/documents',
      fields: {'documentRequirementId': documentRequirementId},
      fileField: 'file',
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
      withAuth: true,
    );
  }

  Future<void> replaceClientDocument({
    required String processInstanceId,
    required String documentFileId,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
  }) async {
    await _apiClient.multipartPut(
      '/client/process-instances/$processInstanceId/documents/$documentFileId/replace',
      fields: const {},
      fileField: 'file',
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
      withAuth: true,
    );
  }

  Future<ClientDocumentDownloadUrl> getClientDocumentDownloadUrl({
    required String processInstanceId,
    required String documentFileId,
  }) async {
    final response = await _apiClient.get(
      '/client/process-instances/$processInstanceId/documents/$documentFileId/download-url',
      withAuth: true,
    );

    return ClientDocumentDownloadUrl.fromJson(response as Map<String, dynamic>);
  }
}
