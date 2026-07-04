import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

// Customer screens
import '../../customer/screens/landing/landing_screen.dart';
import '../../customer/screens/auth/login_screen.dart';
import '../../customer/screens/shell/customer_shell.dart';
import '../../customer/screens/home/home_screen.dart';
import '../../customer/screens/menu/menu_screen.dart';
import '../../customer/screens/cart/cart_screen.dart';
import '../../customer/screens/orders/orders_screen.dart';
import '../../customer/screens/rewards/rewards_screen.dart';
import '../../customer/screens/profile/profile_screen.dart';

// Admin screens
import '../../admin/screens/login/admin_login_screen.dart';
import '../../admin/screens/shell/admin_shell.dart';
import '../../admin/screens/overview/overview_screen.dart';
import '../../admin/screens/orders/admin_orders_screen.dart';
import '../../admin/screens/inventory/inventory_screen.dart';
import '../../admin/screens/procurement/procurement_screen.dart';
import '../../admin/screens/vendors/vendors_screen.dart';
import '../../admin/screens/staff/staff_screen.dart';
import '../../admin/screens/menu_management/menu_management_screen.dart';
import '../../admin/screens/reports/reports_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _customerShellKey = GlobalKey<NavigatorState>();
final _adminShellKey = GlobalKey<NavigatorState>();

// ChangeNotifier that triggers router refresh when auth state changes
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  _RouterNotifier(this._ref) {
    _ref.listen(firebaseAuthProvider, (_, __) => notifyListeners());
    _ref.listen(staffProfileProvider, (_, __) => notifyListeners());
  }
}

final _routerNotifierProvider = ChangeNotifierProvider<_RouterNotifier>(
  (ref) => _RouterNotifier(ref),
);

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(firebaseAuthProvider);
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final path = state.uri.path;

      // Admin routes need staff login
      if (path.startsWith('/admin') && path != '/admin/login') {
        if (!isLoggedIn) return '/admin/login';
        final staff = ref.read(staffProfileProvider).valueOrNull;
        if (staff == null) return null; // still loading — let it through
        if (!staff.isActive) return '/admin/login';
      }

      // Customer routes need phone auth
      if (path.startsWith('/app')) {
        if (!isLoggedIn) return '/auth/login';
      }

      // Redirect logged-in staff away from admin login
      if (path == '/admin/login' && isLoggedIn) {
        final staff = ref.read(staffProfileProvider).valueOrNull;
        if (staff != null && staff.isActive) return '/admin/overview';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const LandingScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const CustomerLoginScreen()),

      ShellRoute(
        navigatorKey: _customerShellKey,
        builder: (_, __, child) => CustomerShell(child: child),
        routes: [
          GoRoute(path: '/app/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/app/menu', builder: (_, __) => const MenuScreen()),
          GoRoute(path: '/app/cart', builder: (_, __) => const CartScreen()),
          GoRoute(path: '/app/orders', builder: (_, __) => const OrdersScreen()),
          GoRoute(path: '/app/rewards', builder: (_, __) => const RewardsScreen()),
          GoRoute(path: '/app/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      GoRoute(path: '/admin/login', builder: (_, __) => const AdminLoginScreen()),

      ShellRoute(
        navigatorKey: _adminShellKey,
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin/overview', builder: (_, __) => const OverviewScreen()),
          GoRoute(path: '/admin/orders', builder: (_, __) => const AdminOrdersScreen()),
          GoRoute(path: '/admin/inventory', builder: (_, __) => const InventoryScreen()),
          GoRoute(path: '/admin/procurement', builder: (_, __) => const ProcurementScreen()),
          GoRoute(path: '/admin/vendors', builder: (_, __) => const VendorsScreen()),
          GoRoute(path: '/admin/staff', builder: (_, __) => const StaffScreen()),
          GoRoute(path: '/admin/menu', builder: (_, __) => const MenuManagementScreen()),
          GoRoute(path: '/admin/reports', builder: (_, __) => const ReportsScreen()),
        ],
      ),
    ],
  );
});
