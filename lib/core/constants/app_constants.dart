/// Application-wide constants for ست الكل.
abstract final class AppConstants {
  AppConstants._();

  // ── Branding ──────────────────────────────────────────────────────────────
  static const String appName = 'ست الكل';
  static const String appNameEn = 'Set El Kol';
  static const String tagline = 'أكل بيتي من إيد ستات مصر';

  // ── Supabase Storage Buckets ───────────────────────────────────────────────
  static const String bucketAvatars = 'avatars';
  static const String bucketFoodImages = 'food-images';
  static const String bucketPaymentProofs = 'payment-proofs';

  // ── Image Handling ────────────────────────────────────────────────────────
  /// Maximum allowed file size in megabytes before compression is rejected.
  static const double maxImageSizeMb = 5.0;

  /// Maximum width/height in pixels after compression.
  static const int maxImageDimension = 1200;

  /// JPEG compression quality (0–100).
  static const int imageQuality = 85;

  // ── Delivery ──────────────────────────────────────────────────────────────
  static const double defaultDeliveryRadiusKm = 10.0;

  // ── Cart / Ordering ───────────────────────────────────────────────────────
  static const double minOrderAmount = 0.0;
  static const int maxCartItemsPerProduct = 20;

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int pageSize = 20;

  // ── Polling ───────────────────────────────────────────────────────────────
  /// How often (in seconds) to poll for order status updates.
  static const int orderStatusPollIntervalSec = 30;

  // ── Geography ─────────────────────────────────────────────────────────────
  /// All 27 Egyptian governorates in Arabic.
  static const List<String> egyptGovernorates = [
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'الدقهلية',
    'البحر الأحمر',
    'البحيرة',
    'الفيوم',
    'الغربية',
    'الإسماعيلية',
    'المنوفية',
    'المنيا',
    'القليوبية',
    'الوادي الجديد',
    'السويس',
    'أسوان',
    'أسيوط',
    'بني سويف',
    'بورسعيد',
    'دمياط',
    'جنوب سيناء',
    'كفر الشيخ',
    'مطروح',
    'الأقصر',
    'قنا',
    'شمال سيناء',
    'سوهاج',
    'الشرقية',
  ];
}
