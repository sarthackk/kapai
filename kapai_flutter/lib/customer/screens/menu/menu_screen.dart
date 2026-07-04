import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/menu_item_model.dart';
import '../cart/cart_provider.dart';

final _menuStreamProvider = StreamProvider<List<MenuItemModel>>(
  (ref) => ref.watch(firestoreServiceProvider).watchMenu(availableOnly: true),
);

final _menuCategoryProvider = StateProvider<String?>((ref) => null);
final _vegOnlyProvider = StateProvider<bool>((ref) => false);

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(_menuStreamProvider);
    final selectedCategory = ref.watch(_menuCategoryProvider);
    final vegOnly = ref.watch(_vegOnlyProvider);
    final cartCount = ref.watch(cartProvider).fold<int>(0, (sum, e) => sum + e.value);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allItems) {
          final categories = allItems.map((i) => i.category).toSet().toList()..sort();
          final filtered = allItems.where((item) {
            final catMatch = selectedCategory == null || item.category == selectedCategory;
            final vegMatch = !vegOnly || item.isVeg;
            return catMatch && vegMatch;
          }).toList();

          final grouped = <String, List<MenuItemModel>>{};
          for (final item in filtered) {
            grouped.putIfAbsent(item.category, () => []).add(item);
          }

          return CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.white,
                surfaceTintColor: AppColors.white,
                title: Text('Menu', style: AppTextStyles.displaySmall),
                actions: [
                  if (cartCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () => context.go('/app/cart'),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.olive,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                            ),
                            Positioned(
                              right: 0, top: 0,
                              child: Container(
                                width: 16, height: 16,
                                decoration: const BoxDecoration(color: AppColors.terracotta, shape: BoxShape.circle),
                                child: Center(child: Text('$cartCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(104),
                  child: Column(
                    children: [
                      // Category chips
                      SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _CatChip(label: 'All', selected: selectedCategory == null,
                                onTap: () => ref.read(_menuCategoryProvider.notifier).state = null),
                            ...categories.map((c) => _CatChip(
                              label: c,
                              selected: selectedCategory == c,
                              onTap: () => ref.read(_menuCategoryProvider.notifier).state = c,
                            )),
                          ],
                        ),
                      ),
                      // Veg filter
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => ref.read(_vegOnlyProvider.notifier).state = !vegOnly,
                              child: Row(
                                children: [
                                  Container(
                                    width: 16, height: 16,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.success, width: 1.5),
                                      borderRadius: BorderRadius.circular(3),
                                      color: vegOnly ? AppColors.success : Colors.transparent,
                                    ),
                                    child: vegOnly ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
                                  ),
                                  const SizedBox(width: 6),
                                  Text('Veg only', style: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoal)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Menu items
              if (grouped.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No items found')),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entries = grouped.entries.toList();
                      final entry = entries[index];
                      return _CategorySection(category: entry.key, items: entry.value);
                    },
                    childCount: grouped.length,
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CatChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.olive : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.olive : AppColors.creamDark),
        ),
        child: Text(label, style: AppTextStyles.labelSmall.copyWith(
            color: selected ? Colors.white : AppColors.charcoal)),
      ),
    ),
  );
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<MenuItemModel> items;

  const _CategorySection({required this.category, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(category, style: AppTextStyles.titleMedium),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.creamDark),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              return _MenuItem(item: e.value, isLast: e.key == items.length - 1);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends ConsumerWidget {
  final MenuItemModel item;
  final bool isLast;

  const _MenuItem({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(cartProvider)[item.id] ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.creamDark)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Veg/Non-veg indicator
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                border: Border.all(color: item.isVeg ? AppColors.success : AppColors.error, width: 1.5),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Center(
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: item.isVeg ? AppColors.success : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(item.name, style: AppTextStyles.labelLarge)),
                    if (item.isBestseller)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Bestseller', style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning)),
                      ),
                  ],
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 3),
                  Text(item.description!, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('₹${item.price.toStringAsFixed(0)}',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.terracotta, fontWeight: FontWeight.w600)),
                    if (item.beansValue > 0) ...[
                      const SizedBox(width: 8),
                      Text('+${item.beansValue} beans',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.moss)),
                    ],
                    const Spacer(),
                    if (qty == 0)
                      GestureDetector(
                        onTap: () => ref.read(cartProvider.notifier).add(item.id),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.olive,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      )
                    else
                      _Stepper(itemId: item.id, qty: qty),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends ConsumerWidget {
  final String itemId;
  final int qty;

  const _Stepper({required this.itemId, required this.qty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => ref.read(cartProvider.notifier).remove(itemId),
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.oliveLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.remove, size: 16, color: AppColors.olive),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('$qty', style: AppTextStyles.labelLarge),
        ),
        GestureDetector(
          onTap: () => ref.read(cartProvider.notifier).add(itemId),
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.olive,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
