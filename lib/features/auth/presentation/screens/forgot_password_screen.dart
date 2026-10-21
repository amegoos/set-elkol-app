import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final error =
        await ref.read(authProvider.notifier).resetPassword(_email.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      context.showSnack(error, isError: true);
    } else {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('استعادة كلمة المرور'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent
            ? _SuccessView(email: _email.text, onBack: context.pop)
            : _FormView(
                formKey: _formKey,
                emailController: _email,
                isLoading: _isLoading,
                onSend: _send,
              ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.onSend,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_reset, color: AppColors.primary, size: 48),
          const SizedBox(height: 20),
          Text(
            'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة تعيين كلمة المرور.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          AppTextField(
            controller: emailController,
            label: 'البريد الإلكتروني',
            hint: 'example@email.com',
            keyboardType: TextInputType.emailAddress,
            prefix: const Icon(Icons.email_outlined, size: 20),
            validator: (v) {
              if (v == null || v.isEmpty) return 'أدخل البريد الإلكتروني';
              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                return 'بريد إلكتروني غير صحيح';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'إرسال رابط الاسترداد',
            onPressed: onSend,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.email, required this.onBack});
  final String email;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read_outlined,
            color: AppColors.success, size: 64),
        const SizedBox(height: 20),
        Text(
          'تم الإرسال!',
          style: AppTypography.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          'تم إرسال رابط استعادة كلمة المرور إلى:\n$email\n\nتحقق من بريدك الإلكتروني.',
          textAlign: TextAlign.center,
          style:
              AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        AppButton(label: 'العودة لتسجيل الدخول', onPressed: onBack),
      ],
    );
  }
}
