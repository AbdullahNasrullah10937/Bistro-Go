// lib/core/providers/cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cart_item.dart';
import '../../services/cart_service.dart';

/// Live cart items list with mutation methods
class CartNotifier extends AsyncNotifier<List<CartItem>> {
  @override
  Future<List<CartItem>> build() async {
    return ref.read(cartServiceProvider).fetchCartItems();
  }

  Future<void> addItem({
    required String menuItemId,
    required int quantity,
    List<String> selectedAddonIds = const [],
    String? notes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(cartServiceProvider).addItem(
            menuItemId: menuItemId,
            quantity: quantity,
            selectedAddonIds: selectedAddonIds,
            notes: notes,
          );
      return ref.read(cartServiceProvider).fetchCartItems();
    });
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    state = await AsyncValue.guard(() async {
      await ref.read(cartServiceProvider).updateQuantity(cartItemId, quantity);
      return ref.read(cartServiceProvider).fetchCartItems();
    });
  }

  Future<void> removeItem(String cartItemId) async {
    state = await AsyncValue.guard(() async {
      await ref.read(cartServiceProvider).removeItem(cartItemId);
      return ref.read(cartServiceProvider).fetchCartItems();
    });
  }

  Future<void> clearCart() async {
    state = await AsyncValue.guard(() async {
      await ref.read(cartServiceProvider).clearCart();
      return <CartItem>[];
    });
  }

  void refresh() => ref.invalidateSelf();
}

final cartNotifierProvider = AsyncNotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

/// Computed: total item count in cart
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartNotifierProvider).when(
        data: (items) => items.fold(0, (sum, i) => sum + i.quantity),
        loading: () => 0,
        error: (_, __) => 0,
      );
});

/// Computed: cart subtotal
final cartSubtotalProvider = Provider<double>((ref) {
  return ref.watch(cartNotifierProvider).when(
        data: (items) => items.fold(0.0, (sum, i) => sum + i.lineTotal),
        loading: () => 0.0,
        error: (_, __) => 0.0,
      );
});
