import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/timeline_step.dart';

class TimelineStepTile extends StatelessWidget {
  const TimelineStepTile({
    super.key,
    required this.step,
    required this.isFirst,
    required this.isLast,
  });

  final TimelineStep step;
  final bool isFirst;
  final bool isLast;

  Color get _statusColor {
    return switch (step.status) {
      'COMPLETED' => AppColors.frGold,
      'CURRENT' => AppColors.frGold,
      'CANCELLED' => AppColors.frDanger,
      _ => AppColors.frTaupe,
    };
  }

  IconData get _statusIcon {
    return switch (step.status) {
      'COMPLETED' => Icons.check,
      'CURRENT' => Icons.radio_button_checked,
      'CANCELLED' => Icons.close,
      _ => Icons.circle_outlined,
    };
  }

  String get _statusLabel {
    return switch (step.status) {
      'COMPLETED' => 'Completado',
      'CURRENT' => 'Actual',
      'CANCELLED' => 'Cancelado',
      _ => 'Pendiente',
    };
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    final local = date.toLocal();

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final completedAtText = _formatDate(step.completedAt);
    final startedAtText = _formatDate(step.startedAt);
    final isCurrent = step.status == 'CURRENT';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 58,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : AppColors.frTaupe.withValues(alpha: 0.35),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: _statusColor, width: 2),
                  ),
                  child: Icon(_statusIcon, size: 18, color: _statusColor),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : AppColors.frTaupe.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.frGold.withValues(alpha: 0.12)
                      : AppColors.frBlack.withValues(alpha: 0.56),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrent
                        ? AppColors.frGold.withValues(alpha: 0.45)
                        : AppColors.frTaupe.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.label,
                      style: const TextStyle(
                        color: AppColors.frCream,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Badge(text: _statusLabel, color: _statusColor),
                        _Badge(text: step.type, color: AppColors.frTaupe),
                      ],
                    ),
                    if (step.departmentName != null &&
                        step.departmentName!.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Text(
                        step.departmentName!,
                        style: const TextStyle(
                          color: AppColors.frMuted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    if (startedAtText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Inicio: $startedAtText',
                        style: const TextStyle(
                          color: AppColors.frMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (completedAtText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Completado: $completedAtText',
                        style: const TextStyle(
                          color: AppColors.frMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
