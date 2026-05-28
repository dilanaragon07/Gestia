import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../data/store/invoice_store.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _navTimer = Timer(const Duration(milliseconds: 2400), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    if (AuthService.instance.isAuthenticated) {
      await AuthService.instance.loadProfile();
      final profile = AuthService.instance.profile;

      if (profile == null || !profile.isActive) {
        await AuthService.instance.signOut();
        if (mounted) context.go('/login');
        return;
      }

      if (profile.isSuperadmin) {
        if (mounted) context.go('/superadmin');
      } else {
        await InvoiceStore.instance.loadAll();
        InvoiceStore.instance.subscribeToChanges();
        if (mounted) context.go('/dashboard');
      }
    } else {
      if (mounted) context.go('/login');
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Background grid pattern
              Positioned.fill(
                child: CustomPaint(painter: _GridPainter()),
              ),

              // Glow orb top-right
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Glow orb bottom-left
              Positioned(
                bottom: -40,
                left: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.purple.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Center content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo mark
                    const AppLogo(size: 80)
                        .animate()
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        )
                        .fadeIn(duration: 400.ms),

                    const SizedBox(height: 24),

                    // App name
                    Text(
                      'Gestia',
                      style: AppTypography.textTheme.displaySmall?.copyWith(
                        letterSpacing: -1.5,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 400.ms)
                        .slideY(begin: 0.3),

                    const SizedBox(height: 8),

                    Text(
                      'Gestión de Cuentas por Pagar',
                      style: AppTypography.textTheme.bodyMedium,
                    )
                        .animate()
                        .fadeIn(delay: 450.ms, duration: 400.ms)
                        .slideY(begin: 0.3),
                  ],
                ),
              ),

              // Bottom loading indicator
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 2,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 400.ms),
                    const SizedBox(height: 16),
                    Text(
                      'v1.0.0',
                      style: AppTypography.caption,
                    )
                        .animate()
                        .fadeIn(delay: 700.ms, duration: 400.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
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
