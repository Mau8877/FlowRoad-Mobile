import 'timeline_step.dart';

class PublicTracking {
  PublicTracking({
    required this.code,
    required this.diagramName,
    required this.status,
    required this.statusLabel,
    required this.currentStepName,
    this.currentDepartmentName,
    this.startedAt,
    this.updatedAt,
    this.finishedAt,
    required this.timeline,
  });

  final String code;
  final String diagramName;
  final String status;
  final String statusLabel;
  final String currentStepName;
  final String? currentDepartmentName;
  final DateTime? startedAt;
  final DateTime? updatedAt;
  final DateTime? finishedAt;
  final List<TimelineStep> timeline;

  factory PublicTracking.fromJson(Map<String, dynamic> json) {
    final rawTimeline = json['timeline'];
    final steps = <TimelineStep>[];

    if (rawTimeline is List) {
      for (final item in rawTimeline) {
        if (item is Map) {
          steps.add(
            TimelineStep.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
      }
    }

    return PublicTracking(
      code: json['code']?.toString() ?? '',
      diagramName: json['diagramName']?.toString() ?? 'Proceso',
      status: json['status']?.toString() ?? '',
      statusLabel: json['statusLabel']?.toString() ?? 'Sin estado',
      currentStepName: json['currentStepName']?.toString() ?? 'Sin paso actual',
      currentDepartmentName: json['currentDepartmentName']?.toString(),
      startedAt: _parseDate(json['startedAt']),
      updatedAt: _parseDate(json['updatedAt']),
      finishedAt: _parseDate(json['finishedAt']),
      timeline: steps,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
