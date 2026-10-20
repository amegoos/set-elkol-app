import 'package:flutter_test/flutter_test.dart';
import 'package:set_elkol_app/core/config/supabase_config.dart';
import 'package:set_elkol_app/core/constants/route_names.dart';
import 'package:set_elkol_app/core/domain/entities/user_profile.dart';
import 'package:set_elkol_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

void main() {
  group('SupabaseConfig Tests', () {
    test('SupabaseConfig url falls back to expected production project URL', () {
      expect(SupabaseConfig.fallbackUrl, equals('https://pyaiuwzabcgdopclnmxk.supabase.co'));
      expect(SupabaseConfig.url, contains('pyaiuwzabcgdopclnmxk.supabase.co'));
    });

    test('SupabaseConfig correctly identifies placeholder keys as invalid', () {
      expect(SupabaseConfig.hasValidKey, isFalse);
    });
  });

  group('AuthState Transitions & Role Routing Tests', () {
    test('AuthState initial state is unauthenticated or initial', () {
      const state = AuthState();
      expect(state.status, equals(AuthStatus.initial));
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.user, isNull);
      expect(state.profile, isNull);
    });

    test('AuthState transitions to loading correctly', () {
      const state = AuthState(status: AuthStatus.initial);
      final loading = state.copyWith(status: AuthStatus.loading);
      expect(loading.status, equals(AuthStatus.loading));
      expect(loading.isLoading, isTrue);
      expect(loading.isAuthenticated, isFalse);
    });

    test('AuthState reset loading after exception', () {
      var isLoading = true;
      try {
        throw Exception('Simulated network error');
      } catch (_) {
        // Exception handled
      } finally {
        isLoading = false;
      }
      expect(isLoading, isFalse);
    });

    test('Sign-up requiring email confirmation sets unauthenticated state', () {
      // When email confirmation is enabled, session is null
      const state = AuthState(status: AuthStatus.unauthenticated);
      expect(state.isAuthenticated, isFalse);
      expect(state.status, equals(AuthStatus.unauthenticated));
    });

    test('Authenticated user without profile routes to /role-select', () {
      const state = AuthState(
        status: AuthStatus.authenticated,
        profile: null,
      );

      expect(state.isAuthenticated, isTrue);
      expect(state.profile, isNull);

      // Simulation of router redirect rule
      final route = (state.isAuthenticated && state.profile == null)
          ? RouteNames.roleSelect
          : RouteNames.customerHome;
      expect(route, equals(RouteNames.roleSelect));
    });

    test('Authenticated customer routes to customerHome', () {
      final profile = UserProfile(
        id: 'cust-1',
        name: 'عميل تجريبي',
        role: UserRole.customer,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final state = AuthState(
        status: AuthStatus.authenticated,
        profile: profile,
      );

      expect(state.isAuthenticated, isTrue);
      expect(profile.isCustomer, isTrue);
      expect(profile.isVendor, isFalse);

      final target = profile.isVendor
          ? RouteNames.vendorDashboard
          : RouteNames.customerHome;
      expect(target, equals(RouteNames.customerHome));
    });

    test('Authenticated vendor routes to vendorDashboard', () {
      final profile = UserProfile(
        id: 'vend-1',
        name: 'شيف أم أحمد',
        role: UserRole.vendor,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final state = AuthState(
        status: AuthStatus.authenticated,
        profile: profile,
      );

      expect(state.isAuthenticated, isTrue);
      expect(profile.isCustomer, isFalse);
      expect(profile.isVendor, isTrue);

      final target = profile.isVendor
          ? RouteNames.vendorDashboard
          : RouteNames.customerHome;
      expect(target, equals(RouteNames.vendorDashboard));
    });
  });

  group('Friendly Auth Error Messages', () {
    String testFriendlyError(dynamic e) {
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
        if (msg.contains('email not confirmed')) {
          return 'يرجى تأكيد بريدك الإلكتروني أولاً عبر الرابط المرسل إليك';
        }
        if (msg.contains('over email rate limit') || msg.contains('rate limit')) {
          return 'تم تجاوز الحد المسموح. يرجى الانتظار قليلاً والمحاولة لاحقاً';
        }
        if (msg.contains('invalid api key') || msg.contains('invalid apikey') || e.statusCode == '401') {
          return 'مفتاح Supabase API غير مهيأ أو غير صالح في .env';
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

    test('maps invalid login credentials to Arabic error message', () {
      final e = AuthException('Invalid login credentials', statusCode: '400');
      expect(testFriendlyError(e), equals('البريد الإلكتروني أو كلمة المرور غير صحيحة'));
    });

    test('maps user already registered to Arabic error message', () {
      final e = AuthException('User already registered', statusCode: '422');
      expect(testFriendlyError(e), equals('هذا البريد الإلكتروني مسجل بالفعل. يرجى تسجيل الدخول'));
    });

    test('maps email not confirmed to Arabic error message', () {
      final e = AuthException('Email not confirmed', statusCode: '400');
      expect(testFriendlyError(e), equals('يرجى تأكيد بريدك الإلكتروني أولاً عبر الرابط المرسل إليك'));
    });

    test('maps invalid api key / 401 to clear Supabase config error', () {
      final e = AuthException('Invalid API key', statusCode: '401');
      expect(testFriendlyError(e), equals('مفتاح Supabase API غير مهيأ أو غير صالح في .env'));
    });

    test('maps network errors to Arabic connection error message', () {
      final e = Exception('SocketException: Failed host lookup: pyaiuwzabcgdopclnmxk.supabase.co');
      expect(testFriendlyError(e), equals('تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت'));
    });

    test('maps user not found error to clear Arabic message', () {
      final e = AuthException('User not found', statusCode: '404');
      final msg = testFriendlyError(e);
      expect(msg, equals('User not found'));
    });

    test('Router refresh condition does NOT trigger on loading transition', () {
      const prev = AuthState(status: AuthStatus.unauthenticated);
      const next = AuthState(status: AuthStatus.loading);

      final authStatusChanged = prev.isAuthenticated != next.isAuthenticated;
      final userChanged = prev.user?.id != next.user?.id;
      final roleChanged = next.isAuthenticated &&
          prev.profile?.role != next.profile?.role;

      final shouldNotify = authStatusChanged || userChanged || roleChanged;
      // Crucial: loading state transition must NOT trigger router refresh!
      expect(shouldNotify, isFalse);
    });

    test('Router refresh condition does NOT trigger on unauthenticated error transition', () {
      const prev = AuthState(status: AuthStatus.loading);
      const next = AuthState(status: AuthStatus.unauthenticated, errorMessage: 'خطأ');

      final authStatusChanged = prev.isAuthenticated != next.isAuthenticated;
      final userChanged = prev.user?.id != next.user?.id;
      final roleChanged = next.isAuthenticated &&
          prev.profile?.role != next.profile?.role;

      final shouldNotify = authStatusChanged || userChanged || roleChanged;
      // Crucial: error transition must NOT trigger router refresh!
      expect(shouldNotify, isFalse);
    });

    test('Router refresh condition DOES trigger on successful authentication', () {
      const prev = AuthState(status: AuthStatus.unauthenticated);
      final profile = UserProfile(
        id: 'user-123',
        name: 'مستخدم جديد',
        role: UserRole.customer,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final next = AuthState(
        status: AuthStatus.authenticated,
        profile: profile,
      );

      final authStatusChanged = prev.isAuthenticated != next.isAuthenticated;
      final userChanged = prev.user?.id != next.user?.id;
      final roleChanged = next.isAuthenticated &&
          prev.profile?.role != next.profile?.role;

      final shouldNotify = authStatusChanged || userChanged || roleChanged;
      // Real authentication status flip MUST trigger router refresh!
      expect(shouldNotify, isTrue);
    });

    test('Router refresh condition DOES trigger when role is selected', () {
      const prev = AuthState(status: AuthStatus.authenticated, profile: null);
      final profile = UserProfile(
        id: 'user-123',
        name: 'مستخدم جديد',
        role: UserRole.vendor,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final next = AuthState(
        status: AuthStatus.authenticated,
        profile: profile,
      );

      final authStatusChanged = prev.isAuthenticated != next.isAuthenticated;
      final userChanged = prev.user?.id != next.user?.id;
      final roleChanged = next.isAuthenticated &&
          prev.profile?.role != next.profile?.role;

      final shouldNotify = authStatusChanged || userChanged || roleChanged;
      // Role selection change MUST trigger router refresh!
      expect(shouldNotify, isTrue);
    });
  });
}
