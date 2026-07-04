import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/models/order_model.dart';
import 'cart_provider.dart';

final _menuForCartProvider = StreamProvider<List<MenuItemModel>>(
  (ref) => ref.watch(firestoreServiceProvider).watchMenu(availableOnly: true),
);

enum _OrderType { dineIn, takeaway }

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  _OrderType _orderType = _OrderType.dineIn;
  final _tableCtrl = TextEditingController();
  final _pickupCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _tableCtrl.dispose();
    _pickupCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(List<MenuItemModel> menu) async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    setState(() => _loading = true);

    final user = ref.read(currentUserProvider).valueOrNull;
    final items = cart.entries.map((e) {
      final item = menu.firstWhere((m) => m.id == e.key);
      return OrderItem(
        menuItemId: item.id,
        name: item.name,
        price: item.price,
        quantity: e.value,
      );
    }).toList();

    final subtotal = items.fold<double>(0, (sum, i) => sum + i.subtotal);
    final beansEarned = items.fold<int>(0, (sum, i) {
      final item = menu.firstWhere((m) => m.id == i.menuItemId, orElse: () => MenuItemModel(id: '', name: '', price: 0, category: ''));
      return sum + (item.beansValue * i.quantity);
    });

    final order = OrderModel(
      id: '',
      customerId: user?.id,
      customerName: user?.name,
      items: items,
      subtotal: subtotal,
      total: subtotal,
      orderType: _orderType == _OrderType.dineIn ? OrderType.dineIn : OrderType.takeaway,
      tableNumber: _orderType == _OrderType.dineIn ? int.tryParse(_tableCtrl.text) : null,
      pickupTime: _orderType == _OrderType.takeaway ? _pickupCtrl.text : null,
      status: OrderStatus.newOrder,
      beansEarned: beansEarned,
      createdAt: DateTime.now(),
    );

    await ref.read(firestoreServiceProvider).createOrder(order);

    // Update user beans
    if (user != null && beansEarned > 0) {
      await ref.read(firestoreServiceProvider).updateUser(
        user.copyWith(beans: user.beans + beansEarned, totalSpent: user.totalSpent + subtotal),
      );
    }

    ref.read(cartProvider.notifier).clear();
    if (mounted) context.go('/app/orders');
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final menuAsync = ref.watch(_menuForCartProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('Your Order', style: AppTextStyles.titleMedium),
        backgroundColor: AppColors.white,
        leading: BackButton(onPressed: () => context.go('/app/menu')),
      ),
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (menu) {
          if (cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 56, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text('Your cart is empty', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textMid)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/app/menu'),
                    child: const Text('Browse Menu'),
                  ),
                ],
              ),
            );
          }

          final cartItems = cart.entries
              .map((e) => (item: menu.firstWhere((m) => m.id == e.key, orElse: () => MenuItemModel(id: e.key, name: '?', price: 0, category: '')), qty: e.value))
              .where((e) => e.item.price > 0)
              .toList();

          final subtotal = cartItems.fold<double>(0, (sum, e) => sum + e.item.price * e.qty);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Items
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.creamDark),
                      ),
                      child: Column(
                        children: cartItems.asMap().entries.map((e) {
                          final ci = e.value;
                          final isLast = e.key == cartItems.length - 1;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.creamDark)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ci.item.name, style: AppTextStyles.labelLarge),
                                      Text('₹${ci.item.price.toStringAsFixed(0)} each',
                                          style: AppTextStyles.bodySmall),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => ref.read(cartProvider.notifier).remove(ci.item.id),
                                      child: Container(
                                        width: 28, height: 28,
                                        decoration: BoxDecoration(color: AppColors.oliveLight, borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(Icons.remove, size: 16, color: AppColors.olive),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text('${ci.qty}', style: AppTextStyles.labelLarge),
                                    ),
                                    GestureDetector(
                                      onTap: () => ref.read(cartProvider.notifier).add(ci.item.id),
                                      child: Container(
                                        width: 28, height: 28,
                                        decoration: BoxDecoration(color: AppColors.olive, borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(Icons.add, size: 16, color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('₹${(ci.item.price * ci.qty).toStringAsFixed(0)}',
                                        style: AppTextStyles.labelLarge),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Order type
                    Text('Order Type', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _TypeButton(
                          label: 'Dine-in',
                          icon: Icons.restaurant_outlined,
                          selected: _orderType == _OrderType.dineIn,
                          onTap: () => setState(() => _orderType = _OrderType.dineIn),
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _TypeButton(
                          label: 'Takeaway',
                          icon: Icons.takeout_dining_outlined,
                          selected: _orderType == _OrderType.takeaway,
                          onTap: () => setState(() => _orderType = _OrderType.takeaway),
                        )),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_orderType == _OrderType.dineIn)
                      TextFormField(
                        controller: _tableCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Table number'),
                      ),
                    if (_orderType == _OrderType.takeaway)
                      TextFormField(
                        controller: _pickupCtrl,
                        decoration: const InputDecoration(labelText: 'Pickup time (e.g. 10 mins)'),
                      ),
                    const SizedBox(height: 16),

                    // Bill summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.creamDark),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text('Subtotal', style: AppTextStyles.bodyMedium)),
                              Text('₹${subtotal.toStringAsFixed(0)}', style: AppTextStyles.labelLarge),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Place order
              Container(
                color: AppColors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _placeOrder(menu),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Place Order · ₹${subtotal.toStringAsFixed(0)}'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.oliveLight : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.olive : AppColors.creamDark),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? AppColors.olive : AppColors.textMid),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.labelLarge.copyWith(
                color: selected ? AppColors.olive : AppColors.charcoal)),
          ],
        ),
      ),
    );
  }
}
