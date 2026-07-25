// lib/core/providers/order_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';

/// Customer: my order history
final myOrdersProvider = FutureProvider<List<Order>>((ref) async {
  return ref.read(orderServiceProvider).fetchMyOrders();
});

/// Single order detail
final orderDetailProvider = FutureProvider.family<Order, String>((ref, orderId) async {
  return ref.read(orderServiceProvider).fetchOrderById(orderId);
});

/// Admin: all orders (with optional status filter)
final adminOrdersProvider =
    FutureProvider.family<List<Order>, OrderStatus?>((ref, status) async {
  return ref.read(orderServiceProvider).fetchAllOrders(statusFilter: status);
});

/// Selected status tab on admin dashboard
final adminStatusFilterProvider = StateProvider<OrderStatus?>((ref) => null);
