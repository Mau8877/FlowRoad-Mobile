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
      return Card(
        elevation: 0,
        color: AppColors.frWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'No hay pasos disponibles para este trámite.',
            style: TextStyle(color: AppColors.frMuted),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: AppColors.frWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
