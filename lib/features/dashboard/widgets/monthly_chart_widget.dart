import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/chart_data_model.dart';
import '../../../data/repositories/reports_repository.dart';

class MonthlyChartWidget extends StatefulWidget {
  const MonthlyChartWidget({super.key});

  @override
  State<MonthlyChartWidget> createState() => _MonthlyChartWidgetState();
}

class _MonthlyChartWidgetState extends State<MonthlyChartWidget> {
  final _repo = ReportsRepository();
  late Future<List<MonthlyChartData>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getMonthlyFlow();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MonthlyChartData>>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        return _ChartCard(data: data);
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.data});
  final List<MonthlyChartData> data;

  @override
  Widget build(BuildContext context) {
    final maxY = data.isEmpty
        ? 100000.0
        : data.fold<double>(0, (m, d) => [d.paid, d.pending, d.overdue].fold(m, (a, v) => v > a ? v : a));
    final axisMax = (maxY * 1.2).ceilToDouble().clamp(10000.0, double.infinity);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
              Expanded(
                child: Text('Flujo Mensual', style: AppTypography.textTheme.titleLarge),
              ),
              _Legend(),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: data.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: axisMax,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.cardElevated,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final k = (rod.toY / 1000).toStringAsFixed(0);
                            return BarTooltipItem(
                              '\$$k k',
                              AppTypography.textTheme.labelLarge!.copyWith(color: rod.color),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= data.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(data[index].month, style: AppTypography.caption),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            getTitlesWidget: (value, meta) {
                              if (value == 0 || value == axisMax) return const SizedBox();
                              final k = (value / 1000).toInt();
                              return Text('\$$k k', style: AppTypography.caption);
                            },
                            interval: axisMax / 4,
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: axisMax / 4,
                        getDrawingHorizontalLine: (_) => FlLine(color: AppColors.divider, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(data.length, (i) {
                        final d = data[i];
                        return BarChartGroupData(
                          x: i,
                          groupVertically: false,
                          barsSpace: 3,
                          barRods: [
                            BarChartRodData(
                              toY: d.paid,
                              color: AppColors.success,
                              width: 8,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: d.pending,
                              color: AppColors.primary,
                              width: 8,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: d.overdue,
                              color: AppColors.error,
                              width: 8,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }),
                    ),
                    duration: 600.ms,
                    curve: Curves.easeOutCubic,
                  ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 350.ms, duration: 400.ms)
        .slideY(begin: 0.1);
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Dot(color: AppColors.success, label: 'Pagado'),
        const SizedBox(width: 10),
        _Dot(color: AppColors.primary, label: 'Pendiente'),
        const SizedBox(width: 10),
        _Dot(color: AppColors.error, label: 'Vencido'),
      ],
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
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
