// test/unit/order_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cibus/models/order.dart';

void main() {
  group('OrderStatus Unit Tests', () {
    test('OrderStatus displayName returns human readable labels', () {
      expect(OrderStatus.placed.displayName, 'Order Placed');
      expect(OrderStatus.confirmed.displayName, 'Confirmed');
      expect(OrderStatus.preparing.displayName, 'Preparing');
      expect(OrderStatus.ready.displayName, 'Ready for Pickup');
      expect(OrderStatus.completed.displayName, 'Completed');
      expect(OrderStatus.cancelled.displayName, 'Cancelled');
    });

    test('OrderStatus fromString parses string correctly with default fallback', () {
      expect(OrderStatus.fromString('preparing'), OrderStatus.preparing);
      expect(OrderStatus.fromString('completed'), OrderStatus.completed);
      expect(OrderStatus.fromString('unknown_status'), OrderStatus.placed);
    });

    test('OrderStatus status state transitions obey business rules', () {
      expect(OrderStatus.placed.canTransitionTo(OrderStatus.confirmed), isTrue);
      expect(OrderStatus.placed.canTransitionTo(OrderStatus.cancelled), isTrue);
      expect(OrderStatus.placed.canTransitionTo(OrderStatus.completed), isFalse);

      expect(OrderStatus.confirmed.canTransitionTo(OrderStatus.preparing), isTrue);
      expect(OrderStatus.preparing.canTransitionTo(OrderStatus.ready), isTrue);
      expect(OrderStatus.ready.canTransitionTo(OrderStatus.completed), isTrue);

      expect(OrderStatus.completed.canTransitionTo(OrderStatus.preparing), isFalse);
      expect(OrderStatus.cancelled.canTransitionTo(OrderStatus.confirmed), isFalse);
    });

    test('OrderStatus isTerminal correctly identifies final states', () {
      expect(OrderStatus.completed.isTerminal, isTrue);
      expect(OrderStatus.cancelled.isTerminal, isTrue);
      expect(OrderStatus.preparing.isTerminal, isFalse);
      expect(OrderStatus.ready.isTerminal, isFalse);
    });
  });

  group('Order JSON Serialization & Helpers', () {
    test('Order.fromJson correctly parses nested items and customer profile', () {
      final json = {
        'id': 'abc12345-6789-0000-1111-222233334444',
        'user_id': 'user_001',
        'status': 'preparing',
        'order_type': 'dine_in',
        'subtotal': 25.0,
        'tax': 2.125,
        'delivery_fee': 0.0,
        'total': 27.125,
        'table_number': '4B',
        'payment_method': 'card',
        'placed_at': '2026-07-27T10:00:00.000Z',
        'profiles': {'name': 'Jane Doe'},
        'order_items': [
          {
            'id': 'item_1',
            'order_id': 'abc12345-6789-0000-1111-222233334444',
            'menu_item_id': 'menu_101',
            'item_name': 'Truffle Burger',
            'quantity': 2,
            'unit_price': 12.5,
            'selected_addons': ['Extra Cheese', 'Bacon']
          }
        ]
      };

      final order = Order.fromJson(json);

      expect(order.shortId, '#ABC12345');
      expect(order.status, OrderStatus.preparing);
      expect(order.type, OrderType.dineIn);
      expect(order.isDineIn, isTrue);
      expect(order.customerName, 'Jane Doe');
      expect(order.items.length, 1);
      expect(order.items.first.itemName, 'Truffle Burger');
      expect(order.items.first.lineTotal, 25.0);
      expect(order.items.first.selectedAddons, contains('Extra Cheese'));
    });
  });
}
