import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/store/invoice_store.dart';
import '../../../shared/widgets/status_badge.dart';
import '../widgets/payment_history_widget.dart';
import '../widgets/register_payment_sheet.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});
  final String invoiceId;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  @override
  void initState() {
    super.initState();
    InvoiceStore.instance.addListener(_onStoreUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InvoiceStore.instance.loadInvoiceDetail(widget.invoiceId);
    });
  }

  @override
  void dispose() {
    InvoiceStore.instance.removeListener(_onStoreUpdate);
    super.dispose();
  }

  void _onStoreUpdate() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  InvoiceModel? get _invoice => InvoiceStore.instance.findById(widget.invoiceId);

  @override
  Widget build(BuildContext context) {
    final inv = _invoice;
    if (inv == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Factura')),
        body: const Center(child: Text('Factura no encontrada')),
      );
    }

    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 2);
    final dateFmt = DateFormat('dd MMMM yyyy', 'es');

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.scaffold,
            expandedHeight: 210,
            pinned: true,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Iconsax.arrow_left),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Iconsax.more, size: 20),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: (inv.supplierColor ?? AppColors.primary)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          inv.supplierInitials,
                          style: TextStyle(
                            color: inv.supplierColor ?? AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      inv.supplierName,
                      style: AppTypography.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(inv.invoiceNumber, style: AppTypography.caption),
                        const SizedBox(width: 10),
                        StatusBadge(status: inv.status),
                        if (inv.isOverdue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.errorSurface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'VENCIDA',
                              style: AppTypography.tag.copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Balance summary card
                _BalanceSummaryCard(invoice: inv, fmt: fmt)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1),

                const SizedBox(height: 16),

                // Discount badge if applicable
                if (inv.novedadType != NovedadType.ok)
                  _NovedadBadge(invoice: inv, fmt: fmt)
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 350.ms),

                if (inv.novedadType != NovedadType.ok) const SizedBox(height: 16),

                // Details
                _SectionCard(
                  title: 'Detalles',
                  children: [
                    _DetailRow(label: 'Número', value: inv.invoiceNumber),
                    _DetailRow(label: 'Categoría', value: inv.category),
                    _DetailRow(
                      label: 'Fecha emisión',
                      value: dateFmt.format(inv.issueDate),
                    ),
                    _DetailRow(
                      label: 'Vencimiento',
                      value: dateFmt.format(inv.dueDate),
                      valueColor: inv.isOverdue ? AppColors.error : null,
                    ),
                    if (inv.createdByName != null)
                      _DetailRow(label: 'Creado por', value: inv.createdByName!),
                    if (inv.notes != null)
                      _DetailRow(label: 'Notas', value: inv.notes!),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 120.ms, duration: 350.ms)
                    .slideY(begin: 0.1),

                const SizedBox(height: 16),

                // Financial breakdown
                _SectionCard(
                  title: 'Desglose Financiero',
                  children: [
                    _DetailRow(
                      label: 'Valor neto',
                      value: fmt.format(inv.netAmount),
                    ),
                    if (inv.discountAmount > 0) ...[
                      _DetailRow(
                        label: 'Descuento',
                        value: '− ${fmt.format(inv.discountAmount)}',
                        valueColor: AppColors.error,
                      ),
                    ],
                    const Divider(height: 20),
                    _DetailRow(
                      label: 'Valor final',
                      value: fmt.format(inv.finalAmount),
                      valueBold: true,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Total pagado',
                      value: fmt.format(inv.totalPaid),
                      valueColor: AppColors.success,
                    ),
                    _DetailRow(
                      label: 'Saldo pendiente',
                      value: fmt.format(inv.balance < 0 ? 0 : inv.balance),
                      valueColor:
                          inv.balance <= 0.01 ? AppColors.success : AppColors.warning,
                      valueBold: true,
                    ),
                    _DetailRow(
                      label: 'Cantidad de pagos',
                      value: '${inv.paymentCount}',
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 160.ms, duration: 350.ms)
                    .slideY(begin: 0.1),

                const SizedBox(height: 16),

                // Payment history
                PaymentHistoryWidget(invoice: inv)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 350.ms),

                const SizedBox(height: 24),

                // Actions
                _ActionButtons(invoice: inv)
                    .animate()
                    .fadeIn(delay: 260.ms, duration: 350.ms),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceSummaryCard extends StatelessWidget {
  const _BalanceSummaryCard({required this.invoice, required this.fmt});
  final InvoiceModel invoice;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final progress = invoice.finalAmount > 0
        ? (invoice.totalPaid / invoice.finalAmount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SALDO PENDIENTE',
                    style: AppTypography.tag.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fmt.format(invoice.balance < 0 ? 0 : invoice.balance),
                    style: AppTypography.moneyLarge.copyWith(color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'pagado',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(
                invoice.balance <= 0.01 ? AppColors.successLight : Colors.white,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _AmountPill(
                label: 'Valor final',
                value: fmt.format(invoice.finalAmount),
              ),
              const SizedBox(width: 10),
              _AmountPill(
                label: 'Pagado',
                value: fmt.format(invoice.totalPaid),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountPill extends StatelessWidget {
  const _AmountPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NovedadBadge extends StatelessWidget {
  const _NovedadBadge({required this.invoice, required this.fmt});
  final InvoiceModel invoice;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    if (invoice.novedadType == NovedadType.desc && invoice.discount != null) {
      final disc = invoice.discount!;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warningSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.discount_shape, size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  'Descuento aplicado',
                  style: AppTypography.textTheme.titleMedium
                      ?.copyWith(color: AppColors.warningLight),
                ),
                const Spacer(),
                Text(
                  '− ${fmt.format(disc.totalDiscount)}',
                  style: AppTypography.textTheme.labelLarge
                      ?.copyWith(color: AppColors.warningLight),
                ),
              ],
            ),
            if (disc.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...disc.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Iconsax.box, size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${item.product} (x${item.quantity.toStringAsFixed(0)})',
                          style: AppTypography.caption,
                        ),
                      ),
                      Text(
                        '− ${fmt.format(item.lineDiscount)}',
                        style: AppTypography.caption.copyWith(color: AppColors.warning),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (invoice.novedadType == NovedadType.other) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.purpleSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Iconsax.info_circle, size: 16, color: AppColors.purple),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                invoice.novedadText ?? 'Novedad personalizada',
                style: AppTypography.textTheme.bodySmall
                    ?.copyWith(color: AppColors.purpleLight),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTypography.tag.copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.textTheme.bodyMedium),
          Flexible(
            child: Text(
              value,
              style: AppTypography.textTheme.titleSmall?.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.invoice});
  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (invoice.status != InvoiceStatus.paid &&
            invoice.status != InvoiceStatus.rejected) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await RegisterPaymentSheet.show(
                  context,
                  invoiceId: invoice.id,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              icon: const Icon(Iconsax.money_send, size: 18),
              label: Text(
                invoice.paymentCount == 0 ? 'Registrar Pago' : 'Registrar Abono',
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Iconsax.document_download, size: 18),
            label: const Text('Descargar PDF'),
          ),
        ),
        if (invoice.status == InvoiceStatus.pending ||
            invoice.status == InvoiceStatus.overdue) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Iconsax.close_circle, size: 18),
              label: const Text('Rechazar Factura'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
