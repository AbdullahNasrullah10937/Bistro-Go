// lib/services/address_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/failures/app_failure.dart';
import '../models/address.dart';

final addressServiceProvider = Provider<AddressService>((ref) => AddressService());

class AddressService {
  final SupabaseClient _client = Supabase.instance.client;
  String get _userId => _client.auth.currentUser?.id ?? '';

  Future<List<Address>> fetchAddresses() async {
    try {
      final data = await _client
          .from(AppConstants.addressesTable)
          .select()
          .eq('user_id', _userId)
          .order('is_default', ascending: false);
      return (data as List).map((e) => Address.fromJson(e)).toList();
    } catch (e) {
      throw ServerFailure('Failed to load addresses: $e');
    }
  }

  Future<Address> addAddress({
    required String label,
    required String addressLine,
    required String city,
    bool isDefault = false,
  }) async {
    try {
      if (isDefault) {
        await _client
            .from(AppConstants.addressesTable)
            .update({'is_default': false})
            .eq('user_id', _userId);
      }
      final result = await _client
          .from(AppConstants.addressesTable)
          .insert({
            'user_id': _userId,
            'label': label,
            'address_line': addressLine,
            'city': city,
            'is_default': isDefault,
          })
          .select()
          .single();
      return Address.fromJson(result);
    } catch (e) {
      throw ServerFailure('Failed to add address: $e');
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _client.from(AppConstants.addressesTable).delete().eq('id', id);
    } catch (e) {
      throw ServerFailure('Failed to delete address: $e');
    }
  }

  Future<void> setDefault(String id) async {
    try {
      await _client
          .from(AppConstants.addressesTable)
          .update({'is_default': false})
          .eq('user_id', _userId);
      await _client
          .from(AppConstants.addressesTable)
          .update({'is_default': true})
          .eq('id', id);
    } catch (e) {
      throw ServerFailure('Failed to set default address: $e');
    }
  }
}
