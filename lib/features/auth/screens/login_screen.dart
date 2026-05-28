import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../data/store/invoice_store.dart';
import '../../../data/store/category_store.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';

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
  bool _biometricAvailable = false;
  bool _hasSavedCredentials = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final available = await BiometricService.instance.isAvailable();
      final saved = await BiometricService.instance.hasSavedCredentials();
      if (!mounted) return;
      setState(() {
        _biometricAvailable = available;
        _hasSavedCredentials = saved;
      });
      if (available && saved) {
        // Small delay so screen renders before biometric prompt appears
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) _loginWithBiometrics();
      }
    } catch (_) {
      // Plugin not available — biometrics disabled silently
    }
  }

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

      // Offer biometric save after first successful manual login
      if (_biometricAvailable && !_hasSavedCredentials && mounted) {
        await _offerSaveBiometrics(_emailCtrl.text.trim(), _passCtrl.text);
      }

      await _navigateAfterLogin(profile.isSuperadmin);
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Credenciales incorrectas. Verifica tu correo y contraseña.';
      });
    }
  }

  Future<void> _loginWithBiometrics() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final creds = await BiometricService.instance.authenticate();
      if (creds == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      await AuthService.instance.signIn(email: creds.email, password: creds.password);
      await AuthService.instance.loadProfile();
      final profile = AuthService.instance.profile;
      if (profile == null || !profile.isActive) {
        await AuthService.instance.signOut();
        if (mounted) setState(() { _loading = false; _error = 'Cuenta desactivada.'; });
        return;
      }
      await _navigateAfterLogin(profile.isSuperadmin);
    } on Exception catch (e) {
      final msg = e.toString();
      if (mounted) {
        setState(() {
          _loading = false;
          _error = msg.contains('locked') || msg.contains('lockout')
              ? 'Demasiados intentos. Usa tu contraseña.'
              : msg.contains('NotEnrolled') || msg.contains('enrolled')
                  ? 'No hay huella registrada. Enróllala en Ajustes del dispositivo.'
                  : null; // sin error visible para cancelación
        });
      }
    }
  }

  Future<void> _navigateAfterLogin(bool isSuperadmin) async {
    if (isSuperadmin) {
      await CategoryStore.instance.load();
      if (mounted) context.go('/superadmin');
    } else {
      await Future.wait([
        InvoiceStore.instance.loadAll(),
        CategoryStore.instance.load(),
      ]);
      InvoiceStore.instance.subscribeToChanges();
      if (mounted) context.go('/dashboard');
    }
  }

  Future<void> _offerSaveBiometrics(String email, String password) async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Acceso con huella dactilar',
            style: AppTypography.textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fingerprint, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              '¿Deseas usar tu huella dactilar para iniciar sesión más rápido?',
              style: AppTypography.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, gracias'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await BiometricService.instance.saveCredentials(email, password);
      if (mounted) setState(() => _hasSavedCredentials = true);
    }
  }

  Future<void> _forgotPassword() async {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Recuperar contraseña', style: AppTypography.textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.',
              style: AppTypography.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Iconsax.sms, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enviar enlace'),
          ),
        ],
      ),
    );
    if (confirmed != true || emailCtrl.text.trim().isEmpty) return;
    try {
      await AuthService.instance.resetPassword(emailCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enlace enviado a ${emailCtrl.text.trim()}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
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
                      onPressed: _forgotPassword,
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

                  // Biometric button
                  if (_biometricAvailable) ...[
                    const SizedBox(height: 16),
                    _hasSavedCredentials
                        ? SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton.icon(
                              onPressed: _loading ? null : _loginWithBiometrics,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                foregroundColor: AppColors.primaryLight,
                              ),
                              icon: const Icon(Icons.fingerprint, size: 26),
                              label: const Text('Ingresar con huella dactilar'),
                            ),
                          ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.1)
                        : GestureDetector(
                            onTap: _loading
                                ? null
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Inicia sesión manualmente una vez para activar la huella dactilar.',
                                        ),
                                      ),
                                    );
                                  },
                            child: Container(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.fingerprint,
                                      size: 26,
                                      color: AppColors.textDisabled),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Configurar huella dactilar',
                                    style: AppTypography.textTheme.labelLarge
                                        ?.copyWith(
                                            color: AppColors.textDisabled),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.1),
                  ],

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
