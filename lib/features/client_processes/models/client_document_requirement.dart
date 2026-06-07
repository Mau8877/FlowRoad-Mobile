class ClientDocumentRequirement {
  ClientDocumentRequirement({
    required this.id,
    required this.nodeId,
    required this.name,
    this.description,
    required this.required,
    required this.allowedFileTypes,
    required this.maxFileSizeMb,
    this.clientCanRead,
    this.clientCanUpload,
    this.clientCanReplace,
  });

  final String id;
  final String nodeId;
  final String name;
  final String? description;
  final bool required;
  final List<String> allowedFileTypes;
  final int maxFileSizeMb;
  final bool? clientCanRead;
  final bool? clientCanUpload;
  final bool? clientCanReplace;

  factory ClientDocumentRequirement.fromJson(Map<String, dynamic> json) {
    return ClientDocumentRequirement(
      id: json['id']?.toString() ?? '',
      nodeId: json['nodeId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Documento',
      description: _readNullableString(json['description']),
      required: json['required'] == true,
      allowedFileTypes: _readStringList(json['allowedFileTypes']),
      maxFileSizeMb: _readInt(json['maxFileSizeMb']),
      clientCanRead: _readNullableBool(json['clientCanRead']),
      clientCanUpload: _readNullableBool(json['clientCanUpload']),
      clientCanReplace: _readNullableBool(json['clientCanReplace']),
    );
  }

  static String? _readNullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool? _readNullableBool(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is bool) {
      return value;
    }

    return value.toString().toLowerCase() == 'true';
  }
}
