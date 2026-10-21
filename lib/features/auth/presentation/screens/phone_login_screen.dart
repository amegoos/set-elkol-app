import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';

/// Screen for entering an Egyptian phone number to receive an SMS OTP.
class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  // Selected country code — Egypt (+20) is primary
  final String _selectedCountryCode = '+20';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final rawPhone = _phoneController.text.trim();
    final formattedPhone = Validators.formatEgyptianPhoneForSupabase(rawPhone);

    final error = await ref
        .read(authProvider.notifier)
        .signInWithPhoneOtp(phone: formattedPhone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      context.showSnack(error, isError: true);
    } else {
      context.showSnack('تم إرسال رمز التحقق بنجاح إلى هاتفك');
      context.push(RouteNames.phoneOtp, extra: formattedPhone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: mediaQuery.viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Icon / Illustration Badge
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_iphone_rounded,
                      color: AppColors.primary,
                      size: 38,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'تسجيل الدخول برقم الموبايل',
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'أدخل رقم هاتفك لتسجيل الدخول أو إنشاء حساب جديد في ست الكل',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),

                // Country Code & Phone Input Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.card,
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      // Country Code Selector (Egypt 🇪🇬 +20)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  AppColors.inputBorder.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🇪🇬', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(
                              _selectedCountryCode,
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down,
                                color: AppColors.textSecondary, size: 20),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Phone Number Input Field
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '01012345678',
                            hintStyle: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.5),
                              letterSpacing: 0.5,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'أدخل رقم الموبايل';
                            }
                            if (!Validators.isValidEgyptianMobileNumber(
                                v.trim())) {
                              return 'رقم مصري غير صحيح (010, 011, 012, 015)';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Hint
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'مثال: 01012345678 أو 01123456789',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                AppButton(
                  label: 'إرسال رمز التحقق',
                  icon: const Icon(Icons.send_rounded, size: 18),
                  isLoading: _isLoading,
                  onPressed: _sendOtp,
                ),

                const SizedBox(height: 24),

                // Notice
                Center(
                  child: Text(
                    'سنرسل لك رمز تأكيد مكون من 6 أرقام عبر رسالة SMS مجانية.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
