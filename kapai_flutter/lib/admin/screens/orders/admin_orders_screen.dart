import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/order_model.dart';

final _ordersFilterProvider = StateProvider<OrderType?>((ref) => null);

final _adminOrdersProvider = StreamProvider.family<List<OrderModel>, OrderType?>(
  (ref, type) => ref.watch(firestoreServiceProvider).watchOrders(type: type, limit: 100),
);

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_ordersFilterProvider);
    final ordersAsync = ref.watch(_adminOrdersProvider(filter));

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Orders', style: AppTextStyles.displaySmall),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _FilterChip(label: 'All', value: null, selected: filter),
                    _FilterChip(label: 'Dine-in', value: OrderType.dineIn, selected: filter),
                    _FilterChip(label: 'Takeaway', value: OrderType.takeaway, selected: filter),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (orders) {
                if (orders.isEmpty) {
                  return Center(child: Text('No orders', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMid)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _OrderCard(order: orders[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends ConsumerWidget {
  final String label;
  final OrderType? value;
  final OrderType? selected;

  const _FilterChip({required this.label, required this.value, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 12),
      child: GestureDetector(
        onTap: () => ref.read(_ordersFilterProvider.notifier).state = value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.olive : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? AppColors.olive : AppColors.creamDark),
          ),
          child: Text(label, style: AppTextStyles.labelSmall.copyWith(color: active ? Colors.white : AppColors.charcoal)),
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = switch (order.status) {
      OrderStatus.newOrder   => (AppColors.warningLight, AppColors.warning),
      OrderStatus.accepted   => (AppColors.sageLight, AppColors.sage),
      OrderStatus.preparing  => (AppColors.oliveLight, AppColors.moss),
      OrderStatus.ready      => (AppColors.successLight, AppColors.success),
      OrderStatus.completed  => (AppColors.cream, AppColors.textMid),
      OrderStatus.cancelled  => (AppColors.errorLight, AppColors.error),
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.creamDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  order.orderType == OrderType.takeaway ? Icons.takeout_dining_outlined : Icons.restaurant_outlined,
                  size: 16, color: AppColors.textMid,
                ),
                const SizedBox(width: 6),
                Text(
                  order.orderType == OrderType.takeaway ? 'Takeaway' : 'Dine-in · Table ${order.tableNumber}',
                  style: AppTextStyles.labelLarge,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.$1, borderRadius: BorderRadius.circular(10)),
                  child: Text(order.status.label, style: AppTextStyles.labelSmall.copyWith(color: statusColor.$2)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('${item.quantity}× ${item.name}', style: AppTextStyles.bodyMedium),
            )),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(DateFormat('h:mm a').format(order.createdAt), style: AppTextStyles.bodySmall),
                const Spacer(),
                Text('₹${order.total.toStringAsFixed(0)}', style: AppTextStyles.titleMedium),
              ],
            ),
            if (order.status != OrderStatus.completed && order.status != OrderStatus.cancelled) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Next status action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => ref.read(firestoreServiceProvider).updateOrderStatus(order.id, _nextStatus(order.status)),
                  child: Text(_nextLabel(order.status)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  OrderStatus _nextStatus(OrderStatus s) => switch (s) {
    OrderStatus.newOrder   => OrderStatus.accepted,
    OrderStatus.accepted   => OrderStatus.preparing,
    OrderStatus.preparing  => OrderStatus.ready,
    OrderStatus.ready      => OrderStatus.completed,
    _                      => s,
  };

  String _nextLabel(OrderStatus s) => switch (s) {
    OrderStatus.newOrder   => 'Accept Order',
    OrderStatus.accepted   => 'Start Preparing',
    OrderStatus.preparing  => 'Mark Ready',
    OrderStatus.ready      => 'Mark Completed',
    _                      => '',
  };
}
