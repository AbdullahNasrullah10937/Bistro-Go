// lib/services/auth_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/failures/app_failure.dart';
import '../models/profile.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Auth State ────────────────────────────────────────────────────────────
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => currentUser != null;
  Session? get currentSession => _client.auth.currentSession;

  // ── Sign Up ───────────────────────────────────────────────────────────────
  Future<Profile> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.supabase.bistro-go://login-callback',
        data: {'name': name, 'phone': phone},
      );

      if (response.user == null) {
        throw const AuthFailure('Sign up failed. Please try again.');
      }

      // Note: Database trigger handle_new_user() automatically creates
      // the profile row in public.profiles with role = 'customer'

      return Profile(
        id: response.user!.id,
        name: name,
        phone: phone,
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ── Sign In ───────────────────────────────────────────────────────────────
  Future<Profile> signIn({required String email, required String password}) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) throw const AuthFailure('Login failed.');
      return await fetchProfile(response.user!.id);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ── Google Sign In ────────────────────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.bistro-go://login-callback',
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.bistro-go://login-callback',
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ── Update Password (Completion of Reset Flow) ────────────────────────────
  Future<void> updatePassword(String newPassword) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (response.user == null) {
        throw const AuthFailure('Failed to update password.');
      }
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ── Profile ───────────────────────────────────────────────────────────────
  Future<Profile> fetchProfile(String userId) async {
    try {
      final data = await _client
          .from(AppConstants.profilesTable)
          .select()
          .eq('id', userId)
          .single();
      return Profile.fromJson(data);
    } catch (e) {
      throw ServerFailure('Failed to load profile: $e');
    }
  }

  Future<Profile> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final data = await _client
          .from(AppConstants.profilesTable)
          .update({
            if (name != null) 'name': name,
            if (phone != null) 'phone': phone,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          })
          .eq('id', userId)
          .select()
          .single();
      return Profile.fromJson(data);
    } catch (e) {
      throw ServerFailure('Failed to update profile: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw const AuthFailure();
      // In production, this should be an Edge Function
      await _client.auth.signOut();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
