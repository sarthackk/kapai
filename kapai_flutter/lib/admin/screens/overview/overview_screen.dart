import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/staff_model.dart';
import '../../../core/models/order_model.dart';
import '../../../core/models/inventory_item_model.dart';
import '../../../core/models/procurement_request_model.dart';

final _activeOrdersProvider = StreamProvider<List<OrderModel>>((ref) =>
    ref.watch(firestoreServiceProvider).watchOrders(status: OrderStatus.newOrder, limit: 20));

final _lowStockProvider = StreamProvider<List<InventoryItemModel>>((ref) =>
    ref.watch(firestoreServiceProvider).watchLowStockItems());

final _pendingProcurementProvider = StreamProvider<List<ProcurementRequestModel>>((ref) =>
    ref.watch(firestoreServiceProvider).watchProcurementRequests(status: ProcurementStatus.pending));

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(staffProfileProvider).valueOrNull;
    final activeOrders = ref.watch(_activeOrdersProvider).valueOrNull ?? [];
    final lowStock = ref.watch(_lowStockProvider).valueOrNull ?? [];
    final pendingProcurement = ref.watch(_pendingProcurementProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good ${_greeting()}, ${staff?.name.split(' ').first ?? ''}!',
                    style: AppTextStyles.displaySmall),
                Text(DateFormat('EEEE, d MMMM').format(DateTime.now()),
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMid)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stat cards
                Row(
                  children: [
                    Expanded(child: _StatCard(
                      label: 'Active Orders',
                      value: '${activeOrders.length}',
                      icon: Icons.receipt_long_outlined,
                      color: AppColors.moss,
                      onTap: () => context.go('/admin/orders'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(
                      label: 'Low Stock',
                      value: '${lowStock.length}',
                      icon: Icons.inventory_2_outlined,
                      color: lowStock.isEmpty ? AppColors.moss : AppColors.error,
                      onTap: () => context.go('/admin/inventory'),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _StatCard(
                      label: 'Pending Requests',
                      value: '${pendingProcurement.length}',
                      icon: Icons.shopping_cart_outlined,
                      color: pendingProcurement.isEmpty ? AppColors.moss : AppColors.warning,
                      onTap: () => context.go('/admin/procurement'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(
                      label: 'Role',
                      value: staff?.role.label ?? '—',
                      icon: Icons.badge_outlined,
                      color: AppColors.sage,
                    )),
                  ],
                ),

                // Active orders section
                if (activeOrders.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Text('Active Orders', style: AppTextStyles.titleMedium)),
                      TextButton(onPressed: () => context.go('/admin/orders'), child: const Text('See all')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...activeOrders.take(3).map((order) => _OrderTile(order: order)),
                ],

                // Low stock section
                if (lowStock.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Text('Low Stock Alerts', style: AppTextStyles.titleMedium)),
                      TextButton(onPressed: () => context.go('/admin/inventory'), child: const Text('View all')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.creamDark),
                    ),
                    child: Column(
                      children: lowStock.take(5).toList().asMap().entries.map((e) {
                        final item = e.value;
                        final isLast = e.key == (lowStock.length > 5 ? 4 : lowStock.length - 1);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.creamDark)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
                              const SizedBox(width: 10),
                              Expanded(child: Text(item.name, style: AppTextStyles.bodyMedium)),
                              Text('${item.currentStock} ${item.unit}', style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.creamDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 10),
            Text(value, style: AppTextStyles.displaySmall.copyWith(color: AppColors.charcoal)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _OrderTile extends ConsumerWidget {
  final OrderModel order;

  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.creamDark),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: order.orderType == OrderType.takeaway ? AppColors.terracottaLight : AppColors.mossLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              order.orderType == OrderType.takeaway ? Icons.takeout_dining_outlined : Icons.restaurant_outlined,
              size: 18,
              color: order.orderType == OrderType.takeaway ? AppColors.terracotta : AppColors.moss,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderType == OrderType.takeaway
                      ? 'Takeaway'
                      : 'Table ${order.tableNumber}',
                  style: AppTextStyles.labelLarge,
                ),
                Text(
                  order.items.map((i) => '${i.quantity}× ${i.name}').join(', '),
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          DropdownButton<OrderStatus>(
            value: order.status,
            underline: const SizedBox(),
            isDense: true,
            items: [OrderStatus.newOrder, OrderStatus.accepted, OrderStatus.preparing, OrderStatus.ready, OrderStatus.completed]
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: (s) {
              if (s != null) ref.read(firestoreServiceProvider).updateOrderStatus(order.id, s);
            },
          ),
        ],
      ),
    );
  }
}
