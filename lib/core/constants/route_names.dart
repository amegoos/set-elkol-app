/// GoRouter route-path constants for ست الكل.
///
/// Every named route in the router must use one of these constants so that
/// refactoring a path only requires changing it here.
abstract final class RouteNames {
  RouteNames._();

  // ── Auth & Onboarding ─────────────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String roleSelect = '/role-select';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String vendorSetup = '/vendor-setup';
  static const String loginCallback = '/login-callback';
  static const String phoneLogin = '/phone-login';
  static const String phoneOtp = '/phone-otp';

  // ── Customer Shell ────────────────────────────────────────────────────────
  static const String customerHome = '/home';
  static const String search = '/search';
  static const String vendorProfile = '/vendor/:vendorId';
  static const String productDetail = '/vendor/:vendorId/product/:productId';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderConfirm = '/order-confirm/:orderId';
  static const String orderTracking = '/order-tracking/:orderId';
  static const String customerOrders = '/my-orders';
  static const String favorites = '/favorites';
  static const String customerProfile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String addresses = '/profile/addresses';
  static const String addAddress = '/profile/addresses/add';
  static const String support = '/support';
  static const String legal = '/legal';
  static const String rateReview = '/rate/:orderId';

  // ── Vendor Shell ──────────────────────────────────────────────────────────
  static const String vendorDashboard = '/vendor-dashboard';
  static const String vendorProducts = '/vendor-dashboard/products';
  static const String addProduct = '/vendor-dashboard/products/add';
  static const String editProduct =
      '/vendor-dashboard/products/:productId/edit';
  static const String vendorOrders = '/vendor-dashboard/orders';
  static const String vendorOrderDetail = '/vendor-dashboard/orders/:orderId';
  static const String vendorEarnings = '/vendor-dashboard/earnings';

  /// Vendor own business profile page (editable).
  static const String vendorBizProfile = '/vendor-dashboard/profile';

  // ── Admin ──────────────────────────────────────────────────────────────────
  static const String adminDashboard = '/admin-dashboard';

  // ── Shared ────────────────────────────────────────────────────────────────
  static const String notifications = '/notifications';
}
