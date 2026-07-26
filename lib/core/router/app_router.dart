// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/update_password_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/item_detail/item_detail_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/order_placed/order_placed_screen.dart';
import '../../features/order_tracking/order_tracking_screen.dart';
import '../../features/order_history/order_history_screen.dart';
import '../../features/order_history/order_detail_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/address_management_screen.dart';
import '../../features/admin/admin_login_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/admin/admin_order_detail_screen.dart';
import '../../features/admin/menu_management_screen.dart';
import '../../features/admin/add_edit_menu_item_screen.dart';
import '../../features/admin/admin_settings_screen.dart';
import '../../features/ai_assistant/ai_assistant_screen.dart';
import '../../features/home/main_shell.dart';

// Route names
abstract class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const updatePassword = '/update-password';
  static const home = '/home';
  static const itemDetail = '/item/:id';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orderPlaced = '/order-placed/:orderId';
  static const orderTracking = '/order-tracking/:orderId';
  static const orderHistory = '/orders';
  static const orderDetail = '/orders/:orderId';
  static const profile = '/profile';
  static const addressManagement = '/profile/addresses';
  static const adminLogin = '/admin/login';
  static const adminDashboard = '/admin/dashboard';
  static const adminOrderDetail = '/admin/orders/:orderId';
  static const menuManagement = '/admin/menu';
  static const addMenuItem = '/admin/menu/add';
  static const editMenuItem = '/admin/menu/edit/:id';
  static const adminSettings = '/admin/settings';
  static const aiAssistant = '/ai-assistant';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final isLoggedIn = user != null;

      // Admin routes guarded separately
      if (state.matchedLocation.startsWith('/admin') &&
          state.matchedLocation != AppRoutes.adminLogin) {
        if (!isLoggedIn) return AppRoutes.adminLogin;
      }

      return null; // no redirect
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.updatePassword,
        builder: (context, state) => const UpdatePasswordScreen(),
      ),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.orderHistory,
            builder: (context, state) => const OrderHistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      GoRoute(
        path: '/item/:id',
        builder: (context, state) =>
            ItemDetailScreen(itemId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-placed/:orderId',
        builder: (context, state) =>
            OrderPlacedScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: '/order-tracking/:orderId',
        builder: (context, state) =>
            OrderTrackingScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: '/orders/:orderId',
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: AppRoutes.addressManagement,
        builder: (context, state) => const AddressManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiAssistant,
        builder: (context, state) => const AiAssistantScreen(),
      ),

      // Admin routes
      GoRoute(
        path: AppRoutes.adminLogin,
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/orders/:orderId',
        builder: (context, state) =>
            AdminOrderDetailScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: AppRoutes.menuManagement,
        builder: (context, state) => const MenuManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.addMenuItem,
        builder: (context, state) => const AddEditMenuItemScreen(),
      ),
      GoRoute(
        path: '/admin/menu/edit/:id',
        builder: (context, state) =>
            AddEditMenuItemScreen(itemId: state.pathParameters['id']),
      ),
      GoRoute(
        path: AppRoutes.adminSettings,
        builder: (context, state) => const AdminSettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
