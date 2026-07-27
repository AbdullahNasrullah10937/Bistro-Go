// test/unit/cart_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';

class CartCalculator {
  static const double taxRate = 0.085; // 8.5%
  static const double standardDeliveryFee = 4.99;
  static const double freeDeliveryThreshold = 30.0;

  static double calculateTax(double subtotal) => subtotal * taxRate;

  static double calculateDeliveryFee({
    required double subtotal,
    required bool isDineIn,
    required bool isTakeaway,
  }) {
    if (isDineIn || isTakeaway) return 0.0;
    if (subtotal >= freeDeliveryThreshold) return 0.0;
    return standardDeliveryFee;
  }

  static double calculateTotal({
    required double subtotal,
    required double tax,
    required double deliveryFee,
  }) {
    return subtotal + tax + deliveryFee;
  }
}

void main() {
  group('Cart Calculator Business Logic Unit Tests', () {
    test('calculateTax accurately computes 8.5% tax', () {
      expect(CartCalculator.calculateTax(100.0), 8.5);
      expect(CartCalculator.calculateTax(20.0), closeTo(1.7, 0.001));
      expect(CartCalculator.calculateTax(0.0), 0.0);
    });

    test('calculateDeliveryFee returns standard fee for delivery under threshold', () {
      final fee = CartCalculator.calculateDeliveryFee(
        subtotal: 25.0,
        isDineIn: false,
        isTakeaway: false,
      );
      expect(fee, 4.99);
    });

    test(r'calculateDeliveryFee waives fee for delivery over threshold ($30)', () {
      final fee = CartCalculator.calculateDeliveryFee(
        subtotal: 35.0,
        isDineIn: false,
        isTakeaway: false,
      );
      expect(fee, 0.0);
    });

    test('calculateDeliveryFee waives fee for Dine-In and Takeaway orders regardless of subtotal', () {
      expect(
        CartCalculator.calculateDeliveryFee(
          subtotal: 10.0,
          isDineIn: true,
          isTakeaway: false,
        ),
        0.0,
      );

      expect(
        CartCalculator.calculateDeliveryFee(
          subtotal: 15.0,
          isDineIn: false,
          isTakeaway: true,
        ),
        0.0,
      );
    });

    test('calculateTotal sums subtotal, tax, and delivery fee correctly', () {
      final subtotal = 20.0;
      final tax = CartCalculator.calculateTax(subtotal); // 1.7
      final deliveryFee = CartCalculator.calculateDeliveryFee(
        subtotal: subtotal,
        isDineIn: false,
        isTakeaway: false,
      ); // 4.99

      final grandTotal = CartCalculator.calculateTotal(
        subtotal: subtotal,
        tax: tax,
        deliveryFee: deliveryFee,
      );

      expect(grandTotal, closeTo(26.69, 0.01));
    });
  });
}
