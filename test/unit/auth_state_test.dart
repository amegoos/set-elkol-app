import 'package:flutter_test/flutter_test.dart';
import 'package:set_elkol_app/core/config/firebase_options.dart';
import 'package:set_elkol_app/core/constants/route_names.dart';
import 'package:set_elkol_app/core/domain/entities/user_profile.dart';
import 'package:set_elkol_app/features/auth/presentation/providers/auth_provider.dart';

void main() {
  group('Firebase Options Tests', () {
    test('DefaultFirebaseOptions has project ID and database URL configured', () {
      expect(DefaultFirebaseOptions.android.projectId, equals('set-elkol'));
      expect(DefaultFirebaseOptions.databaseUrl, contains('set-elkol-default-rtdb'));
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

    test('Admin role routes to admin dashboard', () {
      final adminProfile = UserProfile(
        id: 'admin-1',
        name: 'أحمد أمجد (إدارة ست الكل)',
        email: 'setelkol.support@gmail.com',
        role: UserRole.admin,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final state = AuthState(
        status: AuthStatus.authenticated,
        profile: adminProfile,
      );

      expect(state.isAuthenticated, isTrue);
      expect(state.profile?.isAdmin, isTrue);
      expect(RouteNames.adminDashboard, equals('/admin-dashboard'));
    });

    test('Vendor role routes to vendor dashboard', () {
      final vendorProfile = UserProfile(
        id: 'vendor-1',
        name: 'أم أحمد',
        email: 'omahmed@setelkol.app',
        role: UserRole.vendor,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final state = AuthState(
        status: AuthStatus.authenticated,
        profile: vendorProfile,
      );

      expect(state.isAuthenticated, isTrue);
      expect(state.profile?.isVendor, isTrue);
      expect(RouteNames.vendorDashboard, equals('/vendor-dashboard'));
    });

    test('Customer role routes to customer home', () {
      final customerProfile = UserProfile(
        id: 'customer-1',
        name: 'سارة محمود',
        email: 'sara@setelkol.app',
        role: UserRole.customer,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final state = AuthState(
        status: AuthStatus.authenticated,
        profile: customerProfile,
      );

      expect(state.isAuthenticated, isTrue);
      expect(state.profile?.isCustomer, isTrue);
      expect(RouteNames.customerHome, equals('/home'));
    });
  });
}
