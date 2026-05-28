import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/navigation/app_router.dart';
import '../../core/theme/app_typography.dart';
import '../../data/store/invoice_store.dart';
import '../../features/auth/services/auth_service.dart';
import '../widgets/app_logo.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  static final scaffoldKey = GlobalKey<ScaffoldState>();

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppColors.scaffold,
      body: navigationShell,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
      drawer: const _AppDrawer(),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                index: 0,
                currentIndex: currentIndex,
                icon: Iconsax.home_2,
                activeIcon: Iconsax.home_25,
                label: 'Inicio',
                onTap: onTap,
              ),
              _NavItem(
                index: 1,
                currentIndex: currentIndex,
                icon: Iconsax.document_text,
                activeIcon: Iconsax.document_text1,
                label: 'Facturas',
                onTap: onTap,
              ),
              _NavItem(
                index: 2,
                currentIndex: currentIndex,
                icon: Iconsax.building,
                activeIcon: Iconsax.building_4,
                label: 'Proveedores',
                onTap: onTap,
              ),
              _NavItem(
                index: 3,
                currentIndex: currentIndex,
                icon: Iconsax.chart_2,
                activeIcon: Iconsax.chart_21,
                label: 'Reportes',
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
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
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerSection(title: 'CONFIGURACIÓN'),
                  _DrawerItem(icon: Iconsax.profile_circle, label: 'Mi Perfil'),
                  _DrawerItem(icon: Iconsax.building, label: 'Empresa'),
                  _DrawerItem(icon: Iconsax.people, label: 'Usuarios'),
                  _DrawerItem(icon: Iconsax.key, label: 'Roles y Permisos'),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  _DrawerSection(title: 'SISTEMA'),
                  _DrawerItem(icon: Iconsax.notification, label: 'Notificaciones'),
                  _DrawerItem(icon: Iconsax.import, label: 'Importar / Exportar'),
                  _DrawerItem(icon: Iconsax.setting_2, label: 'Configuración'),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  _DrawerItem(icon: Iconsax.message_question, label: 'Ayuda y Soporte'),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerLogout(),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final profile = AuthService.instance.profile;
    return Padding(
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
                  'Gestia',
                  style: AppTypography.textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  profile?.email ?? '',
                  style: AppTypography.textTheme.bodySmall,
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
    );
  }
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: AppTypography.tag.copyWith(letterSpacing: 1.2),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.textSecondary),
      title: Text(label, style: AppTypography.textTheme.titleMedium),
      onTap: () => Navigator.of(context).pop(),
      horizontalTitleGap: 8,
      dense: true,
    );
  }
}

class _DrawerLogout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
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
    );
  }
}
