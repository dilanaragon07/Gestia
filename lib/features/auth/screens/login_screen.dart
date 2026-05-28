import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../data/store/invoice_store.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.instance.signIn(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      await AuthService.instance.loadProfile();
      final profile = AuthService.instance.profile;

      if (profile == null || !profile.isActive) {
        await AuthService.instance.signOut();
        setState(() {
          _loading = false;
          _error = 'Tu cuenta ha sido desactivada. Contacta al administrador.';
        });
        return;
      }

      if (profile.isSuperadmin) {
        if (mounted) context.go('/superadmin');
      } else {
        await InvoiceStore.instance.loadAll();
        InvoiceStore.instance.subscribeToChanges();
        if (mounted) context.go('/dashboard');
      }
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Credenciales incorrectas. Verifica tu correo y contraseña.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(gradient: AppColors.splashGradient),
          ),

          // Grid
          Positioned.fill(child: CustomPaint(painter: _FaintGridPainter())),

          // Glow accents
          Positioned(
            top: -80,
            left: -80,
            child: _GlowOrb(color: AppColors.primary, size: 280),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: _GlowOrb(color: AppColors.purple, size: 220),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // Logo
                  const AppLogo(size: 56)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.8, 0.8)),

                  const SizedBox(height: 36),

                  Text(
                    'Bienvenido',
                    style: AppTypography.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: -0.1),

                  const SizedBox(height: 6),

                  Text(
                    'Inicia sesión para continuar',
                    style: AppTypography.textTheme.bodyMedium,
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideX(begin: -0.1),

                  const SizedBox(height: 48),

                  // Email
                  _FormLabel(label: 'Correo electrónico')
                      .animate()
                      .fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTypography.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'correo@empresa.com',
                      prefixIcon: const Icon(Iconsax.sms, size: 18),
                    ),
                  ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.1),

                  const SizedBox(height: 20),

                  // Password
                  _FormLabel(label: 'Contraseña').animate().fadeIn(delay: 260.ms),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: AppTypography.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Iconsax.lock, size: 18),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Iconsax.eye_slash : Iconsax.eye,
                          size: 18,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.1),

                  const SizedBox(height: 12),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ).animate().fadeIn(delay: 310.ms),

                  const SizedBox(height: 28),

                  // Error
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.errorSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Iconsax.warning_2, size: 16, color: AppColors.error),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: AppTypography.textTheme.bodySmall?.copyWith(
                                color: AppColors.errorLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Iniciar Sesión'),
                    ),
                  ).animate().fadeIn(delay: 340.ms).slideY(begin: 0.1),

                  const SizedBox(height: 48),

                  // Footer
                  Center(
                    child: Text(
                      'Gestia © 2026 — Todos los derechos reservados',
                      style: AppTypography.caption,
                      textAlign: TextAlign.center,
                    ),
                  ).animate().fadeIn(delay: 450.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.textTheme.labelLarge?.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _FaintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    const spacing = 44.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
