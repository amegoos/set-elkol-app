import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/route_names.dart';
import '../domain/entities/user_profile.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/role_select_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/phone_login_screen.dart';
import '../../features/auth/presentation/screens/phone_otp_screen.dart';
import '../../features/customer/presentation/screens/customer_shell.dart';
import '../../features/customer/presentation/screens/home_screen.dart';
import '../../features/customer/presentation/screens/search_screen.dart';
import '../../features/customer/presentation/screens/cart_screen.dart';
import '../../features/customer/presentation/screens/orders_screen.dart';
import '../../features/customer/presentation/screens/profile_screen.dart';
import '../../features/customer/presentation/screens/vendor_detail_screen.dart';
import '../../features/customer/presentation/screens/product_detail_screen.dart';
import '../../features/customer/presentation/screens/checkout_screen.dart';
import '../../features/customer/presentation/screens/order_tracking_screen.dart';
import '../../features/customer/presentation/screens/favorites_screen.dart';
import '../../features/customer/presentation/screens/addresses_screen.dart';
import '../../features/customer/presentation/screens/support_screen.dart';
import '../../features/customer/presentation/screens/legal_screen.dart';
import '../../features/vendor/presentation/screens/vendor_shell.dart';
import '../../features/vendor/presentation/screens/vendor_dashboard_screen.dart';
import '../../features/vendor/presentation/screens/vendor_products_screen.dart';
import '../../features/vendor/presentation/screens/vendor_orders_screen.dart';
import '../../features/vendor/presentation/screens/vendor_earnings_screen.dart';
import '../../features/vendor/presentation/screens/vendor_biz_profile_screen.dart';
import '../../features/vendor/presentation/screens/vendor_setup_screen.dart';
import '../../features/vendor/presentation/screens/add_edit_product_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';

/// Bridges Riverpod AuthState changes to GoRouter's refreshListenable.
/// Only notifies when real authentication status, user ID, or user role changes.
/// Crucially ignores transient loading and in-form error transitions, which
/// previously caused screen reloads, disposing of active forms, losing inputs,
/// and dropping user feedback.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      final statusChanged = previous?.status != next.status;
      final authStatusChanged =
          previous?.isAuthenticated != next.isAuthenticated;
      final userChanged = previous?.user?.uid != next?.user?.uid;
      final profileChanged = previous?.profile != next.profile;
      final roleChanged =
          next.isAuthenticated && previous?.profile?.role != next.profile?.role;

      if (statusChanged ||
          authStatusChanged ||
          userChanged ||
          profileChanged ||
          roleChanged) {
        debugPrint(
          '[Router] Refreshing routes: statusChanged=$statusChanged, '
          'authStatusChanged=$authStatusChanged, userChanged=$userChanged, '
          'profileChanged=$profileChanged, roleChanged=$roleChanged '
          '(isAuth=${next.isAuthenticated}, role=${next.profile?.role.name})',
        );
        notifyListeners();
      }
    });
  }

  final Ref _ref;
}

final routerRefreshNotifierProvider = Provider<RouterRefreshNotifier>((ref) {
  return RouterRefreshNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: refreshNotifier,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      final isOnSplash = state.matchedLocation == RouteNames.splash;
      final isOnAuth = state.matchedLocation == RouteNames.login ||
          state.matchedLocation == RouteNames.register;
      final isOnPhoneLogin = state.matchedLocation == RouteNames.phoneLogin;
      final isOnPhoneOtp = state.matchedLocation == RouteNames.phoneOtp;
      final isOnRoleSelect = state.matchedLocation == RouteNames.roleSelect;
      final isOnForgot = state.matchedLocation == RouteNames.forgotPassword;
      final isOnVendorSetup = state.matchedLocation == RouteNames.vendorSetup;
      final isOnLoginCallback =
          state.matchedLocation == RouteNames.loginCallback;

      // Do not interrupt while initial session check is running or an operation is in flight
      if (authState.status == AuthStatus.initial) return null;
      if (authState.status == AuthStatus.loading) return null;

      final isAuth = authState.isAuthenticated;
      final profile = authState.profile;

      if (!isAuth) {
        // Not authenticated – allow splash, auth, phone, forgot, or login callback
        if (isOnSplash ||
            isOnAuth ||
            isOnForgot ||
            isOnPhoneLogin ||
            isOnPhoneOtp ||
            isOnLoginCallback) {
          return null;
        }
        return RouteNames.login;
      }

      // Authenticated but no profile/role set yet â†’ navigate to role selection
      if (isAuth && profile == null) {
        if (isOnRoleSelect) return null;
        debugPrint(
            '[Router] Redirecting authenticated user without role to ${RouteNames.roleSelect}');
        return RouteNames.roleSelect;
      }

      // Authenticated with role â†’ navigate to corresponding dashboard
      if (isAuth && profile != null) {
        if (isOnSplash ||
            isOnAuth ||
            isOnRoleSelect ||
            isOnPhoneLogin ||
            isOnPhoneOtp ||
            isOnLoginCallback) {
          if (profile.isAdmin) return RouteNames.adminDashboard;
          final target = profile.isVendor
              ? RouteNames.vendorDashboard
              : RouteNames.customerHome;
          debugPrint(
              '[Router] Redirecting authenticated user (${profile.role.name}) to $target');
          return target;
        }
        // Vendor setup flow is permitted for vendors
        if (isOnVendorSetup) return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (_, __) => const AuthScreen(),
      ),
      GoRoute(
        path: RouteNames.phoneLogin,
        builder: (_, __) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: RouteNames.phoneOtp,
        builder: (_, state) {
          final phone = state.extra as String? ?? '';
          return PhoneOtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: RouteNames.loginCallback,
        builder: (_, __) => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.roleSelect,
        builder: (_, __) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorSetup,
        builder: (_, __) => const VendorSetupScreen(),
      ),

      // â”€â”€ Customer Shell â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => CustomerShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.customerHome,
              builder: (_, __) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'vendor/:vendorId',
                  builder: (_, state) => VendorDetailScreen(
                    vendorId: state.pathParameters['vendorId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'product/:productId',
                      builder: (_, state) => ProductDetailScreen(
                        productId: state.pathParameters['productId']!,
                        vendorId: state.pathParameters['vendorId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.search,
              builder: (_, __) => const SearchScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.cart,
              builder: (_, __) => const CartScreen(),
              routes: [
                GoRoute(
                  path: 'checkout',
                  builder: (_, __) => const CheckoutScreen(),
                ),
                GoRoute(
                  path: 'order-confirm/:orderId',
                  builder: (_, state) => OrderTrackingScreen(
                    orderId: state.pathParameters['orderId']!,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.customerOrders,
              builder: (_, __) => const OrdersScreen(),
              routes: [
                GoRoute(
                  path: ':orderId',
                  builder: (_, state) => OrderTrackingScreen(
                    orderId: state.pathParameters['orderId']!,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.customerProfile,
              builder: (_, __) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'favorites',
                  builder: (_, __) => const FavoritesScreen(),
                ),
                GoRoute(
                  path: 'addresses',
                  builder: (_, __) => const AddressesScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),

      // â”€â”€ Vendor Shell â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => VendorShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.vendorDashboard,
              builder: (_, __) => const VendorDashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.vendorProducts,
              builder: (_, __) => const VendorProductsScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (_, __) => const AddEditProductScreen(),
                ),
                GoRoute(
                  path: ':productId/edit',
                  builder: (_, state) => AddEditProductScreen(
                    productId: state.pathParameters['productId'],
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.vendorOrders,
              builder: (_, __) => const VendorOrdersScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.vendorEarnings,
              builder: (_, __) => const VendorEarningsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.vendorBizProfile,
              builder: (_, __) => const VendorBizProfileScreen(),
            ),
          ]),
        ],
      ),

      GoRoute(
        path: RouteNames.orderTracking,
        builder: (_, state) => OrderTrackingScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RouteNames.support,
        builder: (_, __) => const SupportScreen(),
      ),
      GoRoute(
        path: RouteNames.legal,
        builder: (_, __) => const LegalScreen(),
      ),
      GoRoute(
        path: RouteNames.adminDashboard,
        builder: (_, __) => const AdminDashboardScreen(),
      ),
    ],
  );
});
