// lib/features/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../shared_widgets/primary_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Hero image area ──────────────────────────────────────────────
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient blob
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.9,
                          colors: [Color(0xFFFFDBCF), Color(0xFFF4F1EC)],
                        ),
                      ),
                    ),
                  ),
                  // Decorative food grid
                  GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: const [
                      _FoodTile(icon: Icons.coffee_rounded, label: 'Coffee'),
                      _FoodTile(icon: Icons.lunch_dining_rounded, label: 'Burgers'),
                      _FoodTile(icon: Icons.local_pizza_rounded, label: 'Pizza'),
                      _FoodTile(icon: Icons.set_meal_rounded, label: 'Sushi'),
                      _FoodTile(icon: Icons.cake_rounded, label: 'Desserts'),
                      _FoodTile(icon: Icons.restaurant_rounded, label: 'Pasta'),
                      _FoodTile(icon: Icons.eco_rounded, label: 'Salads'),
                      _FoodTile(icon: Icons.ramen_dining_rounded, label: 'Ramen'),
                      _FoodTile(icon: Icons.egg_alt_rounded, label: 'Breakfast'),
                    ],
                  ),
                ],
              ),
            ),

            // ── Content card ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding, 32,
                AppSpacing.screenPadding, 32,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Order your\nfavorite dish',
                    style: AppTextStyles.headlineLgMobile.copyWith(
                      color: const Color(0xFF1B2A4A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Discover our curated menu of artisanal dishes and premium beverages — crafted for every moment.',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Get Started',
                    onPressed: () => context.go(AppRoutes.login),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go(AppRoutes.signup),
                      child: Text.rich(
                        TextSpan(
                          text: "Don't have an account? ",
                          style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant),
                          children: [
                            TextSpan(
                              text: 'Sign up',
                              style: AppTextStyles.labelMd.copyWith(
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FoodTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2A4A).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.labelXs,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
