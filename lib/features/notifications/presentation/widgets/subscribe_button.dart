import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/notification_service.dart';

class SubscribeButton extends StatefulWidget {
  const SubscribeButton({super.key, required this.trackingCode});

  final String trackingCode;

  @override
  State<SubscribeButton> createState() => _SubscribeButtonState();
}

class _SubscribeButtonState extends State<SubscribeButton> {
  final _notificationService = NotificationService();

  bool _isLoading = false;
  bool _subscribed = false;

  Future<void> _subscribe() async {
    setState(() => _isLoading = true);

    try {
      await _notificationService.subscribeToTracking(
        trackingCode: widget.trackingCode,
      );

      if (!mounted) {
        return;
      }

      setState(() => _subscribed = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Suscripción activada correctamente.'),
          backgroundColor: AppColors.frBrown,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.frDanger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_subscribed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.frGold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.frGold.withValues(alpha: 0.32)),
        ),
        child: const Row(
          children: [
            Icon(Icons.notifications_active_outlined, color: AppColors.frGold),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ya estás suscrito a las notificaciones de este trámite.',
                style: TextStyle(
                  color: AppColors.frGold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PrimaryButton(
      text: 'Suscribirme a notificaciones',
      icon: Icons.notifications_active_outlined,
      isLoading: _isLoading,
      onPressed: _subscribe,
    );
  }
}
