import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../providers/auth_provider.dart';

/// Cinematic Intro & Splash Landing Screen for Set El Kol
/// Features: Real food photography (Egyptian Molokhia hero), natural steam animation,
/// tagline: "أكل الست المصرية مختلف", smooth transition to Auth buttons.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // ── Phase 1: Hero Image Zoom + Fade ──
  late AnimationController _heroController;
  late Animation<double> _heroScale;
  late Animation<double> _heroFade;

  // ── Phase 2: Headline "أكل الست المصرية مختلف" ──
  late AnimationController _textController;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  // ── Phase 3: Action Buttons ──
  late AnimationController _buttonsController;
  late Animation<double> _buttonsFade;
  late Animation<Offset> _buttonsSlide;

  // ── Decorative: Steam & floating heat particles ──
  late AnimationController _steamController;

  bool _hasNavigated = false;
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _runSequence();
  }

  void _initAnimations() {
    // Hero photo Ken-Burns effect (4 seconds duration)
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _heroScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
    );
    _heroFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    // Headline & Tagline entrance (500ms in)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Buttons entrance
    _buttonsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _buttonsFade = CurvedAnimation(
      parent: _buttonsController,
      curve: Curves.easeOut,
    );
    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _buttonsController,
      curve: Curves.easeOutCubic,
    ));

    // Continuous rising steam particles
    _steamController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  Future<void> _runSequence() async {
    _heroController.forward();

    // Check auth state
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      _navigateBasedOnAuth(authState);
      return;
    }

    // Phase 2: Show headline
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _textController.forward();

    // Phase 3: Show auth options after ~2.8s
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    setState(() => _showButtons = true);
    _buttonsController.forward();
  }

  void _navigateBasedOnAuth(AuthState state) {
    if (_hasNavigated) return;
    _hasNavigated = true;

    if (state.status == AuthStatus.authenticated) {
      if (state.profile == null) {
        context.go(RouteNames.roleSelect);
      } else if (state.profile!.isVendor) {
        context.go(RouteNames.vendorDashboard);
      } else {
        context.go(RouteNames.customerHome);
      }
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    _textController.dispose();
    _buttonsController.dispose();
    _steamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        _navigateBasedOnAuth(next);
      }
    });

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1E130E), // Deep earthy charcoal
      body: Stack(
        children: [
          // ── Real Food Photography Background (Molokhia Hero) ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _heroController,
              builder: (_, child) {
                return Opacity(
                  opacity: _heroFade.value,
                  child: Transform.scale(
                    scale: _heroScale.value,
                    child: Image.asset(
                      'assets/images/molokhia_hero.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Rich Gradient Overlay (Dark bottom for readability) ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.65),
                    const Color(0xFF190D08).withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ── Natural Steam Particle Effect Overlay ──
          Positioned.fill(
            child: Stack(
              children: List.generate(8, (i) => _SteamParticle(
                controller: _steamController,
                index: i,
                screenSize: size,
              )),
            ),
          ),

          // ── Main UI Content ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Brand Logo Icon & Badge ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.soup_kitchen_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ست الكل • Set El Kol',
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Hero Cinematic Text: "أكل الست المصرية مختلف" ──
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          Text(
                            'أكل الست المصرية مختلف',
                            style: AppTypography.displayLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 34,
                              height: 1.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'أكل بيتي مصري أصيل بأيدي أفضل الطهاة المنزليين',
                            style: AppTypography.bodyLarge.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Auth Action Buttons ──
                  if (_showButtons) ...[
                    SlideTransition(
                      position: _buttonsSlide,
                      child: FadeTransition(
                        opacity: _buttonsFade,
                        child: Column(
                          children: [
                            // Sign Up
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: () => context.go(RouteNames.login),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor: AppColors.primary.withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.button,
                                  ),
                                ),
                                child: Text(
                                  'إنشاء حساب جديد',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Log In
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton(
                                onPressed: () => context.go(RouteNames.login),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.button,
                                  ),
                                ),
                                child: Text(
                                  'تسجيل الدخول',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    thickness: 0.8,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    'أو الدخول بـ',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    thickness: 0.8,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Continue with Google
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: () {
                                  context.go(RouteNames.login);
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.button,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'G',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'المتابعة مع Google',
                                      style: AppTypography.labelLarge.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Smooth loader during intro sequence
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating Steam Particles (Natural motion effect for hot Egyptian food) ──

class _SteamParticle extends StatelessWidget {
  const _SteamParticle({
    required this.controller,
    required this.index,
    required this.screenSize,
  });

  final AnimationController controller;
  final int index;
  final Size screenSize;

  @override
  Widget build(BuildContext context) {
    final random = math.Random(index * 999);
    final startX = screenSize.width * 0.2 + random.nextDouble() * screenSize.width * 0.6;
    final startY = screenSize.height * 0.6;
    final size = 20.0 + random.nextDouble() * 35;
    final speed = 0.4 + random.nextDouble() * 0.6;

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final progress = (controller.value * speed + index * 0.15) % 1.0;
        final y = startY - progress * screenSize.height * 0.35;
        final x = startX + math.sin(progress * math.pi * 3) * 30;
        final opacity = (math.sin(progress * math.pi) * 0.18).clamp(0.0, 0.2);

        return Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.8),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
