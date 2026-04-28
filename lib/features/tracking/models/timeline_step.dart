class TimelineStep {
  TimelineStep({
    required this.nodeId,
    required this.label,
    required this.type,
    required this.status,
    this.departmentId,
    this.departmentName,
    this.startedAt,
    this.completedAt,
    this.comment,
  });

  final String nodeId;
  final String label;
  final String type;
  final String status;
  final String? departmentId;
  final String? departmentName;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? comment;

  factory TimelineStep.fromJson(Map<String, dynamic> json) {
    return TimelineStep(
      nodeId: json['nodeId']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Nodo',
      type: json['type']?.toString() ?? 'ACTION',
      status: json['status']?.toString() ?? 'PENDING',
      departmentId: json['departmentId']?.toString(),
      departmentName: json['departmentName']?.toString(),
      startedAt: _parseDate(json['startedAt']),
      completedAt: _parseDate(json['completedAt']),
      comment: json['comment']?.toString(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
