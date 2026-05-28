import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/store/invoice_store.dart';
import '../../../shared/widgets/status_badge.dart';

class RecentInvoicesWidget extends StatelessWidget {
  const RecentInvoicesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final recent = InvoiceStore.instance.invoices.take(4).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Facturas Recientes', style: AppTypography.textTheme.titleLarge),
            TextButton.icon(
              onPressed: () => context.go('/invoices'),
              icon: const Icon(Iconsax.arrow_right_3, size: 14),
              label: const Text('Ver todas'),
              iconAlignment: IconAlignment.end,
            ),
          ],
        ).animate().fadeIn(delay: 450.ms),

        const SizedBox(height: 12),

        ...List.generate(recent.length, (i) {
          final inv = recent[i];
          return _InvoiceRow(invoice: inv, index: i);
        }),
      ],
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.invoice, required this.index});
  final InvoiceModel invoice;
  final int index;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM', 'es');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/invoices/${invoice.id}'),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (invoice.supplierColor ?? AppColors.primary).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      invoice.supplierInitials,
                      style: TextStyle(
                        color: invoice.supplierColor ?? AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
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
                        '${invoice.invoiceNumber} · Vence ${dateFmt.format(invoice.dueDate)}',
                        style: AppTypography.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Amount + status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fmt.format(invoice.finalAmount),
                      style: AppTypography.moneySmall.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    StatusBadge(status: invoice.status, compact: true),
                  ],
                ),

                const SizedBox(width: 4),
                const Icon(Iconsax.arrow_right_3, size: 14, color: AppColors.textDisabled),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 500 + index * 60), duration: 350.ms)
        .slideX(begin: 0.05);
  }
}
