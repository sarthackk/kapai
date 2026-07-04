import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/order_model.dart';

final _myOrdersStreamProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).watchOrders(customerId: uid, limit: 50);
});

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(_myOrdersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
            child: Text('Orders', style: AppTextStyles.displayMedium),
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (orders) {
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 52, color: AppColors.textLight),
                        const SizedBox(height: 16),
                        Text('No orders yet', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMid)),
                      ],
                    ),
                  );
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

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final (statusBg, statusFg) = switch (order.status) {
      OrderStatus.newOrder   => (AppColors.warningLight, AppColors.warning),
      OrderStatus.accepted   => (AppColors.sageLight, AppColors.sage),
      OrderStatus.preparing  => (AppColors.oliveLight, AppColors.moss),
      OrderStatus.ready      => (AppColors.successLight, AppColors.success),
      OrderStatus.completed  => (AppColors.cream, AppColors.textMid),
      OrderStatus.cancelled  => (AppColors.errorLight, AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.creamDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                order.orderType == OrderType.takeaway ? 'Takeaway' : 'Dine-in · Table ${order.tableNumber}',
                style: AppTextStyles.labelLarge,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(10)),
                child: Text(order.status.label, style: AppTextStyles.labelSmall.copyWith(color: statusFg)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.items.map((i) => '${i.quantity}× ${i.name}').join(', '),
            style: AppTextStyles.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(DateFormat('d MMM, h:mm a').format(order.createdAt), style: AppTextStyles.bodySmall),
              const Spacer(),
              if (order.beansEarned > 0)
                Text('+${order.beansEarned} beans',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.moss)),
              const SizedBox(width: 12),
              Text('₹${order.total.toStringAsFixed(0)}', style: AppTextStyles.titleMedium),
            ],
          ),
        ],
      ),
    );
  }
}
