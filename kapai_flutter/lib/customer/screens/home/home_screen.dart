import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/models/order_model.dart';

final _menuProvider = StreamProvider<List<MenuItemModel>>(
  (ref) => ref.watch(firestoreServiceProvider).watchMenu(availableOnly: true),
);

final _myOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).watchOrders(customerId: uid, limit: 5);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final menu = ref.watch(_menuProvider).valueOrNull ?? [];
    final activeOrders = ref.watch(_myOrdersProvider).valueOrNull
        ?.where((o) => o.status != OrderStatus.completed && o.status != OrderStatus.cancelled)
        .toList() ?? [];

    final bestsellers = menu.where((m) => m.isBestseller).take(6).toList();
    final greeting = _greeting();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ListView(
        children: [
          // Header
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting,', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMid)),
                Text(user?.name.split(' ').first ?? 'Guest',
                    style: AppTextStyles.displayMedium),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Loyalty card
                _LoyaltyCard(user: user),
                const SizedBox(height: 20),

                // Active orders
                if (activeOrders.isNotEmpty) ...[
                  Text('Active Orders', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 10),
                  ...activeOrders.map((order) => _ActiveOrderTile(order: order)),
                  const SizedBox(height: 20),
                ],

                // Quick order
                Row(
                  children: [
                    Expanded(child: Text("Today's Picks", style: AppTextStyles.titleMedium)),
                    TextButton(onPressed: () => context.go('/app/menu'), child: const Text('See all')),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 160,
                  child: bestsellers.isEmpty
                      ? Center(child: Text('No items yet', style: AppTextStyles.bodySmall))
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: bestsellers.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) => _MenuCard(item: bestsellers[i]),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _LoyaltyCard extends StatelessWidget {
  final UserModel? user;
  const _LoyaltyCard({this.user});

  @override
  Widget build(BuildContext context) {
    final beans = user?.beans ?? 0;
    final tier = user?.tier ?? LoyaltyTier.sprout;
    final nextTierBeans = tier == LoyaltyTier.roast ? beans : tier.minBeans == 0 ? 200 : 500;
    final progress = nextTierBeans == 0 ? 1.0 : (beans / nextTierBeans).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.olive,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.olive.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Loyalty Beans', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(tier.label, style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('$beans', style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w700, height: 1)),
          Text('beans', style: AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tier == LoyaltyTier.roast ? 'Max tier reached!' : '${nextTierBeans - beans} beans to next tier',
            style: AppTextStyles.labelSmall.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _ActiveOrderTile extends StatelessWidget {
  final OrderModel order;
  const _ActiveOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
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
              color: AppColors.mossLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_cafe_outlined, size: 18, color: AppColors.moss),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.items.first.name, style: AppTextStyles.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(order.status.label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.moss)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textLight),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final MenuItemModel item;
  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.creamDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: item.isVeg ? AppColors.mossLight : AppColors.terracottaLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.isVeg ? Icons.eco_outlined : Icons.restaurant_outlined,
              size: 18,
              color: item.isVeg ? AppColors.moss : AppColors.terracotta,
            ),
          ),
          const Spacer(),
          Text(item.name, style: AppTextStyles.labelLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('₹${item.price.toStringAsFixed(0)}',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.terracotta, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
