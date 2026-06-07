class ClientDocumentFile {
  ClientDocumentFile({
    required this.id,
    required this.originalFileName,
    required this.contentType,
    required this.fileExtension,
    required this.fileSizeBytes,
    required this.status,
    required this.version,
    required this.uploadedByName,
    this.uploadedByDepartmentId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String originalFileName;
  final String contentType;
  final String fileExtension;
  final int fileSizeBytes;
  final String status;
  final int version;
  final String uploadedByName;
  final String? uploadedByDepartmentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClientDocumentFile.fromJson(Map<String, dynamic> json) {
    return ClientDocumentFile(
      id: json['id']?.toString() ?? '',
      originalFileName: json['originalFileName']?.toString() ?? 'Archivo',
      contentType: json['contentType']?.toString() ?? '',
      fileExtension: json['fileExtension']?.toString() ?? '',
      fileSizeBytes: _readInt(json['fileSizeBytes']),
      status: json['status']?.toString() ?? '',
      version: _readInt(json['version']),
      uploadedByName: json['uploadedByName']?.toString() ?? 'Sin usuario',
      uploadedByDepartmentId: _readNullableString(
        json['uploadedByDepartmentId'],
      ),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
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
