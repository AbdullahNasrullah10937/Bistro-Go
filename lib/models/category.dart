// lib/models/category.dart

class Category {
  final String id;
  final String name;
  final int sortOrder;
  final String? iconUrl;

  const Category({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.iconUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      iconUrl: json['icon_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sort_order': sortOrder,
        'icon_url': iconUrl,
      };
}
