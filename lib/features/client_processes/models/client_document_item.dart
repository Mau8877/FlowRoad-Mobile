import 'client_document_file.dart';
import 'client_document_requirement.dart';

class ClientDocumentItem {
  ClientDocumentItem({
    required this.requirement,
    this.currentFile,
    required this.status,
    required this.canRead,
    required this.canUpload,
    required this.canReplace,
  });

  final ClientDocumentRequirement requirement;
  final ClientDocumentFile? currentFile;
  final String status;
  final bool canRead;
  final bool canUpload;
  final bool canReplace;

  factory ClientDocumentItem.fromJson(Map<String, dynamic> json) {
    final rawRequirement = json['requirement'];
    final rawFile = json['currentFile'];

    return ClientDocumentItem(
      requirement: rawRequirement is Map
          ? ClientDocumentRequirement.fromJson(
              rawRequirement.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            )
          : ClientDocumentRequirement.fromJson(const {}),
      currentFile: rawFile is Map
          ? ClientDocumentFile.fromJson(
              rawFile.map((key, value) => MapEntry(key.toString(), value)),
            )
          : null,
      status: json['status']?.toString() ?? 'PENDING',
      canRead: json['canRead'] == true,
      canUpload: json['canUpload'] == true,
      canReplace: json['canReplace'] == true,
    );
  }
}
