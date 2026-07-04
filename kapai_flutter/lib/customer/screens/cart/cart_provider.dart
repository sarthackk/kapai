import 'package:flutter_riverpod/flutter_riverpod.dart';

// Map<menuItemId, quantity>
class CartNotifier extends StateNotifier<Map<String, int>> {
  CartNotifier() : super({});

  void add(String itemId) {
    state = {...state, itemId: (state[itemId] ?? 0) + 1};
  }

  void remove(String itemId) {
    final current = state[itemId] ?? 0;
    if (current <= 1) {
      final next = Map<String, int>.from(state);
      next.remove(itemId);
      state = next;
    } else {
      state = {...state, itemId: current - 1};
    }
  }

  void clear() => state = {};

  int get totalItems => state.values.fold(0, (sum, qty) => sum + qty);
}

final cartProvider = StateNotifierProvider<CartNotifier, Map<String, int>>(
  (_) => CartNotifier(),
);
