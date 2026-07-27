// test/unit/currency_formatter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cibus/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter Unit Tests', () {
    test('formatCompact formats amounts with standard dollar symbol and 2 decimal places', () {
      expect(CurrencyFormatter.formatCompact(0.0), '\$0.00');
      expect(CurrencyFormatter.formatCompact(12.5), '\$12.50');
      expect(CurrencyFormatter.formatCompact(49.99), '\$49.99');
      expect(CurrencyFormatter.formatCompact(100.0), '\$100.00');
    });

    test('format uses locale number formatting with dollar sign', () {
      final result = CurrencyFormatter.format(15.75);
      expect(result, contains('15.75'));
      expect(result, contains('\$'));
    });
  });
}
