import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../navigation/app_shell.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/invoices/screens/invoices_screen.dart';
import '../../features/invoices/screens/invoice_detail_screen.dart';
import '../../features/invoices/screens/invoice_form_screen.dart';
import '../../features/suppliers/screens/suppliers_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/payments/screens/payments_history_screen.dart';
import '../../features/superadmin/screens/superadmin_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => const NoTransitionPage(child: SplashScreen()),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => const NoTransitionPage(child: LoginScreen()),
    ),
    GoRoute(
      path: '/superadmin',
      pageBuilder: (context, state) => const NoTransitionPage(child: SuperadminShell()),
    ),
    // Top-level so both regular users and superadmin can push to invoice detail
    GoRoute(
      path: '/invoices/:id',
      pageBuilder: (context, state) => _slideRight(
        InvoiceDetailScreen(invoiceId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/payments',
      pageBuilder: (context, state) => _slideRight(
        PaymentsHistoryScreen(
          supplierId: state.uri.queryParameters['supplierId'],
        ),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/invoices',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: InvoicesScreen()),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) => _slideUp(const InvoiceFormScreen()),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/suppliers',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SuppliersScreen()),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReportsScreen()),
          ),
        ]),
      ],
    ),
  ],
);

CustomTransitionPage<T> _slideRight<T>(Widget child) {
  return CustomTransitionPage<T>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, widget) {
      return SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: widget,
      );
    },
  );
}

CustomTransitionPage<T> _slideUp<T>(Widget child) {
  return CustomTransitionPage<T>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, widget) {
      return SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: widget,
      );
    },
  );
}
