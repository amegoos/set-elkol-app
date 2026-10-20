import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/domain/entities/user_profile.dart';
import '../../../../core/utils/validators.dart';

// ── Auth State ───────────────────────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.profile,
    this.errorMessage,
  });

  final AuthStatus status;
  final User? user;
  final UserProfile? profile;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    UserProfile? profile,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ── Auth Notifier ────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState()) {
    _initialize();
  }

  final Ref _ref;
  StreamSubscription<AuthState>? _sub;
  StreamSubscription<Uri>? _deepLinkSub;

  SupabaseClient get _client => _ref.read(supabaseClientProvider);

  void _initialize() {
    debugPrint('[Auth] Initializing AuthNotifier...');

    // 1. Listen to Supabase auth state changes (this fires for initial session restoration too)
    _client.auth.onAuthStateChange.listen((data) {
      debugPrint('[Auth] session/auth state received: event=${data.event}, hasSession=${data.session != null}, userId=${data.session?.user.id}');
      final user = data.session?.user;
      if (user != null) {
        _loadProfile(user);
      } else {
        // Only set unauthenticated if we are not in initial state anymore
        // This prevents flickering during initial session restoration
        if (state.status != AuthStatus.initial) {
          state = const AuthState(status: AuthStatus.unauthenticated);
        }
      }
    });

    // 2. Check current session immediately (but do not set unauthenticated yet - wait for stream)
    final session = _client.auth.currentSession;
    debugPrint('[Auth] Current session: ${session?.user.id ?? "none"}');
    if (session?.user != null) {
      _loadProfile(session!.user);
    }
    // Note: We do not set unauthenticated here - let the stream handle it
    // This prevents race condition where session is restored async after this check

    // 3. Listen to incoming deep links (Google OAuth callback)
    _setupDeepLinkListener();
  }

  void _setupDeepLinkListener() {
    final appLinks = AppLinks();
    _deepLinkSub = appLinks.uriLinkStream.listen((uri) async {
      debugPrint('[DeepLink] OAuth callback received: scheme=${uri.scheme}, host=${uri.host}');
      if (uri.scheme == 'io.supabase.setelkol' && uri.host == 'login-callback') {
        try {
          final errorParam = uri.queryParameters['error_description'] ??
              uri.queryParameters['error'];
          if (errorParam != null && errorParam.isNotEmpty) {
            debugPrint('[DeepLink] OAuth callback error param: $errorParam');
            final msg = _friendlyAuthError(errorParam);
            state = AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
            return;
          }

          if (_client.auth.currentSession == null) {
            debugPrint('[DeepLink] Processing session exchange from callback URL...');
            await _client.auth.getSessionFromUrl(uri);
            debugPrint('[DeepLink] Session exchange completed');
          }
        } catch (e) {
          debugPrint('[DeepLink] OAuth error in callback processing: $e');
          final msg = _friendlyAuthError(e);
          state = AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
        }
      }
    }, onError: (err) {
      debugPrint('[DeepLink] OAuth error in uriLinkStream: $err');
      final msg = _friendlyAuthError(err);
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
    });

    appLinks.getInitialLink().then((uri) async {
      if (uri != null) {
        debugPrint('[DeepLink] Initial OAuth callback detected: scheme=${uri.scheme}, host=${uri.host}');
        if (uri.scheme == 'io.supabase.setelkol' && uri.host == 'login-callback') {
          try {
            final errorParam = uri.queryParameters['error_description'] ??
                uri.queryParameters['error'];
            if (errorParam != null && errorParam.isNotEmpty) {
              debugPrint('[DeepLink] Initial OAuth error param: $errorParam');
              final msg = _friendlyAuthError(errorParam);
              state = AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
              return;
            }

            if (_client.auth.currentSession == null) {
              await _client.auth.getSessionFromUrl(uri);
            }
          } catch (e) {
            debugPrint('[DeepLink] Initial OAuth error: $e');
            final msg = _friendlyAuthError(e);
            state = AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
          }
        }
      }
    }).catchError((e) {
      debugPrint('[DeepLink] getInitialLink error: $e');
      final msg = _friendlyAuthError(e);
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
    });
  }

  Future<void> _loadProfile(User user) async {
    debugPrint('[Auth] Profile lookup started: userId=${user.id}');

    // Check if this is the admin email
    final isAdminEmail = user.email?.toLowerCase() == 'setelkol.support@gmail.com';

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final exists = data != null;
      debugPrint('[Auth] Profile lookup completed: exists=$exists');

      if (data == null) {
        // New user — check if metadata has a role or if role selection is needed
        final metaRole = user.userMetadata?['role'] as String?;

        // If admin email, force admin role
        final role = isAdminEmail
            ? UserRole.admin
            : (metaRole != null && metaRole.isNotEmpty
                ? UserRole.values.firstWhere((r) => r.name == metaRole, orElse: () => UserRole.customer)
                : null);

        if (role != null) {
          // Create profile in database
          await _client.from('profiles').upsert({
            'id': user.id,
            'email': user.email,
            'phone': user.phone ?? user.userMetadata?['phone'],
            'full_name': user.userMetadata?['full_name'] ?? user.phone ?? user.email ?? 'مستخدم',
            'role': role.name,
            'avatar_url': user.userMetadata?['avatar_url'],
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

          // If vendor, create vendor record
          if (role == UserRole.vendor) {
            await _client.from('vendors').upsert({
              'id': user.id,
              'business_name': user.userMetadata?['full_name'] ?? user.phone ?? user.email ?? 'متجر جديد',
              'is_active': true,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }

          final profile = UserProfile(
            id: user.id,
            name: user.userMetadata?['full_name'] as String? ?? user.phone ?? user.email ?? 'مستخدم',
            phone: user.phone ?? user.userMetadata?['phone'] as String?,
            email: user.email,
            profileImage: user.userMetadata?['avatar_url'] as String?,
            role: role,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          debugPrint('[Auth] Role found: ${profile.role.name}');

          String target;
          if (profile.isAdmin) target = RouteNames.adminDashboard;
          else if (profile.isVendor) target = RouteNames.vendorDashboard;
          else target = RouteNames.customerHome;

          debugPrint('[Auth] Navigation target: $target');
          state = AuthState(
            status: AuthStatus.authenticated,
            user: user,
            profile: profile,
          );
          return;
        }

        debugPrint('[Auth] Role found: none (new user without role)');
        debugPrint('[Auth] Navigation target: /role-select');
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          profile: null,
        );
        return;
      }

      var roleStr = data['role'] as String? ?? 'customer';
      if (isAdminEmail && roleStr != 'admin') {
        roleStr = 'admin';
        try {
          await _client.from('profiles').update({'role': 'admin'}).eq('id', user.id);
        } catch (e) {
          debugPrint('[Auth] Error updating role to admin: $e');
        }
      }
      final role = UserRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => UserRole.customer,
      );

      final profile = UserProfile(
        id: data['id'] as String,
        name: data['full_name'] as String? ?? user.userMetadata?['full_name'] as String? ?? user.phone ?? user.email ?? 'مستخدم',
        phone: data['phone'] as String? ?? user.phone ?? user.userMetadata?['phone'] as String?,
        email: data['email'] as String? ?? user.email,
        profileImage: data['avatar_url'] as String?,
        role: role,
        createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(data['updated_at'] as String? ?? '') ?? DateTime.now(),
      );

      debugPrint('[Auth] Role found: ${profile.role.name}');
      final target = profile.isAdmin
          ? RouteNames.adminDashboard
          : (profile.isVendor ? RouteNames.vendorDashboard : RouteNames.customerHome);
      debugPrint('[Auth] Navigation target: $target');

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        profile: profile,
      );
    } catch (e, stackTrace) {
      debugPrint('[Auth] Error loading profile: $e');
      debugPrint('[Auth] Stack trace: $stackTrace');

      // Graceful fallback from metadata if available so user is not blocked
      if (isAdminEmail) {
        final profile = UserProfile(
          id: user.id,
          name: user.userMetadata?['full_name'] as String? ?? 'إدارة ست الكل',
          phone: user.phone ?? user.userMetadata?['phone'] as String?,
          email: user.email,
          profileImage: user.userMetadata?['avatar_url'] as String?,
          role: UserRole.admin,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          profile: profile,
        );
        return;
      }
      final metaRole = user.userMetadata?['role'] as String?;
      if (metaRole != null && metaRole.isNotEmpty) {
        final role = UserRole.values.firstWhere(
          (r) => r.name == metaRole,
          orElse: () => UserRole.customer,
        );
        final profile = UserProfile(
          id: user.id,
          name: user.userMetadata?['full_name'] as String? ?? user.phone ?? user.email ?? 'مستخدم',
          phone: user.phone ?? user.userMetadata?['phone'] as String?,
          email: user.email,
          profileImage: user.userMetadata?['avatar_url'] as String?,
          role: role,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        debugPrint('[Auth] Role fallback from metadata after profile error: ${profile.role.name}');
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          profile: profile,
        );
        return;
      }

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        profile: null,
        errorMessage: 'تعذر تحميل بيانات الملف الشخصي: ${_friendlyAuthError(e)}',
      );
    }
  }

  // ── Error Mapping ───────────────────────────────────────────────────────────

  String _friendlyAuthError(dynamic e) {
    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      }
      if (msg.contains('user already registered') || msg.contains('already exists')) {
        return 'هذا البريد الإلكتروني مسجل بالفعل. يرجى تسجيل الدخول';
      }
      if (msg.contains('password should be at least') || msg.contains('weak_password')) {
        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
      }
      if (msg.contains('email not confirmed') || msg.contains('email_not_confirmed')) {
        return 'يرجى تأكيد بريدك الإلكتروني أولاً عبر الرابط المرسل إليك';
      }
      if (msg.contains('over email rate limit') || msg.contains('rate limit') || msg.contains('too many requests')) {
        return 'تم تجاوز الحد المسموح. يرجى الانتظار قليلاً والمحاولة لاحقاً';
      }
      if (msg.contains('invalid api key') || msg.contains('invalid apikey') || e.statusCode == '401') {
        return 'مفتاح Supabase API غير مهيأ أو غير صالح في .env';
      }
      if (msg.contains('user not found') || msg.contains('user_not_found')) {
        return 'لا يوجد حساب مسجل بهذا البريد الإلكتروني';
      }
      if (msg.contains('signup disabled')) {
        return 'إنشاء الحسابات معطل حالياً من إعدادات الخادم';
      }
      return e.message;
    }
    if (e is PostgrestException) {
      if (e.code == '42501' || e.message.toLowerCase().contains('permission denied')) {
        return 'لا تملك الصلاحية الكافية للوصول إلى هذه البيانات';
      }
      return 'حدث خطأ في قاعدة البيانات: ${e.message}';
    }
    final str = e.toString().toLowerCase();
    if (str.contains('socketexception') ||
        str.contains('clientexception') ||
        str.contains('failed host lookup') ||
        str.contains('network') ||
        str.contains('timed out')) {
      return 'تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت';
    }
    if (str.contains('invalid api key') || str.contains('invalid apikey') || str.contains('401')) {
      return 'مفتاح Supabase API غير مهيأ أو غير صالح في .env';
    }
    return 'حدث خطأ أثناء معالجة الطلب. يرجى المحاولة مرة أخرى';
  }

  // ── Sign In ─────────────────────────────────────────────────────────────────

  Future<String?> signInWithEmail(String email, String password) async {
    debugPrint('[Auth] Sign-in started: email=$email');
    if (!SupabaseConfig.hasValidKey) {
      debugPrint('[Auth] Sign-in aborted: Supabase key is missing or placeholder');
      const msg = 'تعذر الاتصال بـ Supabase: يرجى إضافة مفتاح Supabase Anon في ملف .env';
      state = const AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
      return msg;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final hasUser = response.user != null;
      final hasSession = response.session != null;
      debugPrint('[Auth] Sign-in response received: hasUser=$hasUser, hasSession=$hasSession');
      debugPrint('[Auth] Session exists: $hasSession');
      debugPrint('[Auth] User ID exists: $hasUser');

      if (response.user != null) {
        await _loadProfile(response.user!);
        return null; // success
      } else {
        const msg = 'فشل تسجيل الدخول: لم يتم استلام بيانات المستخدم من الخادم';
        state = const AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
        return msg;
      }
    } on AuthException catch (e) {
      debugPrint('[Auth] Sign-in AuthException: ${e.message} (code: ${e.statusCode})');
      final msg = _friendlyAuthError(e);
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: msg,
      );
      return msg;
    } catch (e, stackTrace) {
      debugPrint('[Auth] Sign-in error: $e');
      debugPrint('[Auth] Stack trace: $stackTrace');
      final msg = _friendlyAuthError(e);
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
      return msg;
    } finally {
      if (state.isLoading) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    }
  }

  Future<String?> signInWithGoogle() async {
    debugPrint('[Auth] Google OAuth started: redirectTo=io.supabase.setelkol://login-callback');
    if (!SupabaseConfig.hasValidKey) {
      debugPrint('[Auth] Google OAuth aborted: Supabase key is missing or placeholder');
      const msg = 'تعذر الاتصال بـ Supabase: يرجى إضافة مفتاح Supabase Anon في ملف .env';
      state = const AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
      return msg;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final success = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.setelkol://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      debugPrint('[Auth] signInWithOAuth browser launched: $success');
      // Set to unauthenticated while browser is active so UI is not stuck in loading
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return null;
    } on AuthException catch (e) {
      debugPrint('[Auth] Google OAuth error: ${e.message} (code: ${e.statusCode})');
      final msg = _friendlyAuthError(e);
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
      return msg;
    } catch (e, stackTrace) {
      debugPrint('[Auth] Google OAuth error: $e');
      debugPrint('[Auth] Stack trace: $stackTrace');
      final msg = _friendlyAuthError(e);
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
      return msg;
    } finally {
      if (state.isLoading) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    }
  }

  // ── Sign Up ─────────────────────────────────────────────────────────────────

  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    debugPrint('[Auth] Sign-up started: email=$email, hasPhone=${phone != null}');
    if (!SupabaseConfig.hasValidKey) {
      debugPrint('[Auth] Sign-up aborted: Supabase key is missing or placeholder');
      const msg = 'تعذر الاتصال بـ Supabase: يرجى إضافة مفتاح Supabase Anon في ملف .env';
      state = const AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
      return msg;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': name.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
      );

      final hasUser = response.user != null;
      final hasSession = response.session != null;
      debugPrint('[Auth] Sign-up response received: hasUser=$hasUser, hasSession=$hasSession');
      debugPrint('[Auth] Session exists: $hasSession');
      debugPrint('[Auth] User ID exists: $hasUser');

      if (response.user != null) {
        if (response.session != null) {
          // Immediate session established (email confirmation disabled or auto-confirmed)
          debugPrint('[Auth] Session established immediately upon sign up');
          await _loadProfile(response.user!);
          return null;
        } else {
          // Supabase project requires email confirmation before a session exists
          debugPrint('[Auth] Email confirmation required: session is null');
          debugPrint('[Auth] Navigation target: stay on auth and show confirmation dialog');
          state = const AuthState(status: AuthStatus.unauthenticated);
          return 'confirm_email';
        }
      } else {
        const msg = 'تعذر إنشاء الحساب. يرجى المحاولة مرة أخرى';
        state = const AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
        return msg;
      }
    } on AuthException catch (e) {
      debugPrint('[Auth] Sign-up AuthException: ${e.message} (code: ${e.statusCode})');
      final msg = _friendlyAuthError(e);
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
      return msg;
    } catch (e, stackTrace) {
      debugPrint('[Auth] Sign-up error: $e');
      debugPrint('[Auth] Stack trace: $stackTrace');
      final msg = _friendlyAuthError(e);
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
      return msg;
    } finally {
      if (state.isLoading) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    }
  }

  // ── Phone Authentication (SMS OTP) ────────────────────────────────────────

  /// Requests an SMS OTP code sent to the provided Egyptian phone number.
  Future<String?> signInWithPhoneOtp({required String phone}) async {
    debugPrint('[Auth] Phone sign-in OTP requested');
    if (!SupabaseConfig.hasValidKey) {
      debugPrint('[Auth] Phone OTP aborted: Supabase key is missing or placeholder');
      const msg = 'تعذر الاتصال بـ Supabase: يرجى إضافة مفتاح Supabase Anon في ملف .env';
      state = const AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
      return msg;
    }

    final formattedPhone = Validators.formatEgyptianPhoneForSupabase(phone);
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _client.auth.signInWithOtp(
        phone: formattedPhone,
        channel: OtpChannel.sms,
      );
      debugPrint('[Auth] SMS OTP sent successfully');
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return null; // success
    } on AuthException catch (e) {
      debugPrint('[Auth] signInWithPhoneOtp AuthException: ${e.message} (code: ${e.statusCode})');
      final msg = _friendlyPhoneAuthError(e);
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
      return msg;
    } catch (e, stackTrace) {
      debugPrint('[Auth] signInWithPhoneOtp error: $e');
      debugPrint('[Auth] Stack trace: $stackTrace');
      final msg = _friendlyPhoneAuthError(e);
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
      return msg;
    } finally {
      if (state.isLoading) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    }
  }

  /// Verifies the SMS OTP token and establishes the user session.
  Future<String?> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    debugPrint('[Auth] Phone OTP verification started');
    if (!SupabaseConfig.hasValidKey) {
      debugPrint('[Auth] verifyPhoneOtp aborted: Supabase key is missing or placeholder');
      const msg = 'تعذر الاتصال بـ Supabase: يرجى إضافة مفتاح Supabase Anon في ملف .env';
      state = const AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
      return msg;
    }

    final formattedPhone = Validators.formatEgyptianPhoneForSupabase(phone);
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _client.auth.verifyOTP(
        phone: formattedPhone,
        token: token.trim(),
        type: OtpType.sms,
      );
      final hasUser = response.user != null;
      final hasSession = response.session != null;
      debugPrint('[Auth] Phone verification response received: hasUser=$hasUser, hasSession=$hasSession');
      debugPrint('[Auth] Session exists: $hasSession');
      debugPrint('[Auth] User ID exists: $hasUser');

      if (response.user != null) {
        await _loadProfile(response.user!);
        return null; // success — session created
      } else {
        const msg = 'رمز التحقق غير صحيح أو منتهي الصلاحية';
        state = const AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
        return msg;
      }
    } on AuthException catch (e) {
      debugPrint('[Auth] verifyPhoneOtp AuthException: ${e.message} (code: ${e.statusCode})');
      final msg = _friendlyPhoneAuthError(e);
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
      return msg;
    } catch (e, stackTrace) {
      debugPrint('[Auth] verifyPhoneOtp error: $e');
      debugPrint('[Auth] Stack trace: $stackTrace');
      final msg = _friendlyPhoneAuthError(e);
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: msg);
      return msg;
    } finally {
      if (state.isLoading) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    }
  }

  String _friendlyPhoneAuthError(dynamic e) {
    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('token has expired') || msg.contains('expired')) {
        return 'انتهت صلاحية رمز التحقق. يرجى طلب رمز جديد';
      }
      if (msg.contains('invalid token') ||
          msg.contains('invalid otp') ||
          msg.contains('incorrect') ||
          msg.contains('token is invalid') ||
          msg.contains('verification code')) {
        return 'رمز التحقق غير صحيح. يرجى التأكد وإعادة المحاولة';
      }
      if (msg.contains('rate limit') ||
          msg.contains('over sms rate limit') ||
          msg.contains('too many requests')) {
        return 'تم تجاوز الحد المسموح لإرسال الرسائل. يرجى الانتظار دقيقة والمحاولة مجدداً';
      }
      if (msg.contains('phone number') ||
          msg.contains('invalid phone') ||
          msg.contains('unsupported phone')) {
        return 'رقم الهاتف غير صحيح أو غير مدعوم';
      }
      if (msg.contains('sms provider') || msg.contains('provider is not enabled')) {
        return 'خدمة الرسائل القصيرة SMS غير مفعلة في لوحة تحكم Supabase';
      }
      return e.message;
    }
    final str = e.toString().toLowerCase();
    if (str.contains('socketexception') ||
        str.contains('clientexception') ||
        str.contains('failed host lookup') ||
        str.contains('network')) {
      return 'تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت';
    }
    return 'حدث خطأ: $e';
  }

  // ── Role Selection ─────────────────────────────────────────────────────────

  Future<String?> setRole(UserRole role) async {
    final user = state.user;
    if (user == null) return 'لا يوجد مستخدم';

    debugPrint('[Auth] setRole: ${role.name} for user ${user.id}');
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'phone': user.phone ?? user.userMetadata?['phone'],
        'full_name': user.userMetadata?['full_name'] ?? user.phone ?? user.email ?? 'مستخدم',
        'role': role.name,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('[Auth] setRole upsert success');
      await _loadProfile(user);
      return null;
    } catch (e, stackTrace) {
      debugPrint('[Auth] setRole error: $e');
      debugPrint('[Auth] Stack trace: $stackTrace');
      return 'خطأ في حفظ الدور: $e';
    }
  }

  // ── Switch Role (Customer ↔ Vendor) ────────────────────────────────────────

  Future<String?> switchRole() async {
    final user = state.user;
    final currentProfile = state.profile;
    if (user == null || currentProfile == null) return 'لا يوجد مستخدم';

    final newRole = currentProfile.isVendor ? UserRole.customer : UserRole.vendor;
    debugPrint('[Auth] switchRole: ${currentProfile.role.name} -> ${newRole.name} for user ${user.id}');

    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'phone': user.phone ?? user.userMetadata?['phone'],
        'full_name': user.userMetadata?['full_name'] ?? user.phone ?? user.email ?? 'مستخدم',
        'role': newRole.name,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('[Auth] switchRole upsert success');

      // If switching TO vendor, ensure vendor record exists
      if (newRole == UserRole.vendor) {
        final vendorExists = await _client
            .from('vendors')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();

        if (vendorExists == null) {
          await _client.from('vendors').insert({
            'id': user.id,
            'business_name': user.userMetadata?['full_name'] ?? user.phone ?? user.email ?? 'متجر جديد',
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }

      await _loadProfile(user);
      return null;
    } catch (e, stackTrace) {
      debugPrint('[Auth] switchRole error: $e');
      debugPrint('[Auth] Stack trace: $stackTrace');
      return 'خطأ في تغيير الدور: $e';
    }
  }

  // ── Password Reset ─────────────────────────────────────────────────────────

  Future<String?> resetPassword(String email) async {
    debugPrint('[Auth] resetPassword: $email');
    try {
      await _client.auth.resetPasswordForEmail(email);
      debugPrint('[Auth] resetPassword email sent');
      return null;
    } on AuthException catch (e) {
      debugPrint('[Auth] resetPassword AuthException: ${e.message}');
      return _friendlyAuthError(e);
    } catch (e) {
      debugPrint('[Auth] resetPassword error: $e');
      return _friendlyAuthError(e);
    }
  }

  // ── Demo Sign In (1-tap access for User, Vendor, Admin) ─────────────────────

  void signInAsDemo(UserRole role) {
    final demoId = role == UserRole.admin
        ? '00000000-0000-0000-0000-000000000003'
        : (role == UserRole.vendor
            ? '00000000-0000-0000-0000-000000000001'
            : '00000000-0000-0000-0000-000000000002');

    final demoName = role == UserRole.admin
        ? 'أحمد أمجد (مدير التطبيق)'
        : (role == UserRole.vendor
            ? 'أم أحمد (ست الكل)'
            : 'سارة محمود');

    final demoEmail = role == UserRole.admin
        ? 'setelkol.support@gmail.com'
        : (role == UserRole.vendor
            ? 'omahmed@setelkol.app'
            : 'sara@setelkol.app');

    final demoPhone = role == UserRole.admin
        ? '+201099999999'
        : (role == UserRole.vendor ? '+201000000001' : '+201000000002');

    final demoProfile = UserProfile(
      id: demoId,
      name: demoName,
      email: demoEmail,
      phone: demoPhone,
      role: role,
      profileImage: role == UserRole.vendor
          ? 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=300&q=80'
          : (role == UserRole.admin
              ? 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=300&q=80'
              : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80'),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    debugPrint('[Auth] signInAsDemo: role=${role.name}, name=$demoName');
    state = AuthState(
      status: AuthStatus.authenticated,
      user: state.user,
      profile: demoProfile,
    );
  }

  // ── Sign Out ────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    debugPrint('[Auth] signOut - clearing session and local storage');
    try {
      // This clears the session from Supabase AND local secure storage
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('[Auth] signOut error: $e');
    }
    // Force unauthenticated state immediately
    state = const AuthState(status: AuthStatus.unauthenticated);
  }


  @override
  void dispose() {
    _sub?.cancel();
    _deepLinkSub?.cancel();
    super.dispose();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

/// Convenience provider for quick role checks.
final currentProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authProvider).profile;
});

final currentUserRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentProfileProvider)?.role;
});
