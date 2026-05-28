import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/supplier_model.dart';
import '../../../data/store/invoice_store.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../widgets/supplier_card.dart';
import 'supplier_form_sheet.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    InvoiceStore.instance.addListener(_onStoreUpdate);
    InvoiceStore.instance.loadSuppliers();
  }

  @override
  void dispose() {
    InvoiceStore.instance.removeListener(_onStoreUpdate);
    super.dispose();
  }

  void _onStoreUpdate() {
    if (mounted) setState(() {});
  }

  List<SupplierModel> get _filtered {
    final q = _search.toLowerCase();
    return InvoiceStore.instance.suppliers.where((s) {
      return q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q) ||
          s.contactName.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _showAddSupplier() async {
    final created = await SupplierFormSheet.show(context);
    if (created == true) {
      await InvoiceStore.instance.loadSuppliers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final suppliers = InvoiceStore.instance.suppliers;
    final activeCount = suppliers.where((s) => s.isActive).length;
    final totalPending = suppliers.fold<double>(0, (s, x) => s + x.pendingAmount);
    final isSuperadmin = AuthService.instance.isSuperadmin;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.scaffold,
            expandedHeight: 130,
            floating: true,
            snap: true,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Proveedores', style: AppTypography.textTheme.headlineLarge),
                      const SizedBox(height: 10),
                      Autocomplete<SupplierModel>(
                        displayStringForOption: (s) => s.name,
                        optionsBuilder: (TextEditingValue v) {
                          if (v.text.isEmpty) return const [];
                          final q = v.text.toLowerCase();
                          return InvoiceStore.instance.suppliers.where((s) =>
                            s.name.toLowerCase().contains(q) ||
                            s.category.toLowerCase().contains(q) ||
                            s.contactName.toLowerCase().contains(q),
                          );
                        },
                        onSelected: (SupplierModel s) {
                          setState(() => _search = s.name);
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: (v) => setState(() => _search = v),
                            style: AppTypography.textTheme.bodyLarge,
                            decoration: const InputDecoration(
                              hintText: 'Buscar proveedor...',
                              prefixIcon: Icon(Iconsax.search_normal, size: 18),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          final w = MediaQuery.of(context).size.width - 40;
                          return Align(
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                              width: w,
                              child: Material(
                              elevation: 8,
                              color: AppColors.cardElevated,
                              borderRadius: BorderRadius.circular(14),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 260),
                                child: ListView(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  shrinkWrap: true,
                                  children: options.map((s) {
                                    return InkWell(
                                      onTap: () => onSelected(s),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 34, height: 34,
                                              decoration: BoxDecoration(
                                                color: s.avatarColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(9),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  s.initials,
                                                  style: TextStyle(
                                                    color: s.avatarColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(s.name, style: AppTypography.textTheme.titleSmall),
                                                  Text(s.category, style: AppTypography.caption),
                                                ],
                                              ),
                                            ),
                                            const Icon(Iconsax.arrow_right_3, size: 14, color: AppColors.textDisabled),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Activos',
                      value: '$activeCount',
                      icon: Iconsax.building,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Por pagar',
                      value: fmt.format(totalPending),
                      icon: Iconsax.dollar_circle,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Total',
                      value: '${suppliers.length}',
                      icon: Iconsax.people,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          if (_filtered.isEmpty)
            SliverFillRemaining(
              child: EmptyStateWidget(
                icon: Iconsax.building,
                title: 'Sin proveedores',
                subtitle: 'No encontramos proveedores con esa búsqueda',
                actionLabel: isSuperadmin ? 'Agregar proveedor' : null,
                onAction: isSuperadmin ? _showAddSupplier : null,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => SupplierCard(
                    supplier: _filtered[i],
                    index: i,
                    onPaymentsTap: () => context.push('/payments?supplierId=${_filtered[i].id}'),
                  ),
                  childCount: _filtered.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: isSuperadmin
          ? FloatingActionButton.extended(
              onPressed: _showAddSupplier,
              icon: const Icon(Iconsax.add),
              label: const Text('Agregar'),
            ).animate().fadeIn(delay: 400.ms)
          : null,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}
