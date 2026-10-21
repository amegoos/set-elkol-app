import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/domain/entities/user_profile.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Login fields
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();

  // Signup fields
  final _signupName = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPhone = TextEditingController();
  final _signupPassword = TextEditingController();

  bool _isLoading = false;
  String? _loginError;
  String? _signupError;
  String? _loginInfoMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _loginError = null;
          _signupError = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _signupName.dispose();
    _signupEmail.dispose();
    _signupPhone.dispose();
    _signupPassword.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    // Prevent duplicate submissions
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _loginError = null;
      _loginInfoMessage = null;
    });
    try {
      final error = await ref.read(authProvider.notifier).signInWithEmail(
            _loginEmail.text.trim(),
            _loginPassword.text,
          );
      if (!mounted) return;
      if (error != null) {
        setState(() => _loginError = error);
        context.showSnack(error, isError: true);
      } else {
        context.showSnack('تم تسجيل الدخول بنجاح');
        // Navigation handled by router redirect based on auth state
      }
    } catch (e) {
      if (mounted) {
        final msg = 'حدث خطأ غير متوقع أثناء تسجيل الدخول: $e';
        setState(() => _loginError = msg);
        context.showSnack(msg, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signup() async {
    if (!_signupFormKey.currentState!.validate()) return;
    // Prevent duplicate submissions
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _signupError = null;
    });
    try {
      final error = await ref.read(authProvider.notifier).signUpWithEmail(
            email: _signupEmail.text.trim(),
            password: _signupPassword.text,
            name: _signupName.text.trim(),
            phone: _signupPhone.text.trim().isEmpty
                ? null
                : _signupPhone.text.trim(),
          );
      if (!mounted) return;
      if (error == 'confirm_email') {
        _showEmailConfirmDialog();
      } else if (error != null) {
        setState(() => _signupError = error);
        context.showSnack(error, isError: true);
      } else {
        context.showSnack('تم إنشاء الحساب بنجاح');
        // Navigation handled by router redirect based on auth state
      }
    } catch (e) {
      if (mounted) {
        final msg = 'حدث خطأ غير متوقع أثناء إنشاء الحساب: $e';
        setState(() => _signupError = msg);
        context.showSnack(msg, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _googleSignIn() async {
    // Prevent duplicate submissions
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _loginError = null;
      _signupError = null;
    });
    try {
      final error = await ref.read(authProvider.notifier).signInWithGoogle();
      if (!mounted) return;
      if (error != null) {
        setState(() => _loginError = error);
        context.showSnack(error, isError: true);
      }
      // On success, navigation handled by router redirect
    } catch (e) {
      if (mounted) {
        final msg = 'حدث خطأ أثناء المتابعة مع Google: $e';
        setState(() => _loginError = msg);
        context.showSnack(msg, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEmailConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        title: const Row(
          children: [
            Icon(Icons.mark_email_read_outlined,
                color: AppColors.primary, size: 26),
            SizedBox(width: 8),
            Text('تأكيد البريد الإلكتروني'),
          ],
        ),
        content: const Text(
          'تم إنشاء حسابك بنجاح! 🎉\n\nأرسلنا رابط تأكيد إلى بريدك الإلكتروني.\nيرجى فتح بريدك والضغط على الرابط لتفعيل حسابك، ثم التوجه إلى خانة تسجيل الدخول.',
          style: TextStyle(height: 1.6),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _loginInfoMessage =
                    'تم إرسال رابط تأكيد إلى بريدك الإلكتروني. يرجى تفعيل حسابك ثم تسجيل الدخول.';
              });
              _tabController.animateTo(0);
            },
            child: const Text('حسناً، فهمت'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final headerHeight = mediaQuery.size.height * 0.38;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Top Wave Hero Cover Image (Matching Image 1) ─────────────────
            Stack(
              children: [
                ClipPath(
                  clipper: CurvedWaveClipper(),
                  child: Container(
                    height: headerHeight,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.35),
                            Colors.transparent,
                            AppColors.primaryDark.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: mediaQuery.padding.top + 16,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ست الكل 🍲',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Auth Form Container ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  if (!SupabaseConfig.hasValidKey)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        border: Border.all(color: Colors.amber.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.amber.shade800, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'تنبيه: مفتاح Supabase Anon Key غير مهيأ في .env. يرجى إضافته لإتمام عمليات الحساب.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Tab Switcher (Sign In | Sign Up matching Image 1)
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primaryDark,
                    unselectedLabelColor: AppColors.textHint,
                    indicatorColor: AppColors.primaryDark,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    unselectedLabelStyle: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'تسجيل الدخول'),
                      Tab(text: 'إنشاء حساب'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 600,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _LoginTab(
                          formKey: _loginFormKey,
                          emailController: _loginEmail,
                          passwordController: _loginPassword,
                          isLoading: _isLoading,
                          errorMessage: _loginError,
                          infoMessage: _loginInfoMessage,
                          onLogin: _login,
                          onGoogle: _googleSignIn,
                          onPhone: () => context.push(RouteNames.phoneLogin),
                          onForgot: () =>
                              context.push(RouteNames.forgotPassword),
                        ),
                        _SignupTab(
                          formKey: _signupFormKey,
                          nameController: _signupName,
                          emailController: _signupEmail,
                          phoneController: _signupPhone,
                          passwordController: _signupPassword,
                          isLoading: _isLoading,
                          errorMessage: _signupError,
                          onSignup: _signup,
                          onGoogle: _googleSignIn,
                          onPhone: () => context.push(RouteNames.phoneLogin),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Curved Wave Clipper for Top Cover Image Header (Matching Image 1 Design)
class CurvedWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);

    final control1 = Offset(size.width * 0.25, size.height);
    final end1 = Offset(size.width * 0.5, size.height - 35);
    path.quadraticBezierTo(control1.dx, control1.dy, end1.dx, end1.dy);

    final control2 = Offset(size.width * 0.75, size.height - 70);
    final end2 = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(control2.dx, control2.dy, end2.dx, end2.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ── Login Tab ─────────────────────────────────────────────────────────────────

class _LoginTab extends StatelessWidget {
  const _LoginTab({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    this.errorMessage,
    this.infoMessage,
    required this.onLogin,
    required this.onGoogle,
    required this.onPhone,
    required this.onForgot,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? errorMessage;
  final String? infoMessage;
  final VoidCallback onLogin;
  final VoidCallback onGoogle;
  final VoidCallback onPhone;
  final VoidCallback onForgot;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (errorMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: AppRadius.input,
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (infoMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: AppRadius.input,
                  border: Border.all(color: Colors.green.shade600),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: Colors.green.shade700, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        infoMessage!,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            AppTextField(
              controller: emailController,
              label: 'البريد الإلكتروني',
              hint: 'example@email.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefix: const Icon(Icons.email_outlined, size: 20),
              validator: (v) {
                if (v == null || v.isEmpty) return 'أدخل البريد الإلكتروني';
                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                  return 'بريد إلكتروني غير صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: passwordController,
              label: 'كلمة المرور',
              hint: '••••••••',
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                if (v.length < 6) return 'كلمة المرور قصيرة جداً';
                return null;
              },
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: onForgot,
                child: Text(
                  'نسيت كلمة المرور؟',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 4),
            AppButton(
              label: 'تسجيل الدخول',
              onPressed: onLogin,
              isLoading: isLoading,
            ),
            const SizedBox(height: 16),
            _OrDivider(),
            const SizedBox(height: 16),
            _GoogleButton(onPressed: onGoogle, isLoading: isLoading),
            const SizedBox(height: 12),
            _PhoneButton(onPressed: onPhone, isLoading: isLoading),
          ],
        ),
      ),
    );
  }
}

// ── Signup Tab ────────────────────────────────────────────────────────────────

class _SignupTab extends StatelessWidget {
  const _SignupTab({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.isLoading,
    this.errorMessage,
    required this.onSignup,
    required this.onGoogle,
    required this.onPhone,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSignup;
  final VoidCallback onGoogle;
  final VoidCallback onPhone;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (errorMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: AppRadius.input,
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            AppTextField(
              controller: nameController,
              label: 'الاسم',
              hint: 'اسمك الكامل',
              textInputAction: TextInputAction.next,
              prefix: const Icon(Icons.person_outline, size: 20),
              validator: (v) => (v == null || v.isEmpty) ? 'أدخل اسمك' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: emailController,
              label: 'البريد الإلكتروني',
              hint: 'example@email.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefix: const Icon(Icons.email_outlined, size: 20),
              validator: (v) {
                if (v == null || v.isEmpty) return 'أدخل البريد الإلكتروني';
                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                  return 'بريد إلكتروني غير صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: phoneController,
              label: 'رقم الهاتف (اختياري)',
              hint: '01XXXXXXXXX',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              prefix: const Icon(Icons.phone_outlined, size: 20),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: passwordController,
              label: 'كلمة المرور',
              hint: '8 أحرف على الأقل',
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                if (v.length < 8) {
                  return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'إنشاء الحساب',
              onPressed: onSignup,
              isLoading: isLoading,
            ),
            const SizedBox(height: 16),
            _OrDivider(),
            const SizedBox(height: 16),
            _GoogleButton(onPressed: onGoogle, isLoading: isLoading),
            const SizedBox(height: 12),
            _PhoneButton(onPressed: onPhone, isLoading: isLoading),
          ],
        ),
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'أو',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed, required this.isLoading});
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.inputBorder),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: const Icon(Icons.g_mobiledata, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 10),
          Text(
            'المتابعة مع Google',
            style:
                AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _PhoneButton extends StatelessWidget {
  const _PhoneButton({required this.onPressed, required this.isLoading});
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.inputBorder),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.phone_iphone_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            'المتابعة برقم الموبايل',
            style:
                AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
