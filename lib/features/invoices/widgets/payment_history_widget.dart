import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/payment_model.dart';
import '../screens/payment_receipt_sheet.dart';

class PaymentHistoryWidget extends StatelessWidget {
  const PaymentHistoryWidget({super.key, required this.invoice});

  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 2);

    if (invoice.payments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Iconsax.receipt, size: 20, color: AppColors.textTertiary),
            const SizedBox(width: 12),
            Text('Sin abonos registrados', style: AppTypography.textTheme.bodyMedium),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Iconsax.receipt, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Text(
                  'Historial de Abonos',
                  style: AppTypography.textTheme.titleLarge,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${invoice.paymentCount}',
                    style: AppTypography.tag.copyWith(color: AppColors.primaryLight),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Payment rows
          ...List.generate(invoice.payments.length, (i) {
            final payment = invoice.payments[i];
            final isLast = i == invoice.payments.length - 1;
            return _PaymentRow(
              payment: payment,
              invoice: invoice,
              index: i,
              isLast: isLast,
              fmt: fmt,
            );
          }),

          // Summary footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _FooterStat(
                    label: 'Total pagado',
                    value: fmt.format(invoice.totalPaid),
                    color: AppColors.success,
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.divider),
                Expanded(
                  child: _FooterStat(
                    label: 'Saldo pendiente',
                    value: fmt.format(invoice.balance < 0 ? 0 : invoice.balance),
                    color: invoice.balance <= 0.01
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.divider),
                Expanded(
                  child: _FooterStat(
                    label: 'Pagos',
                    value: '${invoice.paymentCount}',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.invoice,
    required this.index,
    required this.isLast,
    required this.fmt,
  });

  final PaymentModel payment;
  final InvoiceModel invoice;
  final int index;
  final bool isLast;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy', 'es_CO');

    return Column(
      children: [
        GestureDetector(
          onTap: () => PaymentReceiptSheet.show(context, payment: payment, invoice: invoice),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Number badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '#${index + 1}',
                      style: AppTypography.tag.copyWith(color: AppColors.primaryLight),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Method icon
                Icon(payment.method.icon, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 8),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(payment.method.label, style: AppTypography.textTheme.titleSmall),
                      Text(
                        dateFmt.format(payment.paymentDate),
                        style: AppTypography.caption,
                      ),
                      if (payment.notes != null)
                        Text(
                          payment.notes!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textDisabled,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                if (payment.evidencePath != null) ...[
                  const Icon(Iconsax.camera, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 8),
                ],

                // Amount
                Text(
                  fmt.format(payment.amount),
                  style: AppTypography.textTheme.titleLarge?.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 60), duration: 300.ms)
            .slideX(begin: 0.05),
        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

class _FooterStat extends StatelessWidget {
  const _FooterStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.textTheme.labelLarge?.copyWith(
            color: color,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
