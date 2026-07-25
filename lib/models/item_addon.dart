// lib/models/item_addon.dart

class ItemAddon {
  final String id;
  final String menuItemId;
  final String name;
  final double extraPrice;

  const ItemAddon({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.extraPrice,
  });

  factory ItemAddon.fromJson(Map<String, dynamic> json) {
    return ItemAddon(
      id: json['id'] as String,
      menuItemId: json['menu_item_id'] as String,
      name: json['name'] as String,
      extraPrice: (json['extra_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'menu_item_id': menuItemId,
        'name': name,
        'extra_price': extraPrice,
      };
}
