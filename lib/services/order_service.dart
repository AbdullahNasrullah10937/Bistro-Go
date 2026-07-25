// lib/services/order_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/failures/app_failure.dart';
import '../models/order.dart';

final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  String get _userId => _client.auth.currentUser?.id ?? '';

  // ── Null-safe helpers ─────────────────────────────────────────────────────
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 1;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 1;
  }

  // ── Place Order ───────────────────────────────────────────────────────────
  Future<Order> placeOrder({
    required List<Map<String, dynamic>> cartItems,
    String orderType = 'delivery',
    String? addressId,
    String? deliveryAddress,
    String? tableNumber,
    String? notes,
    required String paymentMethod,
  }) async {
    final idempotencyKey = _uuid.v4();

    // 1. Try invoking place-order Edge Function first
    try {
      final response = await _client.functions.invoke(
        AppConstants.placeOrderFn,
        body: {
          'idempotency_key': idempotencyKey,
          'cart_items': cartItems,
          'order_type': orderType,
          'address_id': addressId,
          'delivery_address': deliveryAddress,
          'table_number': tableNumber,
          'notes': notes,
          'payment_method': paymentMethod,
        },
      );

      if (response.status == 200 && response.data != null && response.data['order_id'] != null) {
        final orderId = response.data['order_id'] as String;
        return await fetchOrderById(orderId);
      }

      if (response.status == 400 || response.status == 401 || response.status == 500) {
        final errorMsg = (response.data is Map) ? response.data['error']?.toString() : null;
        throw ServerFailure(errorMsg ?? 'Failed to place order (${response.status})');
      }
    } on FunctionException catch (e) {
      if (e.status != 404) {
        throw ServerFailure('Order processing error: ${e.reasonPhrase ?? e.status}');
      }

      // If 404 (Edge Function not deployed), proceed to direct DB fallback below
    } catch (e) {
      if (e is AppFailure) rethrow;
      // If network or unexpected error, fall through to direct DB fallback
    }

    // 2. Direct Database Fallback (if Edge Function 404 or missing)
    try {
      final orderId = _uuid.v4();
      double subtotal = 0;
      for (final item in cartItems) {
        final unitPrice = _toDouble(item['unit_price']);
        final qty = _toInt(item['quantity']);
        final addonTotal = _toDouble(item['addon_total']);
        subtotal += (unitPrice + addonTotal) * qty;
      }
      final tax = subtotal * 0.08;
      final deliveryFee = orderType == 'delivery' ? 2.99 : 0.0;
      final grandTotal = subtotal + tax + deliveryFee;

      // Insert into public.orders (schema verified)
      await _client.from(AppConstants.ordersTable).insert({
        'id': orderId,
        'user_id': _userId,
        'status': 'placed',
        'order_type': orderType,
        'table_number': tableNumber,
        'address_id': addressId,
        'delivery_address': deliveryAddress,
        'notes': notes,
        'payment_method': paymentMethod,
        'subtotal': subtotal,
        'tax': tax,
        'delivery_fee': deliveryFee,
        'total': grandTotal,
      });


      // Insert into public.order_items (schema verified)
      final itemsToInsert = cartItems.map((item) {
        final unitPrice = _toDouble(item['unit_price']);
        final addonTotal = _toDouble(item['addon_total']);
        final qty = _toInt(item['quantity']);
        final itemName = (item['item_name'] as String?) ?? 'Menu Item';
        final addons = (item['selected_addons'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        return {
          'order_id': orderId,
          'menu_item_id': item['menu_item_id'],
          'item_name': itemName,
          'quantity': qty,
          'unit_price': unitPrice + addonTotal,
          'selected_addons': addons,
        };
      }).toList();

      await _client.from(AppConstants.orderItemsTable).insert(itemsToInsert);

      // Insert into public.order_status_history (schema verified)
      await _client.from(AppConstants.orderStatusHistoryTable).insert({
        'order_id': orderId,
        'new_status': 'placed',
        'changed_by': _userId.isNotEmpty ? _userId : null,
      });

      return await fetchOrderById(orderId);
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Failed to place order: $e');
    }
  }

  // ── Fetch Orders ──────────────────────────────────────────────────────────
  Future<List<Order>> fetchMyOrders() async {
    try {
      final orders = await _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', _userId)
          .order('placed_at', ascending: false);
      return (orders as List).map((e) => Order.fromJson(e)).toList();
    } catch (e) {
      throw ServerFailure('Failed to load orders: $e');
    }
  }

  Future<Order> fetchOrderById(String orderId) async {
    try {
      // 1. Fetch order with order_items
      final orderData = await _client
          .from(AppConstants.ordersTable)
          .select('*, order_items(*)')
          .eq('id', orderId)
          .single();

      final mergedMap = Map<String, dynamic>.from(orderData);
      final userId = mergedMap['user_id'] as String?;

      // 2. Separate query: fetch customer's profile (name, phone) from profiles
      if (userId != null && userId.isNotEmpty) {
        try {
          final profileData = await _client
              .from(AppConstants.profilesTable)
              .select('name, phone')
              .eq('id', userId)
              .maybeSingle();
          if (profileData != null) {
            mergedMap['profiles'] = profileData;
          }
        } catch (_) {
          // Profile fetch optional
        }
      }

      return Order.fromJson(mergedMap);
    } catch (e) {
      throw NotFoundFailure('Order not found.');
    }
  }

  // ── Admin: Fetch All Orders ───────────────────────────────────────────────
  Future<List<Order>> fetchAllOrders({OrderStatus? statusFilter}) async {
    try {
      var query = _client
          .from(AppConstants.ordersTable)
          .select('*, order_items(*)');
      if (statusFilter != null) {
        query = query.eq('status', statusFilter.dbValue);
      }
      final ordersList = await query.order('placed_at', ascending: false);

      // Collect user_ids to bulk fetch profiles
      final userIds = (ordersList as List)
          .map((o) => o['user_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      final profilesMap = <String, Map<String, dynamic>>{};
      if (userIds.isNotEmpty) {
        try {
          final profilesData = await _client
              .from(AppConstants.profilesTable)
              .select('id, name, phone')
              .inFilter('id', userIds);

          for (final p in (profilesData as List)) {
            profilesMap[p['id'] as String] = Map<String, dynamic>.from(p);
          }
        } catch (_) {
          // Profile fetch optional
        }
      }

      return ordersList.map((e) {
        final orderMap = Map<String, dynamic>.from(e);
        final userId = orderMap['user_id'] as String?;
        if (userId != null && profilesMap.containsKey(userId)) {
          orderMap['profiles'] = profilesMap[userId];
        }
        return Order.fromJson(orderMap);
      }).toList();
    } catch (e) {
      throw ServerFailure('Failed to load orders: $e');
    }
  }


  // ── Update Order Status ───────────────────────────────────────────────────
  Future<Order> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      // Call the update-order-status Edge Function (validates role + transitions)
      final response = await _client.functions.invoke(
        AppConstants.updateOrderStatusFn,
        body: {
          'order_id': orderId,
          'new_status': newStatus.dbValue,
        },
      );

      if (response.status == 200) {
        // Edge Function returned the updated order — refetch via two-query pattern
        return await fetchOrderById(orderId);
      }

      // Edge Function returned a non-200 — parse and surface the error
      final errorBody = response.data;
      final message = (errorBody is Map ? errorBody['error'] : null) as String?;
      throw ServerFailure(message ?? 'Failed to update order status (HTTP ${response.status})');
    } on AppFailure {
      rethrow;
    } catch (e) {
      // Edge Function not reachable (network, not yet deployed) — fallback to direct DB update
      try {
        await _client
            .from(AppConstants.ordersTable)
            .update({
              'status': newStatus.dbValue,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', orderId);

        await _client.from(AppConstants.orderStatusHistoryTable).insert({
          'order_id': orderId,
          'new_status': newStatus.dbValue,
          'changed_by': _userId.isNotEmpty ? _userId : null,
        });

        return await fetchOrderById(orderId);
      } catch (innerErr) {
        throw ServerFailure('Failed to update order status: $innerErr');
      }
    }
  }

  // ── Create Stripe Payment Intent ──────────────────────────────────────────
  Future<Map<String, dynamic>> createPaymentIntent(String orderId) async {
    try {
      final response = await _client.functions.invoke(
        'create-payment-intent',
        body: {'order_id': orderId},
      );

      if (response.status == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data as Map);
      }

      final errorMsg = (response.data is Map) ? response.data['error']?.toString() : null;
      throw ServerFailure(errorMsg ?? 'Failed to create payment intent (${response.status})');
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw ServerFailure('Payment initialization error: $e');
    }
  }

  // ── Confirm Order Payment ──────────────────────────────────────────────────
  Future<Order> confirmOrderPayment({
    required String orderId,
    required String paymentIntentId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'confirm-order-payment',
        body: {
          'order_id': orderId,
          'payment_intent_id': paymentIntentId,
        },
      );

      if (response.status == 200) {
        return await fetchOrderById(orderId);
      }

      final errorMsg = (response.data is Map) ? response.data['error']?.toString() : null;
      throw ServerFailure(errorMsg ?? 'Failed to confirm order payment (${response.status})');
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw ServerFailure('Payment confirmation error: $e');
    }
  }
}


