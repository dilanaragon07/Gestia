import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class StatCardWidget extends StatelessWidget {
  const StatCardWidget({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.gradient,
    this.subtitle,
    this.change,
    this.isPositiveChange = true,
    this.animDelay = 0,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final LinearGradient gradient;
  final String? subtitle;
  final double? change;
  final bool isPositiveChange;
  final int animDelay;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              if (change != null)
                _ChangePill(change: change!, isPositive: isPositiveChange),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            fmt.format(amount),
            style: AppTypography.moneySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textDisabled,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: animDelay), duration: 400.ms)
        .slideY(begin: 0.15, curve: Curves.easeOutCubic);
  }
}

class _ChangePill extends StatelessWidget {
  const _ChangePill({required this.change, required this.isPositive});
  final double change;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.success : AppColors.error;
    final icon = isPositive ? Iconsax.arrow_up_3 : Iconsax.arrow_down_2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            '${change.abs().toStringAsFixed(1)}%',
            style: AppTypography.tag.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
