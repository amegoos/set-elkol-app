import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';

/// Screen for entering the 6-digit SMS verification OTP sent to the user's phone.
class PhoneOtpScreen extends ConsumerStatefulWidget {
  const PhoneOtpScreen({
    super.key,
    required this.phone,
  });

  final String phone;

  @override
  ConsumerState<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends ConsumerState<PhoneOtpScreen> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  bool _isResending = false;

  // Countdown timer for Resend Code (60s)
  Timer? _countdownTimer;
  int _secondsRemaining = 60;
  bool get _canResend => _secondsRemaining == 0;

  @override
  void initState() {
    super.initState();
    _otpController.text = '123456';
    _startCountdown();
  }

  void _startCountdown() {
    setState(() => _secondsRemaining = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final token = _otpController.text.trim();
    if (token.length < 6) {
      context.showSnack('يرجى إدخال رمز التحقق المكون من 6 أرقام',
          isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final error = await ref.read(authProvider.notifier).verifyPhoneOtp(
          phone: widget.phone,
          token: token,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      context.showSnack(error, isError: true);
    } else {
      context.showSnack('تم التحقق بنجاح! مرحباً بك في ست الكل');
      final profile = ref.read(currentProfileProvider);
      if (profile == null) {
        context.go(RouteNames.roleSelect);
      } else if (profile.isAdmin) {
        context.go(RouteNames.adminDashboard);
      } else if (profile.isVendor) {
        context.go(RouteNames.vendorDashboard);
      } else {
        context.go(RouteNames.customerHome);
      }
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend || _isResending) return;

    setState(() => _isResending = true);

    final error = await ref
        .read(authProvider.notifier)
        .signInWithPhoneOtp(phone: widget.phone);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (error != null) {
      context.showSnack(error, isError: true);
    } else {
      context.showSnack('تم إعادة إرسال رمز التحقق عبر SMS');
      _otpController.clear();
      _startCountdown();
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
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: mediaQuery.viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // SMS Icon Badge
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        color: AppColors.primary,
                        size: 38,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'رمز التحقق',
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Subtitle with Phone Number
                  Text(
                    'تم إرسال رمز التأكيد المكون من 6 أرقام إلى',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.phone,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          'تعديل',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_outlined,
                              size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 6),
                          Text(
                            'كود التأكيد الجاهز: 123456',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // 6-digit OTP Display & Hidden TextField
                  GestureDetector(
                    onTap: () => _focusNode.requestFocus(),
                    child: AbsorbPointer(
                      absorbing: false,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Visual 6 digit boxes
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _otpController,
                            builder: (context, value, _) {
                              final text = value.text;
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(6, (index) {
                                  final isFilled = index < text.length;
                                  final isCurrent = index == text.length;
                                  final char = isFilled ? text[index] : '';

                                  return Container(
                                    width: 46,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isCurrent
                                            ? AppColors.primary
                                            : (isFilled
                                                ? AppColors.primaryDark
                                                : AppColors.inputBorder),
                                        width:
                                            isCurrent || isFilled ? 2.0 : 1.2,
                                      ),
                                      boxShadow: [
                                        if (isCurrent)
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      char,
                                      style:
                                          AppTypography.headlineSmall.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),

                          // Invisible actual TextFormField to capture keyboard input
                          Opacity(
                            opacity: 0.0,
                            child: TextFormField(
                              controller: _otpController,
                              focusNode: _focusNode,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              onChanged: (val) {
                                if (val.length == 6) {
                                  _verifyOtp();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Verify Button
                  AppButton(
                    label: 'تأكيد ودخول',
                    isLoading: _isLoading,
                    onPressed: _verifyOtp,
                  ),

                  const SizedBox(height: 28),

                  // Resend Code Section
                  Center(
                    child: _canResend
                        ? TextButton.icon(
                            onPressed: _isResending ? null : _resendCode,
                            icon: _isResending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 20),
                            label: Text(
                              'إعادة إرسال رمز التحقق',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.timer_outlined,
                                  size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                'إعادة إرسال الرمز بعد $_secondsRemaining ثانية',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
