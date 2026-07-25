// lib/services/storage_service.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/failures/app_failure.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<String> uploadMenuImage(File file) async {
    try {
      final ext = file.path.split('.').last;
      final fileName = '${_uuid.v4()}.$ext';
      final path = 'menu/$fileName';

      await _client.storage
          .from(AppConstants.menuImagesBucket)
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      return _client.storage
          .from(AppConstants.menuImagesBucket)
          .getPublicUrl(path);
    } catch (e) {
      throw StorageFailure('Failed to upload image: $e');
    }
  }

  Future<void> deleteMenuImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final path = uri.pathSegments.skipWhile((s) => s != AppConstants.menuImagesBucket).skip(1).join('/');
      await _client.storage.from(AppConstants.menuImagesBucket).remove([path]);
    } catch (_) {
      // Non-critical: swallow deletion errors
    }
  }
}
