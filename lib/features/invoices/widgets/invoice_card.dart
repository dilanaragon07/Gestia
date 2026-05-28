import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/invoice_model.dart';
import '../../../shared/widgets/status_badge.dart';

class InvoiceCard extends StatelessWidget {
  const InvoiceCard({super.key, required this.invoice, this.index = 0});

  final InvoiceModel invoice;
  final int index;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/invoices/${invoice.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: invoice.status == InvoiceStatus.overdue
                    ? AppColors.error.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: (invoice.supplierColor ?? AppColors.primary)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Center(
                          child: Text(
                            invoice.supplierInitials,
                            style: TextStyle(
                              color: invoice.supplierColor ?? AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Supplier + number
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.supplierName,
                              style: AppTypography.textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              invoice.invoiceNumber,
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),

                      // Amount
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            fmt.format(invoice.finalAmount),
                            style: AppTypography.moneySmall,
                          ),
                          const SizedBox(height: 4),
                          StatusBadge(status: invoice.status, compact: true),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _MetaChip(
                        icon: Iconsax.calendar,
                        label: 'Emitida ${dateFmt.format(invoice.issueDate)}',
                      ),
                      const Spacer(),
                      _MetaChip(
                        icon: Iconsax.timer,
                        label: 'Vence ${dateFmt.format(invoice.dueDate)}',
                        color: invoice.isOverdue ? AppColors.error : null,
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Iconsax.arrow_right_3,
                        size: 14,
                        color: AppColors.textDisabled,
                      ),
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
        .fadeIn(delay: Duration(milliseconds: index * 60), duration: 350.ms)
        .slideY(begin: 0.08);
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.caption.copyWith(color: c)),
      ],
    );
  }
}
