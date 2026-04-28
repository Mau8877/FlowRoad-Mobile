import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/timeline_step.dart';
import 'timeline_step_tile.dart';

class ProcessTimeline extends StatelessWidget {
  const ProcessTimeline({super.key, required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.frCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.frGold.withValues(alpha: 0.18)),
        ),
        child: const Text(
          'No hay pasos disponibles para este trámite.',
          style: TextStyle(color: AppColors.frMuted),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.frCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.frGold.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: List.generate(steps.length, (index) {
            return TimelineStepTile(
              step: steps[index],
              isFirst: index == 0,
              isLast: index == steps.length - 1,
            );
          }),
        ),
      ),
    );
  }
}
