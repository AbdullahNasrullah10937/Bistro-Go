// lib/services/menu_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/failures/app_failure.dart';
import '../models/category.dart';
import '../models/menu_item.dart';

final menuServiceProvider = Provider<MenuService>((ref) => MenuService());

class MenuService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Categories ────────────────────────────────────────────────────────────
  Future<List<Category>> fetchCategories() async {
    try {
      final data = await _client
          .from(AppConstants.categoriesTable)
          .select()
          .order('sort_order');
      return (data as List).map((e) => Category.fromJson(e)).toList();
    } catch (e) {
      throw ServerFailure('Failed to load categories: $e');
    }
  }

  // ── Menu Items ────────────────────────────────────────────────────────────
  Future<List<MenuItem>> fetchAllItems({bool availableOnly = true}) async {
    try {
      var query = _client
          .from(AppConstants.menuItemsTable)
          .select('*, item_addons(*)');
      if (availableOnly) {
        query = query.eq('is_available', true);
      }
      final data = await query.order('name');
      return (data as List).map((e) => MenuItem.fromJson(e)).toList();
    } catch (e) {
      throw ServerFailure('Failed to load menu items: $e');
    }
  }

  Future<List<MenuItem>> fetchItemsByCategory(String categoryId,
      {bool availableOnly = true}) async {
    try {
      var query = _client
          .from(AppConstants.menuItemsTable)
          .select('*, item_addons(*)')
          .eq('category_id', categoryId);
      if (availableOnly) query = query.eq('is_available', true);
      final data = await query.order('name');
      return (data as List).map((e) => MenuItem.fromJson(e)).toList();
    } catch (e) {
      throw ServerFailure('Failed to load menu items: $e');
    }
  }

  Future<MenuItem> fetchItemById(String id) async {
    try {
      final data = await _client
          .from(AppConstants.menuItemsTable)
          .select('*, item_addons(*)')
          .eq('id', id)
          .single();
      return MenuItem.fromJson(data);
    } catch (e) {
      throw NotFoundFailure('Menu item not found.');
    }
  }

  Future<List<MenuItem>> searchItems(String query) async {
    try {
      final data = await _client
          .from(AppConstants.menuItemsTable)
          .select('*, item_addons(*)')
          .eq('is_available', true)
          .ilike('name', '%$query%');
      return (data as List).map((e) => MenuItem.fromJson(e)).toList();
    } catch (e) {
      throw ServerFailure('Search failed: $e');
    }
  }

  // ── Admin CRUD ────────────────────────────────────────────────────────────
  Future<MenuItem> createItem(Map<String, dynamic> data) async {
    try {
      final result = await _client
          .from(AppConstants.menuItemsTable)
          .insert(data)
          .select('*, item_addons(*)')
          .single();
      return MenuItem.fromJson(result);
    } catch (e) {
      throw ServerFailure('Failed to create item: $e');
    }
  }

  Future<MenuItem> updateItem(String id, Map<String, dynamic> data) async {
    try {
      final result = await _client
          .from(AppConstants.menuItemsTable)
          .update(data)
          .eq('id', id)
          .select('*, item_addons(*)')
          .single();
      return MenuItem.fromJson(result);
    } catch (e) {
      throw ServerFailure('Failed to update item: $e');
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _client.from(AppConstants.menuItemsTable).delete().eq('id', id);
    } catch (e) {
      throw ServerFailure('Failed to delete item: $e');
    }
  }

  Future<void> toggleAvailability(String id, bool isAvailable) async {
    try {
      await _client
          .from(AppConstants.menuItemsTable)
          .update({'is_available': isAvailable})
          .eq('id', id);
    } catch (e) {
      throw ServerFailure('Failed to update availability: $e');
    }
  }

  // ── Category CRUD ─────────────────────────────────────────────────────────
  Future<Category> createCategory(String name, int sortOrder) async {
    try {
      final result = await _client
          .from(AppConstants.categoriesTable)
          .insert({'name': name, 'sort_order': sortOrder})
          .select()
          .single();
      return Category.fromJson(result);
    } catch (e) {
      throw ServerFailure('Failed to create category: $e');
    }
  }
}
