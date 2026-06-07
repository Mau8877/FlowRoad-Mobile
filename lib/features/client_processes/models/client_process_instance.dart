class ClientProcessInstance {
  ClientProcessInstance({
    required this.id,
    required this.code,
    required this.diagramId,
    required this.diagramName,
    required this.diagramVersion,
    required this.status,
    this.clientId,
    this.clientName,
    this.clientEmail,
    this.startedAt,
    this.updatedAt,
    this.finishedAt,
  });

  final String id;
  final String code;
  final String diagramId;
  final String diagramName;
  final int diagramVersion;
  final String status;
  final String? clientId;
  final String? clientName;
  final String? clientEmail;
  final DateTime? startedAt;
  final DateTime? updatedAt;
  final DateTime? finishedAt;

  factory ClientProcessInstance.fromJson(Map<String, dynamic> json) {
    return ClientProcessInstance(
      id: _readString(json, ['id', 'processInstanceId']),
      code: _readString(json, ['code', 'processCode']),
      diagramId: _readString(json, ['diagramId']),
      diagramName: _readString(json, ['diagramName']),
      diagramVersion: _readInt(json['diagramVersion']),
      status: _readString(json, ['status', 'processStatus']),
      clientId: _readNullableString(json['clientId']),
      clientName: _readNullableString(json['clientName']),
      clientEmail: _readNullableString(json['clientEmail']),
      startedAt: _parseDate(json['startedAt']),
      updatedAt: _parseDate(json['updatedAt']),
      finishedAt: _parseDate(json['finishedAt']),
    );
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];

      if (value != null) {
        return value.toString();
      }
    }

    return '';
  }

  static String? _readNullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
