import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/supplier_model.dart';
import '../../../data/store/invoice_store.dart';
import '../../../features/invoices/screens/payment_receipt_sheet.dart';
import '../../../shared/widgets/empty_state_widget.dart';

typedef _Entry = ({PaymentModel payment, InvoiceModel invoice});

class PaymentsHistoryScreen extends StatefulWidget {
  const PaymentsHistoryScreen({super.key, this.supplierId});

  final String? supplierId;

  @override
  State<PaymentsHistoryScreen> createState() => _PaymentsHistoryScreenState();
}

class _PaymentsHistoryScreenState extends State<PaymentsHistoryScreen> {
  String? _selectedSupplierId;

  @override
  void initState() {
    super.initState();
    _selectedSupplierId = widget.supplierId;
    InvoiceStore.instance.addListener(_onUpdate);
    if (InvoiceStore.instance.invoices.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) InvoiceStore.instance.loadAll();
      });
    }
  }

  @override
  void dispose() {
    InvoiceStore.instance.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  List<_Entry> get _entries {
    final all = InvoiceStore.instance.invoices
        .expand((inv) => inv.payments.map((p) => (payment: p, invoice: inv)))
        .where((e) =>
            _selectedSupplierId == null ||
            e.invoice.supplierId == _selectedSupplierId)
        .toList()
      ..sort((a, b) =>
          b.payment.paymentDate.compareTo(a.payment.paymentDate));
    return all;
  }

  List<SupplierModel> get _suppliersWithPayments {
    final ids = InvoiceStore.instance.invoices
        .where((i) => i.payments.isNotEmpty)
        .map((i) => i.supplierId)
        .toSet();
    return InvoiceStore.instance.suppliers
        .where((s) => ids.contains(s.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final entries = _entries;
    final total = entries.fold<double>(0, (s, e) => s + e.payment.amount);
    final suppliers = _suppliersWithPayments;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.scaffold,
            pinned: true,
            title: Text('Historial de Pagos', style: AppTypography.textTheme.titleLarge),
            automaticallyImplyLeading: true,
          ),

          // Supplier filter chips
          if (suppliers.isNotEmpty)
            SliverToBoxAdapter(
              child: _SupplierFilter(
                suppliers: suppliers,
                selectedId: _selectedSupplierId,
                onSelect: (id) => setState(() => _selectedSupplierId = id),
              ),
            ),

          // Summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  _SummaryChip(
                    label: 'Pagos',
                    value: '${entries.length}',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  _SummaryChip(
                    label: 'Total pagado',
                    value: fmt.format(total),
                    color: AppColors.success,
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          if (InvoiceStore.instance.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (entries.isEmpty)
            SliverFillRemaining(
              child: EmptyStateWidget(
                icon: Iconsax.receipt,
                title: 'Sin pagos',
                subtitle: _selectedSupplierId != null
                    ? 'No hay pagos para este proveedor'
                    : 'No hay pagos registrados',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _PaymentEntryCard(
                    entry: entries[i],
                    index: i,
                    fmt: fmt,
                  ),
                  childCount: entries.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _SupplierFilter extends StatelessWidget {
  const _SupplierFilter({
    required this.suppliers,
    required this.selectedId,
    required this.onSelect,
  });

  final List<SupplierModel> suppliers;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _FilterChip(
            label: 'Todos',
            isSelected: selectedId == null,
            color: AppColors.primary,
            onTap: () => onSelect(null),
          ),
          ...suppliers.map((s) => _FilterChip(
                label: s.name,
                isSelected: selectedId == s.id,
                color: s.avatarColor,
                onTap: () => onSelect(s.id),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.5) : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.tag.copyWith(
            color: isSelected ? color : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTypography.caption,
          ),
          Text(
            value,
            style: AppTypography.textTheme.labelLarge?.copyWith(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentEntryCard extends StatelessWidget {
  const _PaymentEntryCard({
    required this.entry,
    required this.index,
    required this.fmt,
  });

  final _Entry entry;
  final int index;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final payment = entry.payment;
    final invoice = entry.invoice;
    final dateFmt = DateFormat('dd/MM/yyyy', 'es_CO');
    final hasEvidence = payment.evidenceUrl != null ||
        (payment.evidencePath != null && File(payment.evidencePath!).existsSync());

    return GestureDetector(
      onTap: () => PaymentReceiptSheet.show(
        context,
        payment: payment,
        invoice: invoice,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Supplier avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (invoice.supplierColor ?? AppColors.primary)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(11),
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

            // Middle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.supplierName,
                    style: AppTypography.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(payment.method.icon,
                          size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(payment.method.label, style: AppTypography.caption),
                      const SizedBox(width: 8),
                      Text('·', style: AppTypography.caption),
                      const SizedBox(width: 8),
                      Text(
                        invoice.invoiceNumber,
                        style: AppTypography.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right: amount + date + evidence
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmt.format(payment.amount),
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasEvidence) ...[
                      const Icon(Iconsax.camera,
                          size: 11, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      dateFmt.format(payment.paymentDate),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 50), duration: 300.ms)
        .slideY(begin: 0.06);
  }
}
