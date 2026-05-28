import 'package:flutter/material.dart';
import '../../../shared/navigation/app_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/store/invoice_store.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../features/payments/screens/payments_history_screen.dart';
import '../../../features/suppliers/screens/suppliers_screen.dart';
import 'superadmin_dashboard_screen.dart';
import 'users_screen.dart';

class SuperadminShell extends StatefulWidget {
  const SuperadminShell({super.key});

  @override
  State<SuperadminShell> createState() => _SuperadminShellState();
}

class _SuperadminShellState extends State<SuperadminShell> {
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    InvoiceStore.instance.loadSuppliers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.scaffold,
      body: IndexedStack(
        index: _index,
        children: [
          SuperadminDashboardScreen(
            onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const UsersScreen(),
          const SuppliersScreen(),
          const PaymentsHistoryScreen(),
        ],
      ),
      drawer: _SuperadminDrawer(
        currentIndex: _index,
        onNavTap: (i) {
          Navigator.of(context).pop();
          setState(() => _index = i);
        },
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Iconsax.chart_square, Iconsax.chart_square, 'Dashboard'),
      (Iconsax.people, Iconsax.people, 'Usuarios'),
      (Iconsax.building, Iconsax.building_4, 'Proveedores'),
      (Iconsax.receipt, Iconsax.receipt_2, 'Pagos'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(items.length, (i) {
              final (icon, activeIcon, label) = items[i];
              final isActive = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primaryMuted : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isActive ? activeIcon : icon,
                          size: 22,
                          color: isActive ? AppColors.primaryLight : AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: AppTypography.tag.copyWith(
                          color: isActive ? AppColors.primaryLight : AppColors.textTertiary,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                        ),
                        child: Text(label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _SuperadminDrawer extends StatelessWidget {
  const _SuperadminDrawer({required this.currentIndex, required this.onNavTap});
  final int currentIndex;
  final ValueChanged<int> onNavTap;

  @override
  Widget build(BuildContext context) {
    final profile = AuthService.instance.profile;

    final navItems = [
      (Iconsax.chart_square, 'Dashboard'),
      (Iconsax.people, 'Usuarios'),
      (Iconsax.building_4, 'Proveedores'),
      (Iconsax.receipt_2, 'Pagos'),
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const AppLogo(size: 48, showGlow: false),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.displayName ?? 'Superadmin',
                          style: AppTypography.textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(profile?.email ?? '', style: AppTypography.textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Superadmin',
                            style: AppTypography.tag.copyWith(
                              color: AppColors.primaryLight,
                              fontSize: 10,
                            ),
                          ),
                        ),
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
            const SizedBox(height: 8),

            // Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                    child: Text('Navegación', style: AppTypography.caption),
                  ),
                  ...List.generate(navItems.length, (i) {
                    final (icon, label) = navItems[i];
                    final isActive = i == currentIndex;
                    return ListTile(
                      leading: Icon(
                        icon,
                        size: 20,
                        color: isActive ? AppColors.primaryLight : AppColors.textSecondary,
                      ),
                      title: Text(
                        label,
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          color: isActive ? AppColors.primaryLight : AppColors.textPrimary,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: isActive,
                      selectedTileColor: AppColors.primaryMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      dense: true,
                      horizontalTitleGap: 10,
                      onTap: () => onNavTap(i),
                    );
                  }),
                ],
              ),
            ),

            const Expanded(child: SizedBox()),
            const Divider(height: 1),

            // Logout
            ListTile(
              leading: const Icon(Iconsax.logout, size: 20, color: AppColors.error),
              title: Text(
                'Cerrar Sesión',
                style: AppTypography.textTheme.titleMedium?.copyWith(color: AppColors.error),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                InvoiceStore.instance.reset();
                await AuthService.instance.signOut();
                appRouter.go('/login');
              },
              horizontalTitleGap: 8,
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}
