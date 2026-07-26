// lib/features/admin/admin_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../services/auth_service.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  bool _soundAlerts = true;
  bool _autoAccept = true;
  bool _isOpen = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: CircleAvatar(
            backgroundColor: const Color(0xFFF2ECE4),
            child: const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF44403C)),
          ),
        ),
        title: const Text(
          'Bistro Go',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB83806),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF78716C), size: 22),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go(AppRoutes.adminLogin);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1917),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage store configuration & preferences.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF78716C),
              ),
            ),
            const SizedBox(height: 16),

            // Coming Soon Notice Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFB45309), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Advanced Settings Coming Soon',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Full printer configuration, tax overrides, and custom staff roles are coming in the next update.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Color(0xFFB45309),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 1: Store Operations
            _CardContainer(
              title: 'Store Operations',
              icon: Icons.storefront_rounded,
              child: Column(
                children: [
                  _SettingSwitchTile(
                    title: 'Store Accepting Orders',
                    subtitle: 'Toggle store visibility for incoming customer orders',
                    value: _isOpen,
                    onChanged: (v) => setState(() => _isOpen = v),
                  ),
                  const Divider(height: 1, color: Color(0xFFF5F5F4)),
                  _SettingSwitchTile(
                    title: 'Auto-Accept Orders',
                    subtitle: 'Automatically confirm new orders when placed',
                    value: _autoAccept,
                    onChanged: (v) => setState(() => _autoAccept = v),
                  ),
                  const Divider(height: 1, color: Color(0xFFF5F5F4)),
                  _SettingSwitchTile(
                    title: 'Kitchen Alert Sound',
                    subtitle: 'Play audio alert when a new order arrives',
                    value: _soundAlerts,
                    onChanged: (v) => setState(() => _soundAlerts = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 2: Restaurant Profile
            _CardContainer(
              title: 'Restaurant Profile',
              icon: Icons.restaurant_rounded,
              child: Column(
                children: const [
                  _InfoRow(label: 'Restaurant Name', value: 'Bistro Go'),
                  Divider(height: 1, color: Color(0xFFF5F5F4)),
                  _InfoRow(label: 'Currency', value: r'USD ($)'),
                  Divider(height: 1, color: Color(0xFFF5F5F4)),
                  _InfoRow(label: 'Tax Rate', value: '8.5%'),
                  Divider(height: 1, color: Color(0xFFF5F5F4)),
                  _InfoRow(label: 'Default Prep Time', value: '20 mins'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 3: Admin Account
            _CardContainer(
              title: 'Account & Version',
              icon: Icons.admin_panel_settings_rounded,
              child: Column(
                children: [
                  const _InfoRow(label: 'Role', value: 'Administrator'),
                  const Divider(height: 1, color: Color(0xFFF5F5F4)),
                  const _InfoRow(label: 'App Version', value: 'v1.0.0 (Release)'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) context.go(AppRoutes.adminLogin);
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                      label: const Text(
                        'Sign Out of Admin Portal',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE7E5E4))),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Dash Tab
              InkWell(
                onTap: () => context.go(AppRoutes.adminDashboard),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.grid_view_rounded, color: Color(0xFF78716C), size: 22),
                      SizedBox(height: 2),
                      Text(
                        'Dash',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF78716C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Menu Tab
              InkWell(
                onTap: () => context.push(AppRoutes.menuManagement),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.restaurant_rounded, color: Color(0xFF78716C), size: 22),
                      SizedBox(height: 2),
                      Text(
                        'Menu',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF78716C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Active Settings Tab (Filled Terracotta Pill)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFB83806),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.settings_rounded, color: Colors.white, size: 20),
                    SizedBox(height: 2),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _CardContainer({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A3E37).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF5F5F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFB83806), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1917),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1917),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF78716C),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFFB83806),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE7E5E4),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF78716C),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1917),
            ),
          ),
        ],
      ),
    );
  }
}
