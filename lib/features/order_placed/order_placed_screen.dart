// lib/features/order_placed/order_placed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../shared_widgets/primary_button.dart';

class OrderPlacedScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderPlacedScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderPlacedScreen> createState() => _OrderPlacedScreenState();
}

class _OrderPlacedScreenState extends ConsumerState<OrderPlacedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String get _shortId => '#${widget.orderId.substring(0, 8).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Success animation ────────────────────────────────────
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: AppColors.successContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 64,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  'Order Placed!',
                  style: AppTextStyles.headlineLgMobile.copyWith(
                      color: const Color(0xFF1B2A4A)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your order $_shortId has been received.\nWe\'re getting it ready for you.',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Order ID card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF1B2A4A).withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    children: [
                      Text('Order ID', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(_shortId,
                          style: AppTextStyles.headlineMd.copyWith(
                              fontFamily: 'Sora', color: AppColors.primary,
                              letterSpacing: 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                PrimaryButton(
                  label: 'Track My Order',
                  onPressed: () => context.go('/order-tracking/${widget.orderId}'),
                  icon: Icons.location_on_rounded,
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Back to Menu',
                  onPressed: () => context.go(AppRoutes.home),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
