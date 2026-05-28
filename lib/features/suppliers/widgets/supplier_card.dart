import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/supplier_model.dart';

class SupplierCard extends StatelessWidget {
  const SupplierCard({
    super.key,
    required this.supplier,
    this.index = 0,
    this.onTap,
    this.onPaymentsTap,
    this.onEdit,
    this.onDelete,
  });

  final SupplierModel supplier;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onPaymentsTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: supplier.avatarColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            supplier.initials,
                            style: TextStyle(
                              color: supplier.avatarColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    supplier.name,
                                    style: AppTypography.textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!supplier.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.textDisabled,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'INACTIVO',
                                      style: AppTypography.tag.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (supplier.tags.isNotEmpty)
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: supplier.tags.map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: supplier.avatarColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tag,
                                    style: AppTypography.tag.copyWith(
                                      color: supplier.avatarColor,
                                    ),
                                  ),
                                )).toList(),
                              )
                            else
                              Text('Sin categorías', style: AppTypography.caption),
                          ],
                        ),
                      ),

                      if (onEdit != null || onDelete != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onEdit != null)
                              IconButton(
                                onPressed: onEdit,
                                icon: const Icon(Iconsax.edit_2, size: 16),
                                color: AppColors.textSecondary,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            if (onDelete != null)
                              IconButton(
                                onPressed: onDelete,
                                icon: const Icon(Iconsax.trash, size: 16),
                                color: AppColors.error,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                          ],
                        )
                      else
                        const Icon(
                          Iconsax.arrow_right_3,
                          size: 16,
                          color: AppColors.textDisabled,
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _StatPill(
                        label: 'Facturas',
                        value: '${supplier.totalInvoices}',
                        icon: Iconsax.document_text,
                        onTap: onPaymentsTap,
                      ),
                      const SizedBox(width: 12),
                      _StatPill(
                        label: 'Total acumulado',
                        value: fmt.format(supplier.totalAmount),
                        icon: Iconsax.money_recive,
                      ),
                      if (supplier.pendingAmount > 0) ...[
                        const SizedBox(width: 12),
                        _StatPill(
                          label: 'Por pagar',
                          value: fmt.format(supplier.pendingAmount),
                          icon: Iconsax.clock,
                          highlight: true,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 70), duration: 350.ms)
        .slideY(begin: 0.08);
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
    this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: highlight ? AppColors.warningSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highlight ? AppColors.warning.withValues(alpha: 0.25) : AppColors.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 11,
                  color: highlight ? AppColors.warning : AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: highlight ? AppColors.warningLight : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: AppTypography.textTheme.labelLarge?.copyWith(
                fontSize: 11,
                color: highlight ? AppColors.warningLight : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      ),
    );
  }
}
