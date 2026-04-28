import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../login/data/auth_service.dart';
import '../../../login/presentation/pages/login_page.dart';
import '../../data/tracking_service.dart';
import 'tracking_detail_page.dart';

class TrackingCodePage extends StatefulWidget {
  const TrackingCodePage({super.key});

  static const String routeName = '/tracking-code';

  @override
  State<TrackingCodePage> createState() => _TrackingCodePageState();
}

class _TrackingCodePageState extends State<TrackingCodePage> {
  final _trackingService = TrackingService();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _searchTracking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tracking = await _trackingService.getTrackingByCode(
        _codeController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamed(TrackingDetailPage.routeName, arguments: tracking);
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginPage.routeName, (_) => false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.frDanger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.frGray,
      appBar: AppBar(
        title: const Text('Consultar trámite'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                elevation: 0,
                color: AppColors.frWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: AppColors.frGold.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.route_outlined,
                            size: 38,
                            color: AppColors.frGold,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Consulta el avance de tu trámite',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.frBlack,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ingresa el código de seguimiento que te entregó la empresa.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.frMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppTextField(
                          controller: _codeController,
                          label: 'Código de seguimiento',
                          hintText: 'PROC-20260427-C65A82',
                          prefixIcon: Icons.confirmation_number_outlined,
                          textInputAction: TextInputAction.search,
                          validator: (value) => Validators.required(
                            value,
                            'El código es obligatorio',
                          ),
                        ),
                        const SizedBox(height: 22),
                        PrimaryButton(
                          text: 'Consultar trámite',
                          icon: Icons.search,
                          isLoading: _isLoading,
                          onPressed: _searchTracking,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
