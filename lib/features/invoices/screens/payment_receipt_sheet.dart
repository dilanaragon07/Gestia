import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/payment_model.dart';

class PaymentReceiptSheet extends StatelessWidget {
  const PaymentReceiptSheet({
    super.key,
    required this.payment,
    required this.invoice,
  });

  final PaymentModel payment;
  final InvoiceModel invoice;

  static Future<void> show(
    BuildContext context, {
    required PaymentModel payment,
    required InvoiceModel invoice,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentReceiptSheet(payment: payment, invoice: invoice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 2);
    final dateFmt = DateFormat('dd/MM/yyyy', 'es_CO');
    final hasEvidence = payment.evidencePath != null &&
        File(payment.evidencePath!).existsSync();

    return DraggableScrollableSheet(
      initialChildSize: hasEvidence ? 0.88 : 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: ListView(
          controller: controller,
          padding: EdgeInsets.zero,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: (invoice.supplierColor ?? AppColors.primary)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Comprobante de Pago',
                            style: AppTypography.textTheme.titleLarge),
                        Text(invoice.supplierName,
                            style: AppTypography.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Iconsax.close_circle, size: 20),
                    color: AppColors.textTertiary,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),
            const SizedBox(height: 20),

            // Amount — prominente
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success.withValues(alpha: 0.12),
                      AppColors.success.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.25)),
                ),
                child: Column(
                  children: [
                    Text('Monto pagado', style: AppTypography.caption),
                    const SizedBox(height: 6),
                    Text(
                      fmt.format(payment.amount),
                      style: AppTypography.textTheme.headlineLarge?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Detalles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Iconsax.document_text,
                      label: 'Factura',
                      value: invoice.invoiceNumber,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _DetailRow(
                      icon: Iconsax.calendar,
                      label: 'Fecha de pago',
                      value: dateFmt.format(payment.paymentDate),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _DetailRow(
                      icon: payment.method.icon,
                      label: 'Método',
                      value: payment.method.label,
                    ),
                    if (payment.notes != null) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _DetailRow(
                        icon: Iconsax.note,
                        label: 'Notas',
                        value: payment.notes!,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Evidencia fotográfica
            if (hasEvidence) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Iconsax.camera, size: 16,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text('Evidencia fotográfica',
                            style: AppTypography.textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _showFullImage(context, payment.evidencePath!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(payment.evidencePath!),
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Toca la imagen para ampliar',
                        style: AppTypography.caption),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.file(File(path), fit: BoxFit.contain),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Iconsax.close_circle,
                    color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Text(label, style: AppTypography.caption),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: AppTypography.textTheme.titleSmall
                  ?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.end,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
