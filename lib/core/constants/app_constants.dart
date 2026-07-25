// lib/core/constants/app_constants.dart

abstract class AppConstants {
  static const String appName = 'Bistro Go';
  static const String supabaseUrl = 'https://tadfgzdhytlqmaqevswv.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_qN9oNTvuXtwCpkgnalq5oA_itBUPJIC';

  // Storage bucket names
  static const String menuImagesBucket = 'menu-images';
  static const String avatarsBucket = 'avatars';

  // Edge Function names
  static const String placeOrderFn = 'place-order';
  static const String updateOrderStatusFn = 'update-order-status';
  static const String menuAssistantFn = 'menu-assistant';

  // Table names
  static const String profilesTable = 'profiles';
  static const String categoriesTable = 'categories';
  static const String menuItemsTable = 'menu_items';
  static const String itemAddonsTable = 'item_addons';
  static const String cartItemsTable = 'cart_items';
  static const String ordersTable = 'orders';
  static const String orderItemsTable = 'order_items';
  static const String orderStatusHistoryTable = 'order_status_history';
  static const String addressesTable = 'addresses';
  static const String paymentsTable = 'payments';

  // Tax rate
  static const double taxRate = 0.08; // 8%
  static const double deliveryFee = 2.99;

  // Currency
  static const String currencySymbol = '\$';

  // Pagination
  static const int pageSize = 20;
}
