// lib/core/providers/menu_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category.dart';
import '../../models/menu_item.dart';
import '../../services/menu_service.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(menuServiceProvider).fetchCategories();
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final menuItemsProvider = FutureProvider<List<MenuItem>>((ref) async {
  final categoryId = ref.watch(selectedCategoryProvider);
  final service = ref.read(menuServiceProvider);
  if (categoryId == null) {
    return service.fetchAllItems();
  }
  return service.fetchItemsByCategory(categoryId);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<MenuItem>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  return ref.read(menuServiceProvider).searchItems(query.trim());
});

final menuItemDetailProvider = FutureProvider.family<MenuItem, String>((ref, id) async {
  return ref.read(menuServiceProvider).fetchItemById(id);
});

/// Admin: all items including unavailable
final adminMenuItemsProvider = FutureProvider<List<MenuItem>>((ref) async {
  return ref.read(menuServiceProvider).fetchAllItems(availableOnly: false);
});
