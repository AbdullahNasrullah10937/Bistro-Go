// lib/core/providers/address_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/address.dart';
import '../../services/address_service.dart';

final userAddressesProvider = FutureProvider<List<Address>>((ref) async {
  return ref.read(addressServiceProvider).fetchAddresses();
});
