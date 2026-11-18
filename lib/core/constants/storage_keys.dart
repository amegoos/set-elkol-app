/// SharedPreferences / secure-storage key constants.
/// Centralising keys prevents typo-based runtime bugs.
abstract final class StorageKeys {
  StorageKeys._();

  /// Whether the user has already seen the onboarding flow.
  static const String onboardingSeen = 'onboarding_seen';

  /// BCP-47 locale tag selected by the user (e.g. 'ar', 'en').
  static const String selectedLocale = 'selected_locale';

  /// Role chosen at registration: 'customer' | 'vendor'.
  static const String selectedRole = 'selected_role';

  /// Firebase user UID cached for quick local checks.
  static const String cachedUserId = 'cached_user_id';

  /// The vendor UUID whose items are currently in the cart.
  /// Used to enforce single-vendor cart constraint.
  static const String cartVendorId = 'cart_vendor_id';

  /// Tracks if the user intentionally logged out so the app does not auto-login.
  static const String explicitlyLoggedOut = 'explicitly_logged_out';
}
