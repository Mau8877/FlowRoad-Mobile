import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../notifications/presentation/widgets/subscribe_button.dart';
import '../../models/public_tracking.dart';
import '../widgets/process_timeline.dart';

class TrackingDetailPage extends StatelessWidget {
  const TrackingDetailPage({super.key, required this.tracking});

  static const String routeName = '/tracking-detail';

  final PublicTracking tracking;

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Sin fecha';
    }

    final local = date.toLocal();

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  Color _statusColor(String status) {
    return switch (status) {
      'COMPLETED' => AppColors.frSuccess,
      'CANCELLED' => AppColors.frDanger,
      'PENDING_ASSIGNMENT' => AppColors.frWarning,
      _ => AppColors.frGold,
    };
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(tracking.status);

    return Scaffold(
      backgroundColor: AppColors.frGray,
      appBar: AppBar(title: const Text('Detalle del trámite')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              elevation: 0,
              color: AppColors.frWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tracking.diagramName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.frBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      tracking.code,
                      style: const TextStyle(
                        color: AppColors.frMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tracking.statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _DetailRow(
                      icon: Icons.play_circle_outline,
                      label: 'Paso actual',
                      value: tracking.currentStepName,
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons.apartment_outlined,
                      label: 'Departamento actual',
                      value: tracking.currentDepartmentName ?? 'No asignado',
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Inicio',
                      value: _formatDate(tracking.startedAt),
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons.update,
                      label: 'Última actualización',
                      value: _formatDate(tracking.updatedAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SubscribeButton(trackingCode: tracking.code),
            const SizedBox(height: 18),
            const Text(
              'Avance del proceso',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.frBlack,
              ),
            ),
            const SizedBox(height: 10),
            ProcessTimeline(steps: tracking.timeline),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.frBrown, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.frMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.frBlack,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
