// lib/models/order.dart

enum OrderStatus {
  placed,
  confirmed,
  preparing,
  ready,
  completed,
  cancelled;

  String get displayName => switch (this) {
        OrderStatus.placed => 'Order Placed',
        OrderStatus.confirmed => 'Confirmed',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.ready => 'Ready for Pickup',
        OrderStatus.completed => 'Completed',
        OrderStatus.cancelled => 'Cancelled',
      };

  String get dbValue => name;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.placed,
    );
  }

  /// Returns true if this status can transition to [next]
  bool canTransitionTo(OrderStatus next) {
    return switch (this) {
      OrderStatus.placed => next == OrderStatus.confirmed || next == OrderStatus.cancelled,
      OrderStatus.confirmed => next == OrderStatus.preparing || next == OrderStatus.cancelled,
      OrderStatus.preparing => next == OrderStatus.ready,
      OrderStatus.ready => next == OrderStatus.completed,
      OrderStatus.completed => false,
      OrderStatus.cancelled => false,
    };
  }

  bool get isTerminal => this == OrderStatus.completed || this == OrderStatus.cancelled;
  int get stepIndex => switch (this) {
        OrderStatus.placed => 0,
        OrderStatus.confirmed => 1,
        OrderStatus.preparing => 2,
        OrderStatus.ready => 3,
        OrderStatus.completed => 4,
        OrderStatus.cancelled => -1,
      };
}

enum OrderType {
  delivery,
  dineIn,
  takeaway;

  String get displayName => switch (this) {
        OrderType.delivery => 'Delivery',
        OrderType.dineIn => 'Dine-In',
        OrderType.takeaway => 'Takeaway',
      };
}

class OrderItem {
  final String id;
  final String orderId;
  final String menuItemId;
  final String itemName;
  final int quantity;
  final double unitPrice;
  final List<String> selectedAddons;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    this.selectedAddons = const [],
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      menuItemId: json['menu_item_id'] as String,
      itemName: json['item_name'] as String? ??
          (json['menu_items'] != null
              ? (json['menu_items'] as Map)['name'] as String? ?? 'Item'
              : 'Item'),
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      selectedAddons:
          (json['selected_addons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  double get lineTotal => unitPrice * quantity;
}

class Order {
  final String id;
  final String userId;
  final OrderStatus status;
  final String orderType;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double total;
  final String? addressId;
  final String? deliveryAddress;
  final String? tableNumber;
  final String? notes;
  final String paymentMethod;
  final DateTime placedAt;
  final DateTime updatedAt;
  final List<OrderItem> items;
  // Customer info (via JOIN)
  final String? customerName;
  final String? customerEmail;

  const Order({
    required this.id,
    required this.userId,
    required this.status,
    required this.orderType,
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    required this.total,
    this.addressId,
    this.deliveryAddress,
    this.tableNumber,
    this.notes,
    required this.paymentMethod,
    required this.placedAt,
    required this.updatedAt,
    this.items = const [],
    this.customerName,
    this.customerEmail,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['order_items'] as List<dynamic>? ?? [];
    final profile = json['profiles'] as Map<String, dynamic>?;
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: OrderStatus.fromString(json['status'] as String? ?? 'placed'),
      orderType: json['order_type'] as String? ?? 'delivery',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      addressId: json['address_id'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      tableNumber: json['table_number'] as String?,
      notes: json['notes'] as String?,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      placedAt: json['placed_at'] != null
          ? DateTime.tryParse(json['placed_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),

      items: itemsJson.map((i) => OrderItem.fromJson(i as Map<String, dynamic>)).toList(),
      customerName: profile?['name'] as String?,
      customerEmail: json['customer_email'] as String?,
    );
  }

  OrderType get type => switch (orderType) {
        'dine_in' => OrderType.dineIn,
        'takeaway' => OrderType.takeaway,
        _ => OrderType.delivery,
      };

  bool get isDineIn => type == OrderType.dineIn;
  bool get isTakeaway => type == OrderType.takeaway;
  String get shortId => '#${id.substring(0, 8).toUpperCase()}';
}

