// lib/models/menu_item.dart
import 'item_addon.dart';

class MenuItem {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final List<String> tags;
  final List<ItemAddon> addons;

  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
    required this.tags,
    this.addons = const [],
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final addonsJson = json['item_addons'] as List<dynamic>? ?? [];
    return MenuItem(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      addons: addonsJson.map((a) => ItemAddon.fromJson(a as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'category_id': categoryId,
        'name': name,
        'description': description,
        'price': price,
        'image_url': imageUrl,
        'is_available': isAvailable,
        'tags': tags,
      };

  MenuItem copyWith({
    String? categoryId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? isAvailable,
    List<String>? tags,
    List<ItemAddon>? addons,
  }) {
    return MenuItem(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      tags: tags ?? this.tags,
      addons: addons ?? this.addons,
    );
  }

  bool get isVegan => tags.contains('Vegan');
  bool get isVegetarian => tags.contains('Vegetarian');
  bool get isGlutenFree => tags.contains('Gluten-Free');
}
