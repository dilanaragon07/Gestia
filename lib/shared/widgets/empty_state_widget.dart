import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 36, color: AppColors.textTertiary),
            )
                .animate()
                .scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTypography.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.2),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 150.ms, duration: 300.ms).slideY(begin: 0.2),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(actionLabel!),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 300.ms)
                  .slideY(begin: 0.2),
            ],
          ],
        ),
      ),
    );
  }
}
