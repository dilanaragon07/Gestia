import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/chart_data_model.dart';
import '../../../data/repositories/reports_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedPeriod = 2;
  final _periods = ['Sem.', 'Mes', '3M', '6M', 'Año'];
  late TabController _tabCtrl;
  final _repo = ReportsRepository();
  late Future<List<MonthlyChartData>> _flowFuture;
  late Future<List<CategoryData>> _catFuture;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _flowFuture = _repo.getMonthlyFlow();
    _catFuture = _repo.getCategoryBreakdown();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            backgroundColor: AppColors.scaffold,
            pinned: true,
            title: Text('Reportes', style: AppTypography.textTheme.headlineLarge),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Iconsax.document_download, size: 20),
                color: AppColors.textSecondary,
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Iconsax.share, size: 20),
                color: AppColors.textSecondary,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TabBar(
                  controller: _tabCtrl,
                  tabs: const [
                    Tab(text: 'Pagos'),
                    Tab(text: 'Categorías'),
                  ],
                ),
              ),
            ),
          ),

          SliverFillRemaining(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _PaymentsTab(fmt: fmt, selectedPeriod: _selectedPeriod, onPeriod: (i) => setState(() => _selectedPeriod = i), periods: _periods, flowFuture: _flowFuture),
                _CategoriesTab(fmt: fmt, catFuture: _catFuture),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab({
    required this.fmt,
    required this.selectedPeriod,
    required this.onPeriod,
    required this.periods,
    required this.flowFuture,
  });
  final NumberFormat fmt;
  final int selectedPeriod;
  final ValueChanged<int> onPeriod;
  final List<String> periods;
  final Future<List<MonthlyChartData>> flowFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MonthlyChartData>>(
      future: flowFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        return _PaymentsContent(
          fmt: fmt,
          selectedPeriod: selectedPeriod,
          onPeriod: onPeriod,
          periods: periods,
          data: data,
        );
      },
    );
  }
}

class _PaymentsContent extends StatelessWidget {
  const _PaymentsContent({
    required this.fmt,
    required this.selectedPeriod,
    required this.onPeriod,
    required this.periods,
    required this.data,
  });
  final NumberFormat fmt;
  final int selectedPeriod;
  final ValueChanged<int> onPeriod;
  final List<String> periods;
  final List<MonthlyChartData> data;

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (s, d) => s + d.paid);
    final totalPending = data.fold<double>(0, (s, d) => s + d.pending);
    final maxPaid = data.isEmpty ? 1.0 : data.map((d) => d.paid).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: List.generate(periods.length, (i) {
                final active = i == selectedPeriod;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onPeriod(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(
                        child: Text(
                          periods[i],
                          style: AppTypography.textTheme.labelMedium?.copyWith(
                            color: active ? Colors.white : AppColors.textTertiary,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ).animate().fadeIn(duration: 350.ms),

          const SizedBox(height: 20),

          // KPI row
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: 'Total Pagado',
                  value: fmt.format(total),
                  change: '+10.2%',
                  isPositive: true,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  label: 'Pendiente',
                  value: fmt.format(totalPending),
                  change: '+5.8%',
                  isPositive: false,
                  color: AppColors.warning,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 80.ms, duration: 350.ms),

          const SizedBox(height: 20),

          // Line chart
          _LineChartCard(data: data)
              .animate()
              .fadeIn(delay: 160.ms, duration: 400.ms),

          const SizedBox(height: 20),

          // Monthly table
          Text('Detalle Mensual', style: AppTypography.textTheme.titleLarge)
              .animate()
              .fadeIn(delay: 240.ms),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(data.length, (i) {
                final d = data[i];
                final isLast = i == data.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(d.month, style: AppTypography.textTheme.labelMedium),
                          ),
                          Expanded(
                            child: _MiniProgressBar(
                              paid: d.paid,
                              max: maxPaid,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 80,
                            child: Text(
                              fmt.format(d.paid),
                              style: AppTypography.textTheme.labelLarge?.copyWith(fontSize: 12),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                );
              }),
            ),
          )
              .animate()
              .fadeIn(delay: 280.ms, duration: 350.ms),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab({required this.fmt, required this.catFuture});
  final NumberFormat fmt;
  final Future<List<CategoryData>> catFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryData>>(
      future: catFuture,
      builder: (context, snapshot) {
        final cats = snapshot.data ?? [];
        return _CategoriesContent(fmt: fmt, cats: cats);
      },
    );
  }
}

class _CategoriesContent extends StatelessWidget {
  const _CategoriesContent({required this.fmt, required this.cats});
  final NumberFormat fmt;
  final List<CategoryData> cats;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pie chart
          _PieChartCard(categories: cats)
              .animate()
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 20),

          Text('Por Categoría', style: AppTypography.textTheme.titleLarge)
              .animate()
              .fadeIn(delay: 150.ms),
          const SizedBox(height: 12),

          ...List.generate(cats.length, (i) {
            final c = cats[i];
            final colors = [
              AppColors.primary,
              AppColors.success,
              AppColors.warning,
              AppColors.purple,
              AppColors.error,
            ];
            final color = colors[i % colors.length];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.category, style: AppTypography.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: c.percentage / 100,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        fmt.format(c.amount),
                        style: AppTypography.textTheme.labelLarge,
                      ),
                      Text(
                        '${c.percentage.toStringAsFixed(1)}%',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 200 + i * 60), duration: 350.ms);
          }),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.color,
  });
  final String label;
  final String value;
  final String change;
  final bool isPositive;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.moneySmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              change,
              style: AppTypography.tag.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartCard extends StatelessWidget {
  const _LineChartCard({required this.data});
  final List<MonthlyChartData> data;

  @override
  Widget build(BuildContext context) {
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
          Text('Tendencia de Pagos', style: AppTypography.textTheme.titleLarge),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
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
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(data.length, (i) {
                      return FlSpot(i.toDouble(), data[i].paid / 1000);
                    }),
                    isCurved: true,
                    color: AppColors.success,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.success.withValues(alpha: 0.15),
                          AppColors.success.withValues(alpha: 0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: List.generate(data.length, (i) {
                      return FlSpot(i.toDouble(), data[i].pending / 1000);
                    }),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.1),
                          AppColors.primary.withValues(alpha: 0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                minY: 0,
              ),
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniProgressBar extends StatelessWidget {
  const _MiniProgressBar({required this.paid, required this.max});
  final double paid;
  final double max;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: paid / max,
        backgroundColor: AppColors.border,
        valueColor: const AlwaysStoppedAnimation(AppColors.success),
        minHeight: 6,
      ),
    );
  }
}

class _PieChartCard extends StatelessWidget {
  const _PieChartCard({required this.categories});
  final List<CategoryData> categories;

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.purple,
      AppColors.error,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text('Distribución por Categoría', style: AppTypography.textTheme.titleLarge),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: List.generate(categories.length, (i) {
                  final c = categories[i];
                  return PieChartSectionData(
                    value: c.percentage,
                    color: colors[i % colors.length],
                    radius: 60,
                    showTitle: false,
                  );
                }),
                sectionsSpace: 3,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: List.generate(categories.length, (i) {
              final c = categories[i];
              final color = colors[i % colors.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${c.category} ${c.percentage.toStringAsFixed(1)}%',
                    style: AppTypography.caption,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
