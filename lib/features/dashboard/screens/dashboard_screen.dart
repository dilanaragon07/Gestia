import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/store/invoice_store.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../shared/navigation/app_shell.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../widgets/stat_card_widget.dart';
import '../widgets/monthly_chart_widget.dart';
import '../widgets/recent_invoices_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    InvoiceStore.instance.addListener(_onStoreUpdate);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    InvoiceStore.instance.removeListener(_onStoreUpdate);
    super.dispose();
  }

  void _onStoreUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: _loading
          ? const SkeletonDashboard()
          : _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _DashboardAppBar(),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),
              _OverdueAlert(),
              const SizedBox(height: 20),
              _StatsGrid(),
              const SizedBox(height: 24),
              const MonthlyChartWidget(),
              const SizedBox(height: 24),
              const RecentInvoicesWidget(),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}

class _DashboardAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFmt = DateFormat('EEEE, d MMMM', 'es');
    final hour = now.hour;
    final greeting = hour < 12 ? 'Buenos días' : hour < 18 ? 'Buenas tardes' : 'Buenas noches';
    final displayName = AuthService.instance.profile?.displayName ?? 'Usuario';

    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.scaffold,
      expandedHeight: 80,
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
                      Text(
                        greeting,
                        style: AppTypography.textTheme.bodyMedium,
                      )
                          .animate()
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: 2),
                      Text(
                        displayName,
                        style: AppTypography.textTheme.headlineMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                          .animate()
                          .fadeIn(delay: 80.ms, duration: 400.ms)
                          .slideX(begin: -0.05),
                      Text(
                        dateFmt.format(now),
                        style: AppTypography.caption,
                      )
                          .animate()
                          .fadeIn(delay: 120.ms, duration: 400.ms),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Notifications
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Iconsax.notification, size: 22),
                          color: AppColors.textSecondary,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    // Avatar
                    GestureDetector(
                      onTap: () => AppShell.scaffoldKey.currentState?.openDrawer(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            AuthService.instance.profile?.initials ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverdueAlert extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final overdue = InvoiceStore.instance.overdueInvoices;
    if (overdue.isEmpty) return const SizedBox.shrink();

    final first = overdue.first;
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final label = overdue.length == 1
        ? '1 factura vencida '
        : '${overdue.length} facturas vencidas ';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.warning_2, size: 18, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.errorLight),
                children: [
                  TextSpan(
                    text: label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: '— ${first.supplierName} · ${fmt.format(first.balance)}',
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/invoices'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Ver'),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 50.ms, duration: 400.ms)
        .slideX(begin: -0.05);
  }
}

class _StatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final store = InvoiceStore.instance;
    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = ((constraints.maxWidth - 12) / 2) / 128;
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: ratio,
          children: [
            StatCardWidget(
              label: 'Total por Pagar',
              amount: store.totalPayable,
              icon: Iconsax.dollar_circle,
              iconColor: AppColors.primary,
              gradient: AppColors.cardGlowBlue,
              change: 12.4,
              isPositiveChange: false,
              animDelay: 100,
            ),
            StatCardWidget(
              label: 'Facturas Vencidas',
              amount: store.totalOverdue,
              icon: Iconsax.clock,
              iconColor: AppColors.error,
              gradient: AppColors.cardGlowRed,
              subtitle: '${store.overdueInvoices.length} facturas',
              animDelay: 160,
            ),
            StatCardWidget(
              label: 'Pagado este Mes',
              amount: store.paidThisMonth,
              icon: Iconsax.tick_circle,
              iconColor: AppColors.success,
              gradient: AppColors.cardGlowGreen,
              change: 10.2,
              isPositiveChange: true,
              animDelay: 220,
            ),
            StatCardWidget(
              label: 'Pendientes',
              amount: store.pendingInvoices.fold(0.0, (s, i) => s + i.balance),
              icon: Iconsax.document_like,
              iconColor: AppColors.warning,
              gradient: AppColors.cardGlowAmber,
              subtitle: '${store.pendingInvoices.length} facturas',
              animDelay: 280,
            ),
          ],
        );
      },
    );
  }
}
