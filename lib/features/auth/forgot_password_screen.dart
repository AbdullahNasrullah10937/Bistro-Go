// lib/features/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../services/auth_service.dart';
import '../../shared_widgets/primary_button.dart';
import '../../shared_widgets/bistro_app_bar.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(_emailCtrl.text.trim());
      if (mounted) setState(() { _loading = false; _sent = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      appBar: const BistroAppBar(title: 'Reset Password'),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: _sent ? _SuccessView() : _FormView(
          formKey: _formKey,
          emailCtrl: _emailCtrl,
          loading: _loading,
          onSend: _sendReset,
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool loading;
  final VoidCallback onSend;
  const _FormView({required this.formKey, required this.emailCtrl, required this.loading, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Forgot your password?', style: AppTextStyles.headlineLgMobile.copyWith(color: const Color(0xFF1B2A4A))),
          const SizedBox(height: 8),
          Text("Enter your email and we'll send you a reset link.", style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 32),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'you@example.com',
              labelText: 'Email',
              prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x331B2A4A))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
            validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(label: 'Send Reset Link', onPressed: onSend, isLoading: loading),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.successContainer, shape: BoxShape.circle),
            child: const Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.success),
          ),
          const SizedBox(height: 24),
          Text('Check your inbox', style: AppTextStyles.headlineMd),
          const SizedBox(height: 8),
          Text("We've sent a password reset link to your email.", style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Back to Login', style: AppTextStyles.labelMd.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
