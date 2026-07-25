// lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../services/auth_service.dart';
import '../../shared_widgets/bistro_app_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      appBar: BistroAppBar(title: 'Profile', showBack: false),
      body: profileAsync.when(
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              // ── Avatar & Name ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF1B2A4A).withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          (profile?.name?.isNotEmpty == true) ? profile!.name![0].toUpperCase() : '?',
                          style: AppTextStyles.headlineLgMobile.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(profile?.name ?? 'User', style: AppTextStyles.headlineSm),
                    const SizedBox(height: 4),
                    Text(profile?.phone ?? 'No phone added',
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Actions ───────────────────────────────────────────────────
              _MenuSection(items: [
                _MenuItem(icon: Icons.person_outline_rounded, label: 'Edit Profile', onTap: () => _showEditDialog(context, ref, profile?.name, profile?.phone)),
                _MenuItem(icon: Icons.location_on_outlined, label: 'Saved Addresses', onTap: () => context.push(AppRoutes.addressManagement)),
                _MenuItem(icon: Icons.receipt_long_outlined, label: 'Order History', onTap: () => context.go(AppRoutes.orderHistory)),
                _MenuItem(icon: Icons.auto_awesome_rounded, label: 'AI Menu Assistant', onTap: () => context.push(AppRoutes.aiAssistant)),
              ]),
              const SizedBox(height: AppSpacing.md),

              _MenuSection(items: [
                _MenuItem(icon: Icons.logout_rounded, label: 'Sign Out', color: AppColors.error, onTap: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go(AppRoutes.login);
                }),
              ]),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, String? name, String? phone) {
    final nameCtrl = TextEditingController(text: name);
    final phoneCtrl = TextEditingController(text: phone);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit Profile', style: AppTextStyles.headlineSm),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              await ref.read(profileNotifierProvider.notifier).updateProfile(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
              );
              if (dialogContext.mounted) {
                navigator.pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

}

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF1B2A4A).withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (item.color ?? AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, size: 20, color: item.color ?? AppColors.primary),
                ),
                title: Text(item.label, style: AppTextStyles.bodyMd.copyWith(color: item.color ?? AppColors.onSurface)),
                trailing: Icon(Icons.chevron_right_rounded, color: AppColors.outline, size: 20),
                onTap: item.onTap,
              ),
              if (!isLast) const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MenuItem({required this.icon, required this.label, required this.onTap, this.color});
}
