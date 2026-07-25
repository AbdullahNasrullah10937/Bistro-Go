// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_stripe/flutter_stripe.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/router/app_router.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe
  Stripe.publishableKey =
      'pk_test_51Tx7EkAHWArEkdZ5DGt0fkMJfCEnBi7ywvnNekQC6OIpdDJDpKO3UsNs5iULKARGbbMBXch2a1Qrnuz3KjUve1CA00sXl0zttL';
  Stripe.merchantIdentifier = 'merchant.flutter.stripe.bistrogo';
  await Stripe.instance.applySettings();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );


  runApp(
    const ProviderScope(
      child: BistroGoApp(),
    ),
  );
}

class BistroGoApp extends ConsumerWidget {
  const BistroGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activate centralized auth state listener to clear user-scoped state on login/logout
    ref.watch(authStateListenerProvider);

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

