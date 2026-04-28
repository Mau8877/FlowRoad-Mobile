import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../tracking/presentation/pages/tracking_code_page.dart';
import '../../data/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  static const String routeName = '/register';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.registerClient(
        email: _emailController.text,
        password: _passwordController.text,
        nombre: _nombreController.text,
        apellido: _apellidoController.text,
        telefono: _telefonoController.text,
        direccion: _direccionController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(TrackingCodePage.routeName, (_) => false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.frBrown,
      appBar: AppBar(
        title: const Text('Registro'),
        backgroundColor: AppColors.frBlack,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.frBrown, AppColors.frBlack],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.frBlack.withValues(alpha: 0.80),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: AppColors.frGold.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.frBlack.withValues(alpha: 0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Crear cuenta',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.frCream,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Regístrate para consultar tus trámites desde el móvil.',
                            style: TextStyle(
                              color: AppColors.frMuted,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        AppTextField(
                          controller: _nombreController,
                          label: 'Nombre',
                          prefixIcon: Icons.person_outline,
                          validator: (value) => Validators.required(
                            value,
                            'El nombre es obligatorio',
                          ),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _apellidoController,
                          label: 'Apellido',
                          prefixIcon: Icons.person_outline,
                          validator: (value) => Validators.required(
                            value,
                            'El apellido es obligatorio',
                          ),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _telefonoController,
                          label: 'Teléfono',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                          validator: (value) => Validators.required(
                            value,
                            'El teléfono es obligatorio',
                          ),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _direccionController,
                          label: 'Dirección',
                          prefixIcon: Icons.location_on_outlined,
                          validator: (value) => Validators.required(
                            value,
                            'La dirección es obligatoria',
                          ),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _emailController,
                          label: 'Correo',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.mail_outline,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          obscureText: true,
                          prefixIcon: Icons.lock_outline,
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: 'Registrarme',
                          icon: Icons.person_add_alt_1,
                          isLoading: _isLoading,
                          onPressed: _register,
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
