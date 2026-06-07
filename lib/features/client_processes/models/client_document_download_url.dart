class ClientDocumentDownloadUrl {
  ClientDocumentDownloadUrl({
    required this.documentFileId,
    required this.originalFileName,
    required this.contentType,
    required this.expiresInSeconds,
    required this.downloadUrl,
  });

  final String documentFileId;
  final String originalFileName;
  final String contentType;
  final int expiresInSeconds;
  final String downloadUrl;

  factory ClientDocumentDownloadUrl.fromJson(Map<String, dynamic> json) {
    return ClientDocumentDownloadUrl(
      documentFileId: json['documentFileId']?.toString() ?? '',
      originalFileName: json['originalFileName']?.toString() ?? 'Archivo',
      contentType: json['contentType']?.toString() ?? '',
      expiresInSeconds: _readInt(json['expiresInSeconds']),
      downloadUrl: json['downloadUrl']?.toString() ?? '',
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
