import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/order_model.dart';

final _recentOrdersProvider = StreamProvider<List<OrderModel>>((ref) =>
    ref.watch(firestoreServiceProvider).watchOrders(limit: 200));

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(_recentOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 16),
            child: Text('Reports', style: AppTextStyles.displaySmall),
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (orders) {
                final completed = orders.where((o) => o.status == OrderStatus.completed).toList();
                final totalRevenue = completed.fold<double>(0, (sum, o) => sum + o.total);
                final dineIn = completed.where((o) => o.orderType == OrderType.dineIn).length;
                final takeaway = completed.where((o) => o.orderType == OrderType.takeaway).length;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _ReportCard(
                      title: 'Total Revenue',
                      value: '₹${totalRevenue.toStringAsFixed(0)}',
                      subtitle: '${completed.length} completed orders',
                      icon: Icons.currency_rupee,
                      color: AppColors.moss,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _ReportCard(
                          title: 'Dine-in',
                          value: '$dineIn',
                          subtitle: 'orders',
                          icon: Icons.restaurant_outlined,
                          color: AppColors.sage,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _ReportCard(
                          title: 'Takeaway',
                          value: '$takeaway',
                          subtitle: 'orders',
                          icon: Icons.takeout_dining_outlined,
                          color: AppColors.terracotta,
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ReportCard(
                      title: 'Avg Order Value',
                      value: completed.isEmpty ? '₹0' : '₹${(totalRevenue / completed.length).toStringAsFixed(0)}',
                      subtitle: 'per completed order',
                      icon: Icons.trending_up,
                      color: AppColors.olive,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.creamDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Advanced Reports', style: AppTextStyles.titleMedium),
                          const SizedBox(height: 8),
                          Text('Category-wise sales, inventory cost analysis, and staff performance reports coming soon.',
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMid)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ReportCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
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
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.displaySmall),
          const SizedBox(height: 2),
          Text(title, style: AppTextStyles.labelLarge),
          Text(subtitle, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
