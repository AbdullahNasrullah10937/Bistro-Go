// lib/models/cart_item.dart
import 'menu_item.dart';

class CartItem {
  final String id;
  final String userId;
  final String menuItemId;
  final int quantity;
  final List<String> selectedAddonIds;
  final String? notes;
  // Populated via JOIN
  final MenuItem? menuItem;

  const CartItem({
    required this.id,
    required this.userId,
    required this.menuItemId,
    required this.quantity,
    this.selectedAddonIds = const [],
    this.notes,
    this.menuItem,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final addonsRaw = json['selected_addons'];
    List<String> addonIds = [];
    if (addonsRaw is List) {
      addonIds = addonsRaw.map((e) => e.toString()).toList();
    }

    return CartItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      menuItemId: json['menu_item_id'] as String,
      quantity: json['quantity'] as int? ?? 1,
      selectedAddonIds: addonIds,
      notes: json['notes'] as String?,
      menuItem: json['menu_items'] != null
          ? MenuItem.fromJson(json['menu_items'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'menu_item_id': menuItemId,
        'quantity': quantity,
        'selected_addons': selectedAddonIds,
        'notes': notes,
      };

  CartItem copyWith({int? quantity, List<String>? selectedAddonIds, String? notes}) {
    return CartItem(
      id: id,
      userId: userId,
      menuItemId: menuItemId,
      quantity: quantity ?? this.quantity,
      selectedAddonIds: selectedAddonIds ?? this.selectedAddonIds,
      notes: notes ?? this.notes,
      menuItem: menuItem,
    );
  }

  double get lineTotal {
    if (menuItem == null) return 0;
    double addonsTotal = 0;
    for (final addonId in selectedAddonIds) {
      final addon = menuItem!.addons.where((a) => a.id == addonId).firstOrNull;
      if (addon != null) addonsTotal += addon.extraPrice;
    }
    return (menuItem!.price + addonsTotal) * quantity;
  }
}
