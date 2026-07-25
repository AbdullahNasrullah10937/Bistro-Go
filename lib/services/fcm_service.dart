// lib/services/fcm_service.dart
// FCM Push Notification — STUB IMPLEMENTATION
// Replace with full Firebase Messaging integration before production.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService());

class FcmService {
  /// Initializes FCM. Currently a stub — wire up FirebaseMessaging in production.
  Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('[FCM] Stub: FCM initialization skipped in this build.');
    }
    // TODO: Production implementation:
    // 1. Call FirebaseMessaging.instance.requestPermission()
    // 2. Get FCM token via FirebaseMessaging.instance.getToken()
    // 3. Save token to profiles.fcm_token in Supabase
    // 4. Listen to foreground messages: FirebaseMessaging.onMessage.listen(...)
    // 5. Configure flutter_local_notifications for foreground display
    // 6. Handle background tap: FirebaseMessaging.onMessageOpenedApp.listen(...)
  }

  /// Returns the device FCM token (stub returns null).
  Future<String?> getToken() async {
    if (kDebugMode) {
      debugPrint('[FCM] Stub: getToken() returning null.');
    }
    return null;
  }

  /// Saves FCM token to Supabase profile (stub no-op).
  Future<void> saveTokenToProfile(String userId) async {
    if (kDebugMode) {
      debugPrint('[FCM] Stub: saveTokenToProfile() no-op.');
    }
  }
}
