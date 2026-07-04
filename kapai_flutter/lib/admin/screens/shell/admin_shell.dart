import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/staff_model.dart';

class _NavItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String permission;

  const _NavItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.permission = '',
  });
}

const _navItems = [
  _NavItem(path: '/admin/overview', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Overview'),
  _NavItem(path: '/admin/orders', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Orders', permission: 'manageOrders'),
  _NavItem(path: '/admin/inventory', icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Inventory', permission: 'manageInventory'),
  _NavItem(path: '/admin/procurement', icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart, label: 'Procurement', permission: 'approveProcurement'),
  _NavItem(path: '/admin/vendors', icon: Icons.store_outlined, activeIcon: Icons.store, label: 'Vendors', permission: 'manageVendors'),
  _NavItem(path: '/admin/menu', icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: 'Menu', permission: 'manageMenu'),
  _NavItem(path: '/admin/staff', icon: Icons.people_outline, activeIcon: Icons.people, label: 'Staff', permission: 'manageStaff'),
  _NavItem(path: '/admin/reports', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Reports', permission: 'viewReports'),
];

class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffProfileProvider);
    final staff = staffAsync.valueOrNull;
    final isWide = MediaQuery.of(context).size.width >= 800;

    final visibleItems = _navItems.where((item) {
      if (item.permission.isEmpty) return true;
      return staff?.can(item.permission) ?? false;
    }).toList();

    if (isWide) {
      return _WideSidebar(child: child, items: visibleItems, staff: staff);
    }
    return _NarrowDrawer(child: child, items: visibleItems, staff: staff);
  }
}

class _WideSidebar extends StatelessWidget {
  final Widget child;
  final List<_NavItem> items;
  final StaffModel? staff;

  const _WideSidebar({required this.child, required this.items, this.staff});

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: AppColors.white,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.olive,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('K', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kapai', style: AppTextStyles.titleMedium),
                          Text('Admin Panel', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),
                const SizedBox(height: 8),

                // Nav items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: items.map((item) {
                      final active = path.startsWith(item.path);
                      return _SidebarItem(item: item, active: active);
                    }).toList(),
                  ),
                ),

                // Staff info
                const Divider(height: 1),
                _StaffFooter(staff: staff),
              ],
            ),
          ),
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NarrowDrawer extends StatelessWidget {
  final Widget child;
  final List<_NavItem> items;
  final StaffModel? staff;

  const _NarrowDrawer({required this.child, required this.items, this.staff});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: Text('Kapai Admin', style: AppTextStyles.titleMedium),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.white,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.olive),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Kapai', style: AppTextStyles.displaySmall.copyWith(color: Colors.white)),
                  Text('Admin Panel', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: items.map((item) {
                  final path = GoRouterState.of(context).uri.path;
                  final active = path.startsWith(item.path);
                  return _SidebarItem(item: item, active: active, onTap: () => Navigator.pop(context));
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            _StaffFooter(staff: staff),
          ],
        ),
      ),
      body: child,
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback? onTap;

  const _SidebarItem({required this.item, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active ? AppColors.oliveLight : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            onTap?.call();
            context.go(item.path);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  active ? item.activeIcon : item.icon,
                  size: 20,
                  color: active ? AppColors.olive : AppColors.textMid,
                ),
                const SizedBox(width: 10),
                Text(
                  item.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: active ? AppColors.olive : AppColors.charcoal,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
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

class _StaffFooter extends ConsumerWidget {
  final StaffModel? staff;
  const _StaffFooter({this.staff});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.oliveLight,
            child: Text(
              (staff?.name.isNotEmpty ?? false) ? staff!.name[0].toUpperCase() : '?',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.olive),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(staff?.name ?? '—', style: AppTextStyles.labelLarge, overflow: TextOverflow.ellipsis),
                Text(staff?.role.label ?? '', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 18, color: AppColors.textMid),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/admin/login');
            },
          ),
        ],
      ),
    );
  }
}
