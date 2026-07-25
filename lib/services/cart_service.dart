// lib/services/cart_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/failures/app_failure.dart';
import '../models/cart_item.dart';

final cartServiceProvider = Provider<CartService>((ref) => CartService());

class CartService {
  final SupabaseClient _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser?.id ?? '';

  Future<List<CartItem>> fetchCartItems() async {
    try {
      final data = await _client
          .from(AppConstants.cartItemsTable)
          .select('*, menu_items(*, item_addons(*))')
          .eq('user_id', _userId);
      return (data as List).map((e) => CartItem.fromJson(e)).toList();
    } catch (e) {
      throw ServerFailure('Failed to load cart: $e');
    }
  }

  Future<CartItem> addItem({
    required String menuItemId,
    required int quantity,
    List<String> selectedAddonIds = const [],
    String? notes,
  }) async {
    try {
      // Check if same item+addons combo already in cart
      final existing = await _client
          .from(AppConstants.cartItemsTable)
          .select()
          .eq('user_id', _userId)
          .eq('menu_item_id', menuItemId)
          .maybeSingle();

      if (existing != null) {
        final newQty = (existing['quantity'] as int) + quantity;
        final updated = await _client
            .from(AppConstants.cartItemsTable)
            .update({'quantity': newQty})
            .eq('id', existing['id'])
            .select('*, menu_items(*, item_addons(*))')
            .single();
        return CartItem.fromJson(updated);
      }

      final result = await _client
          .from(AppConstants.cartItemsTable)
          .insert({
            'user_id': _userId,
            'menu_item_id': menuItemId,
            'quantity': quantity,
            'selected_addons': selectedAddonIds,
            'notes': notes,
          })
          .select('*, menu_items(*, item_addons(*))')
          .single();
      return CartItem.fromJson(result);
    } catch (e) {
      throw ServerFailure('Failed to add item to cart: $e');
    }
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    try {
      if (quantity <= 0) {
        await removeItem(cartItemId);
        return;
      }
      await _client
          .from(AppConstants.cartItemsTable)
          .update({'quantity': quantity})
          .eq('id', cartItemId);
    } catch (e) {
      throw ServerFailure('Failed to update quantity: $e');
    }
  }

  Future<void> removeItem(String cartItemId) async {
    try {
      await _client
          .from(AppConstants.cartItemsTable)
          .delete()
          .eq('id', cartItemId);
    } catch (e) {
      throw ServerFailure('Failed to remove item: $e');
    }
  }

  Future<void> clearCart() async {
    try {
      await _client
          .from(AppConstants.cartItemsTable)
          .delete()
          .eq('user_id', _userId);
    } catch (e) {
      throw ServerFailure('Failed to clear cart: $e');
    }
  }

  Future<int> getCartCount() async {
    try {
      final data = await _client
          .from(AppConstants.cartItemsTable)
          .select('quantity')
          .eq('user_id', _userId);
      return (data as List).fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
    } catch (_) {
      return 0;
    }
  }
}
