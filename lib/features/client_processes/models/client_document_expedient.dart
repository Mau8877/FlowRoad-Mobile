import 'client_document_item.dart';

class ClientDocumentExpedient {
  ClientDocumentExpedient({
    required this.processInstanceId,
    required this.processCode,
    required this.diagramId,
    required this.diagramName,
    required this.processStatus,
    required this.items,
  });

  final String processInstanceId;
  final String processCode;
  final String diagramId;
  final String diagramName;
  final String processStatus;
  final List<ClientDocumentItem> items;

  factory ClientDocumentExpedient.fromJson(Map<String, dynamic> json) {
    return ClientDocumentExpedient(
      processInstanceId: json['processInstanceId']?.toString() ?? '',
      processCode: json['processCode']?.toString() ?? '',
      diagramId: json['diagramId']?.toString() ?? '',
      diagramName: json['diagramName']?.toString() ?? 'Tramite',
      processStatus: json['processStatus']?.toString() ?? '',
      items: _readItems(json['items']),
    );
  }

  static List<ClientDocumentItem> _readItems(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value.whereType<Map>().map((item) {
      return ClientDocumentItem.fromJson(
        item.map((key, value) => MapEntry(key.toString(), value)),
      );
    }).toList();
  }
}
