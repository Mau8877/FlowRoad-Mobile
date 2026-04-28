import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../tracking/presentation/pages/tracking_code_page.dart';
import '../../data/auth_service.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const String routeName = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(TrackingCodePage.routeName);
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.frDanger),
    );
  }

  void _goToRegister() {
    Navigator.of(context).pushNamed(RegisterPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.frBrown,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.frBrown, AppColors.frBlack],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: AppColors.frGold.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: AppColors.frGold.withValues(alpha: 0.45),
                        ),
                      ),
                      child: const Icon(
                        Icons.route_outlined,
                        color: AppColors.frGold,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'FLOWROAD',
                      style: TextStyle(
                        color: AppColors.frGold,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Seguimiento móvil de trámites',
                      style: TextStyle(
                        color: AppColors.frMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.frBlack.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: AppColors.frGold.withValues(alpha: 0.24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.frBlack.withValues(alpha: 0.35),
                            blurRadius: 30,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppColors.frCream,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Accede para consultar el avance de tu trámite.',
                              style: TextStyle(
                                color: AppColors.frMuted,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            AppTextField(
                              controller: _emailController,
                              label: 'Correo',
                              hintText: 'cliente@correo.com',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              prefixIcon: Icons.mail_outline,
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _passwordController,
                              label: 'Contraseña',
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              prefixIcon: Icons.lock_outline,
                              validator: Validators.password,
                            ),
                            const SizedBox(height: 24),
                            PrimaryButton(
                              text: 'Iniciar sesión',
                              icon: Icons.login,
                              isLoading: _isLoading,
                              onPressed: _login,
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: TextButton(
                                onPressed: _isLoading ? null : _goToRegister,
                                child: const Text(
                                  'Crear cuenta de cliente',
                                  style: TextStyle(
                                    color: AppColors.frGold,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
