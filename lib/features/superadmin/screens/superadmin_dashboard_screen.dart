import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/debt_model.dart';
import '../../../data/models/supplier_model.dart';
import '../../../data/repositories/superadmin_repository.dart';
import '../../../data/store/invoice_store.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class SuperadminDashboardScreen extends StatefulWidget {
  const SuperadminDashboardScreen({super.key, this.onOpenDrawer});
  final VoidCallback? onOpenDrawer;

  @override
  State<SuperadminDashboardScreen> createState() => _SuperadminDashboardScreenState();
}

class _SuperadminDashboardScreenState extends State<SuperadminDashboardScreen> {
  final _repo = SuperadminRepository();

  late Future<AdminStats> _statsFuture;
  late Future<List<DebtEvolutionData>> _evolutionFuture;

  SupplierModel? _selectedSupplier;
  Future<List<InvoiceDebtPoint>>? _supplierTimelineFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _repo.getAdminStats();
    _evolutionFuture = _repo.getDebtEvolution();
    InvoiceStore.instance.addListener(_onStoreUpdate);
  }

  @override
  void dispose() {
    InvoiceStore.instance.removeListener(_onStoreUpdate);
    super.dispose();
  }

  void _onStoreUpdate() {
    if (mounted) setState(() {});
  }

  void _selectSupplier(SupplierModel? s) {
    setState(() {
      _selectedSupplier = s;
      _supplierTimelineFuture =
          s == null ? null : _repo.getSupplierDebtTimeline(s.id);
    });
  }

  void _refresh() {
    setState(() {
      _statsFuture = _repo.getAdminStats();
      _evolutionFuture = _repo.getDebtEvolution();
      if (_selectedSupplier != null) {
        _supplierTimelineFuture =
            _repo.getSupplierDebtTimeline(_selectedSupplier!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: CustomScrollView(
        slivers: [
          _AppBar(onRefresh: _refresh, onOpenDrawer: widget.onOpenDrawer),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                _StatsSection(future: _statsFuture),
                const SizedBox(height: 24),
                _DebtEvolutionCard(future: _evolutionFuture),
                const SizedBox(height: 24),
                _SupplierDebtSection(
                  selectedSupplier: _selectedSupplier,
                  suppliers: InvoiceStore.instance.suppliers,
                  timelineFuture: _supplierTimelineFuture,
                  onSupplierSelected: _selectSupplier,
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── App Bar ─────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  const _AppBar({required this.onRefresh, this.onOpenDrawer});
  final VoidCallback onRefresh;
  final VoidCallback? onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.scaffold,
      expandedHeight: 72,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Panel General', style: AppTypography.textTheme.headlineMedium)
                          .animate().fadeIn(duration: 400.ms),
                      Text('Superadmin', style: AppTypography.caption)
                          .animate().fadeIn(delay: 80.ms, duration: 400.ms),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Iconsax.refresh, size: 20),
                  color: AppColors.textSecondary,
                ),
                GestureDetector(
                  onTap: () => onOpenDrawer?.call(),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('SA',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
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

// ─── Stats Section ────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.future});
  final Future<AdminStats> future;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = ((constraints.maxWidth - 12) / 2) / 110;
        return FutureBuilder<AdminStats>(
          future: future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: ratio,
                children: List.generate(4, (_) => const SkeletonCard()),
              );
            }
            final s = snap.data!;
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: ratio,
              children: [
                _StatCard(
                  label: 'Total Deuda',
                  value: fmt.format(s.totalDebt),
                  icon: Iconsax.dollar_circle,
                  color: AppColors.error,
                  delay: 0,
                ),
                _StatCard(
                  label: 'Pagado este Mes',
                  value: fmt.format(s.paidThisMonth),
                  icon: Iconsax.tick_circle,
                  color: AppColors.success,
                  delay: 60,
                ),
                _StatCard(
                  label: 'Usuarios Activos',
                  value: '${s.activeUsers}',
                  icon: Iconsax.people,
                  color: AppColors.primary,
                  delay: 120,
                  isMoney: false,
                ),
                _StatCard(
                  label: 'Proveedores',
                  value: '${s.supplierCount}',
                  icon: Iconsax.building,
                  color: AppColors.purple,
                  delay: 180,
                  isMoney: false,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
    this.isMoney = true,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;
  final bool isMoney;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: isMoney
                    ? AppTypography.moneySmall
                    : AppTypography.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(label, style: AppTypography.caption),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 350.ms)
        .slideY(begin: 0.1);
  }
}

// ─── Debt Evolution Chart ─────────────────────────────────────────────────────

class _DebtEvolutionCard extends StatelessWidget {
  const _DebtEvolutionCard({required this.future});
  final Future<List<DebtEvolutionData>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DebtEvolutionData>>(
      future: future,
      builder: (context, snap) {
        final data = snap.data ?? [];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Evolución de Deuda', style: AppTypography.textTheme.titleLarge),
                  Row(
                    children: [
                      _Dot(color: AppColors.error, label: 'Deuda'),
                      const SizedBox(width: 10),
                      _Dot(color: AppColors.success, label: 'Pagado'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 160,
                child: data.isEmpty
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : _buildChart(data),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 250.ms, duration: 400.ms)
            .slideY(begin: 0.1);
      },
    );
  }

  Widget _buildChart(List<DebtEvolutionData> data) {
    final maxVal = data.fold<double>(
        0, (m, d) => [d.newDebt, d.paymentsMade].fold(m, (a, v) => v > a ? v : a));
    final axisMax = (maxVal * 1.25).clamp(10000.0, double.infinity);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: data.length > 6 ? 2 : 1,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(data[i].month, style: AppTypography.caption),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: axisMax,
        lineBarsData: [
          // New debt
          LineChartBarData(
            spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].newDebt)),
            isCurved: true,
            color: AppColors.error,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [AppColors.error.withValues(alpha: 0.12), AppColors.error.withValues(alpha: 0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Payments
          LineChartBarData(
            spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].paymentsMade)),
            isCurved: true,
            color: AppColors.success,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [AppColors.success.withValues(alpha: 0.12), AppColors.success.withValues(alpha: 0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: 500.ms,
      curve: Curves.easeOutCubic,
    );
  }
}

// ─── Supplier Debt Section ────────────────────────────────────────────────────

class _SupplierDebtSection extends StatelessWidget {
  const _SupplierDebtSection({
    required this.selectedSupplier,
    required this.suppliers,
    required this.timelineFuture,
    required this.onSupplierSelected,
  });
  final SupplierModel? selectedSupplier;
  final List<SupplierModel> suppliers;
  final Future<List<InvoiceDebtPoint>>? timelineFuture;
  final ValueChanged<SupplierModel?> onSupplierSelected;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deuda por Proveedor', style: AppTypography.textTheme.titleLarge),
          const SizedBox(height: 16),
          // Supplier selector
          DropdownButtonFormField<SupplierModel>(
            initialValue: selectedSupplier,
            hint: const Text('Selecciona un proveedor'),
            dropdownColor: AppColors.cardElevated,
            decoration: InputDecoration(
              prefixIcon: const Icon(Iconsax.building, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            items: suppliers
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.name, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: onSupplierSelected,
          ),
          if (selectedSupplier != null && timelineFuture != null) ...[
            const SizedBox(height: 20),
            FutureBuilder<List<InvoiceDebtPoint>>(
              future: timelineFuture,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final points = snap.data!;
                if (points.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text('Sin facturas para este proveedor', style: AppTypography.caption),
                    ),
                  );
                }
                return _SupplierChart(
                  points: points,
                  supplier: selectedSupplier!,
                  fmt: fmt,
                );
              },
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 350.ms, duration: 400.ms)
        .slideY(begin: 0.1);
  }
}

class _SupplierChart extends StatelessWidget {
  const _SupplierChart({
    required this.points,
    required this.supplier,
    required this.fmt,
  });
  final List<InvoiceDebtPoint> points;
  final SupplierModel supplier;
  final NumberFormat fmt;

  Color _colorForStatus(String status) => switch (status) {
        'paid' => AppColors.success,
        'overdue' => AppColors.error,
        'partial' => AppColors.warning,
        _ => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    final totalDebt = points.fold<double>(0, (s, p) => s + p.balance);
    final totalAmount = points.fold<double>(0, (s, p) => s + p.finalAmount);
    final maxBalance = points.fold<double>(0, (m, p) => p.finalAmount > m ? p.finalAmount : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary row
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: 'Total Facturas',
                value: fmt.format(totalAmount),
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStat(
                label: 'Saldo Pendiente',
                value: fmt.format(totalDebt),
                color: totalDebt > 0 ? AppColors.error : AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStat(
                label: 'Facturas',
                value: '${points.length}',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Bar chart
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxBalance * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.cardElevated,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final p = points[group.x];
                    return BarTooltipItem(
                      '${p.invoiceNumber}\n${fmt.format(p.balance)}',
                      AppTypography.textTheme.labelSmall!.copyWith(color: rod.color),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i >= points.length) return const SizedBox();
                      final d = points[i].issueDate;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${d.month}/${d.year.toString().substring(2)}',
                          style: AppTypography.caption.copyWith(fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(points.length, (i) {
                final p = points[i];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: p.balance > 0 ? p.balance : p.finalAmount * 0.02,
                      color: _colorForStatus(p.status),
                      width: points.length <= 6 ? 20 : points.length <= 10 ? 14 : 8,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }),
            ),
            duration: 500.ms,
            curve: Curves.easeOutCubic,
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _Dot(color: AppColors.primary, label: 'Pendiente'),
            _Dot(color: AppColors.warning, label: 'Parcial'),
            _Dot(color: AppColors.error, label: 'Vencida'),
            _Dot(color: AppColors.success, label: 'Pagada'),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTypography.textTheme.labelLarge?.copyWith(color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
