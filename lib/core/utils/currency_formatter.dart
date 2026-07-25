// lib/core/utils/currency_formatter.dart
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );

  static String format(double amount) => _formatter.format(amount);

  static String formatCompact(double amount) =>
      '${AppConstants.currencySymbol}${amount.toStringAsFixed(2)}';
}
