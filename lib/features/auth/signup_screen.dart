// lib/features/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../services/auth_service.dart';
import '../../shared_widgets/primary_button.dart';
import '../../shared_widgets/bistro_app_bar.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).signUp(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully — please log in now.')),
      );

      context.go(AppRoutes.login);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      appBar: BistroAppBar(
        title: 'Create Account',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join Bistro Go',
                style: AppTextStyles.headlineLgMobile.copyWith(
                    color: const Color(0xFF1B2A4A)),
              ),
              const SizedBox(height: 6),
              Text(
                'Create your account to start ordering',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 28),

              _buildField('Full Name', _nameCtrl, Icons.person_outline_rounded,
                  hint: 'John Doe',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null),
              const SizedBox(height: AppSpacing.md),

              _buildField('Email', _emailCtrl, Icons.mail_outline_rounded,
                  hint: 'you@example.com',
                  type: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Enter a valid email' : null),
              const SizedBox(height: AppSpacing.md),

              _buildField('Phone (optional)', _phoneCtrl, Icons.phone_outlined,
                  hint: '+1 234 567 8900',
                  type: TextInputType.phone),
              const SizedBox(height: AppSpacing.md),

              _buildField('Password', _passCtrl, Icons.lock_outline_rounded,
                  hint: '••••••••',
                  obscure: true,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Min 6 characters' : null),
              const SizedBox(height: AppSpacing.md),

              _buildField('Confirm Password', _confirmCtrl, Icons.lock_outline_rounded,
                  hint: '••••••••',
                  obscure: true,
                  validator: (v) =>
                      (v != _passCtrl.text) ? 'Passwords do not match' : null),
              const SizedBox(height: AppSpacing.xl),

              PrimaryButton(
                  label: 'Create Account', onPressed: _signUp, isLoading: _loading),
              const SizedBox(height: AppSpacing.lg),

              Center(
                child: GestureDetector(
                  onTap: () => context.go(AppRoutes.login),
                  child: Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant),
                      children: [
                        TextSpan(
                          text: 'Login',
                          style: AppTextStyles.labelMd.copyWith(
                              color: const Color(0xFF1B2A4A)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    required String hint,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.labelMd.copyWith(color: const Color(0xFF1B2A4A))),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: AppColors.onSurface.withValues(alpha: 0.4)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0x331B2A4A))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0x331B2A4A))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
        ),
      ],
    );
  }
}
