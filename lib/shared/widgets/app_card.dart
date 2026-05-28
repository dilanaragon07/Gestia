import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.gradient,
    this.borderColor,
    this.borderRadius = 16,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final LinearGradient? gradient;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: AppColors.primaryMuted.withValues(alpha: 0.3),
        highlightColor: AppColors.primaryMuted.withValues(alpha: 0.1),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? AppColors.card : null,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AppColors.border,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
