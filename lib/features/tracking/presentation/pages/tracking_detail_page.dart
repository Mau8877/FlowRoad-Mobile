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
      'PENDING_ASSIGNMENT' => AppColors.frTaupe,
      _ => AppColors.frGold,
    };
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(tracking.status);

    return Scaffold(
      backgroundColor: AppColors.frBlack,
      appBar: AppBar(
        title: const Text('Detalle del trámite'),
        backgroundColor: AppColors.frBlack,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.frBrown, AppColors.frBlack],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: AppColors.frGold.withValues(alpha: 0.22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trámite',
                    style: TextStyle(
                      color: AppColors.frGold,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tracking.diagramName,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: AppColors.frCream,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    tracking.code,
                    style: const TextStyle(
                      color: AppColors.frMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      tracking.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _DetailRow(
                    icon: Icons.play_circle_outline,
                    label: 'Paso actual',
                    value: tracking.currentStepName,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.apartment_outlined,
                    label: 'Departamento actual',
                    value: tracking.currentDepartmentName ?? 'No asignado',
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Inicio',
                    value: _formatDate(tracking.startedAt),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.update,
                    label: 'Última actualización',
                    value: _formatDate(tracking.updatedAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SubscribeButton(trackingCode: tracking.code),
            const SizedBox(height: 22),
            const Text(
              'Avance del proceso',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: AppColors.frGold,
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
        Icon(icon, color: AppColors.frGold, size: 21),
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
                  color: AppColors.frCream,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
