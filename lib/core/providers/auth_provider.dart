// lib/core/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/profile.dart';
import '../../services/auth_service.dart';
import 'address_provider.dart';
import 'cart_provider.dart';
import 'order_provider.dart';



/// Stream of Supabase auth state changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Centralized Auth State Listener — invalidates all user-scoped state on sign in / sign out
final authStateListenerProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
    next.whenData((authState) {
      final event = authState.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.userUpdated ||
          event == AuthChangeEvent.tokenRefreshed) {
        ref.invalidate(cartNotifierProvider);
        ref.invalidate(myOrdersProvider);
        ref.invalidate(profileNotifierProvider);
        ref.invalidate(profileProvider);
        ref.invalidate(userAddressesProvider);
      }
    });
  });
});


/// The currently signed-in user (nullable)

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

/// Whether user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// Profile of the current user
final profileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final authService = ref.read(authServiceProvider);
  return authService.fetchProfile(user.id);
});

/// AsyncNotifier to manage the current profile with mutation support
class ProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    return ref.read(authServiceProvider).fetchProfile(user.id);
  }

  Future<void> updateProfile({String? name, String? phone, String? avatarUrl}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(authServiceProvider).updateProfile(
            userId: user.id,
            name: name,
            phone: phone,
            avatarUrl: avatarUrl,
          );
    });
  }

  void invalidate() => ref.invalidateSelf();
}

final profileNotifierProvider = AsyncNotifierProvider<ProfileNotifier, Profile?>(
  ProfileNotifier.new,
);
