import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/store/invoice_store.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/expandable_fab.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../widgets/invoice_card.dart';
import '../widgets/register_payment_sheet.dart';
import '../widgets/register_invoice_sheet.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  InvoiceStatus? _filter;
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    InvoiceStore.instance.addListener(_onStoreUpdate);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _loading = false);
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

  List<InvoiceModel> get _filtered {
    return InvoiceStore.instance.invoices.where((inv) {
      final matchStatus = _filter == null || inv.status == _filter;
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
          inv.supplierName.toLowerCase().contains(q) ||
          inv.invoiceNumber.toLowerCase().contains(q);
      return matchStatus && matchSearch;
    }).toList();
  }

  Future<void> _showPaymentSheet() async {
    await RegisterPaymentSheet.show(context);
    // Store notifies → _onStoreUpdate rebuilds
  }

  Future<void> _showInvoiceSheet() async {
    await RegisterInvoiceSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final isSuperadmin = AuthService.instance.isSuperadmin;
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: CustomScrollView(
        slivers: [
          _InvoicesAppBar(
            onSearch: (v) => setState(() => _search = v),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: _FilterChips(
                selected: _filter,
                onSelected: (s) => setState(() => _filter = s == _filter ? null : s),
              ),
            ),
          ),
          if (_loading)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const SkeletonInvoiceCard(),
                  childCount: 5,
                ),
              ),
            )
          else if (_filtered.isEmpty)
            SliverFillRemaining(
              child: EmptyStateWidget(
                icon: Iconsax.document_text,
                title: 'Sin facturas',
                subtitle: 'No hay facturas que coincidan con tu búsqueda',
                actionLabel: isSuperadmin ? null : 'Registrar factura',
                onAction: isSuperadmin ? null : _showInvoiceSheet,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => InvoiceCard(invoice: _filtered[i], index: i),
                  childCount: _filtered.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: isSuperadmin
          ? null
          : ExpandableFab(
              onRegisterPayment: _showPaymentSheet,
              onRegisterInvoice: _showInvoiceSheet,
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
    );
  }
}

class _InvoicesAppBar extends StatelessWidget {
  const _InvoicesAppBar({required this.onSearch});
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.scaffold,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Facturas', style: AppTypography.textTheme.headlineLarge),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Iconsax.filter, size: 20),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  onChanged: onSearch,
                  style: AppTypography.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por proveedor o número...',
                    prefixIcon: Icon(Iconsax.search_normal, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});
  final InvoiceStatus? selected;
  final ValueChanged<InvoiceStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = [
      (InvoiceStatus.pending, 'Pendientes'),
      (InvoiceStatus.partial, 'Parciales'),
      (InvoiceStatus.overdue, 'Vencidas'),
      (InvoiceStatus.paid, 'Pagadas'),
      (InvoiceStatus.rejected, 'Rechazadas'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((entry) {
          final (status, label) = entry;
          final isSelected = selected == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onSelected(status),
              selectedColor: status.surfaceColor,
              checkmarkColor: status.color,
              labelStyle: AppTypography.textTheme.labelMedium?.copyWith(
                color: isSelected ? status.color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
              side: BorderSide(
                color: isSelected ? status.color.withValues(alpha: 0.4) : AppColors.border,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
