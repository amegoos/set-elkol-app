import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/shared_preferences_provider.dart';

// ── Locale Provider ──────────────────────────────────────────────────────────

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'app_locale';

  static Locale _load(SharedPreferences prefs) {
    final code = prefs.getString(_key);
    if (code == 'en') return const Locale('en');
    return const Locale('ar'); // Arabic default
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_key, locale.languageCode);
    state = locale;
  }

  void toggleLocale() {
    if (state.languageCode == 'ar') {
      setLocale(const Locale('en'));
    } else {
      setLocale(const Locale('ar'));
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

// ── Localization Config ───────────────────────────────────────────────────────

abstract final class AppLocalizationConfig {
  static const List<Locale> supportedLocales = [
    Locale('ar'),
    Locale('en'),
  ];

  static const List<LocalizationsDelegate<dynamic>> delegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}

// ── Simple inline strings (no ARB needed for MVP) ────────────────────────────

class AppStrings {
  static const Map<String, Map<String, String>> _data = {
    'ar': {
      'appName': 'ست الكل',
      'tagline': 'أكل بيتي من إيد ستات مصر',
      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'name': 'الاسم',
      'phone': 'رقم الهاتف',
      'forgotPassword': 'نسيت كلمة المرور؟',
      'sendResetLink': 'إرسال رابط الاسترداد',
      'continueWithGoogle': 'المتابعة مع Google',
      'orDivider': 'أو',
      'customer': 'عميل',
      'vendor': 'بائع',
      'chooseRole': 'اختر دورك',
      'iAmCustomer': 'أنا عميل أريد الطلب',
      'iAmVendor': 'أنا بائع أريد البيع',
      'home': 'الرئيسية',
      'search': 'بحث',
      'cart': 'السلة',
      'orders': 'طلباتي',
      'profile': 'حسابي',
      'searchHint': 'ابحث عن أكل أو بائع...',
      'categories': 'الأقسام',
      'featured': 'المميز',
      'popular': 'الأكثر طلباً',
      'nearbyVendors': 'بائعين قريبين',
      'addToCart': 'أضف للسلة',
      'checkout': 'إتمام الطلب',
      'placeOrder': 'تأكيد الطلب',
      'orderPlaced': 'تم الطلب!',
      'totalAmount': 'الإجمالي',
      'deliveryFee': 'رسوم التوصيل',
      'subtotal': 'المجموع الفرعي',
      'paymentMethod': 'طريقة الدفع',
      'cash': 'كاش عند الاستلام',
      'instapay': 'InstaPay',
      'vodafoneCash': 'فودافون كاش',
      'address': 'العنوان',
      'addAddress': 'أضف عنوان',
      'deliveryNote': 'ملاحظات التوصيل',
      'orderStatus': 'حالة الطلب',
      'pending': 'في الانتظار',
      'accepted': 'مقبول',
      'preparing': 'قيد التحضير',
      'ready': 'جاهز',
      'outForDelivery': 'في الطريق إليك',
      'delivered': 'تم التسليم',
      'cancelled': 'ملغي',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'save': 'حفظ',
      'edit': 'تعديل',
      'delete': 'حذف',
      'loading': 'جاري التحميل...',
      'retry': 'إعادة المحاولة',
      'noResults': 'لا توجد نتائج',
      'emptyCart': 'السلة فارغة',
      'emptyOrders': 'لا توجد طلبات',
      'emptyFavorites': 'لا توجد مفضلة',
      'dashboard': 'لوحة التحكم',
      'myProducts': 'منتجاتي',
      'myOrders': 'طلباتي',
      'earnings': 'الأرباح',
      'addProduct': 'إضافة منتج',
      'productName': 'اسم المنتج',
      'productDescription': 'وصف المنتج',
      'price': 'السعر',
      'egp': 'ج.م',
      'notifications': 'الإشعارات',
      'logout': 'تسجيل الخروج',
      'logoutConfirm': 'هل تريد تسجيل الخروج؟',
      'yes': 'نعم',
      'no': 'لا',
      'errorGeneral': 'حدث خطأ، حاول مرة أخرى',
      'errorNetwork': 'تحقق من الاتصال بالإنترنت',
      'errorInvalidEmail': 'بريد إلكتروني غير صحيح',
      'errorWeakPassword': 'كلمة المرور يجب أن تكون 8 أحرف على الأقل',
      'errorEmptyField': 'هذا الحقل مطلوب',
      'successResetEmail': 'تم إرسال رابط الاسترداد على بريدك',
      'becomeVendor': 'أصبح بائعاً',
      'vendorSetup': 'إعداد متجرك',
      'storeName': 'اسم المتجر',
      'storeDescription': 'وصف المتجر',
      'deliveryOptions': 'خيارات التوصيل',
      'delivery': 'توصيل',
      'pickup': 'استلام ذاتي',
      'governorate': 'المحافظة',
      'area': 'المنطقة',
      'minOrder': 'الحد الأدنى للطلب',
      'deliveryFeeLabel': 'رسوم التوصيل',
      'today': 'اليوم',
      'thisWeek': 'هذا الأسبوع',
      'thisMonth': 'هذا الشهر',
      'totalSales': 'إجمالي المبيعات',
      'totalOrders': 'إجمالي الطلبات',
      'rating': 'التقييم',
      'reviews': 'التقييمات',
      'writeReview': 'اكتب تقييمك',
      'favorites': 'المفضلة',
      'myAddresses': 'عناوين التوصيل',
      'accountSettings': 'إعدادات الحساب',
      'language': 'اللغة',
      'arabic': 'العربية',
      'english': 'English',
    },
    'en': {
      'appName': 'Set El Kol',
      'tagline': 'Homemade food from Egyptian mothers',
      'login': 'Login',
      'signup': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'name': 'Name',
      'phone': 'Phone',
      'forgotPassword': 'Forgot Password?',
      'sendResetLink': 'Send Reset Link',
      'continueWithGoogle': 'Continue with Google',
      'orDivider': 'or',
      'customer': 'Customer',
      'vendor': 'Vendor',
      'chooseRole': 'Choose Your Role',
      'iAmCustomer': 'I want to order food',
      'iAmVendor': 'I want to sell food',
      'home': 'Home',
      'search': 'Search',
      'cart': 'Cart',
      'orders': 'Orders',
      'profile': 'Profile',
      'searchHint': 'Search for food or vendors...',
      'categories': 'Categories',
      'featured': 'Featured',
      'popular': 'Popular',
      'nearbyVendors': 'Nearby Vendors',
      'addToCart': 'Add to Cart',
      'checkout': 'Checkout',
      'placeOrder': 'Place Order',
      'orderPlaced': 'Order Placed!',
      'totalAmount': 'Total',
      'deliveryFee': 'Delivery Fee',
      'subtotal': 'Subtotal',
      'paymentMethod': 'Payment Method',
      'cash': 'Cash on Delivery',
      'instapay': 'InstaPay',
      'vodafoneCash': 'Vodafone Cash',
      'address': 'Address',
      'addAddress': 'Add Address',
      'deliveryNote': 'Delivery Notes',
      'orderStatus': 'Order Status',
      'pending': 'Pending',
      'accepted': 'Accepted',
      'preparing': 'Preparing',
      'ready': 'Ready',
      'outForDelivery': 'Out for Delivery',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
      'loading': 'Loading...',
      'retry': 'Retry',
      'noResults': 'No results found',
      'emptyCart': 'Your cart is empty',
      'emptyOrders': 'No orders yet',
      'emptyFavorites': 'No favorites yet',
      'dashboard': 'Dashboard',
      'myProducts': 'My Products',
      'myOrders': 'My Orders',
      'earnings': 'Earnings',
      'addProduct': 'Add Product',
      'productName': 'Product Name',
      'productDescription': 'Product Description',
      'price': 'Price',
      'egp': 'EGP',
      'notifications': 'Notifications',
      'logout': 'Logout',
      'logoutConfirm': 'Are you sure you want to logout?',
      'yes': 'Yes',
      'no': 'No',
      'errorGeneral': 'Something went wrong, please try again',
      'errorNetwork': 'Check your internet connection',
      'errorInvalidEmail': 'Invalid email address',
      'errorWeakPassword': 'Password must be at least 8 characters',
      'errorEmptyField': 'This field is required',
      'successResetEmail': 'Reset link sent to your email',
      'becomeVendor': 'Become a Vendor',
      'vendorSetup': 'Setup Your Store',
      'storeName': 'Store Name',
      'storeDescription': 'Store Description',
      'deliveryOptions': 'Delivery Options',
      'delivery': 'Delivery',
      'pickup': 'Pickup',
      'governorate': 'Governorate',
      'area': 'Area',
      'minOrder': 'Minimum Order',
      'deliveryFeeLabel': 'Delivery Fee',
      'today': 'Today',
      'thisWeek': 'This Week',
      'thisMonth': 'This Month',
      'totalSales': 'Total Sales',
      'totalOrders': 'Total Orders',
      'rating': 'Rating',
      'reviews': 'Reviews',
      'writeReview': 'Write a Review',
      'favorites': 'Favorites',
      'myAddresses': 'My Addresses',
      'accountSettings': 'Account Settings',
      'language': 'Language',
      'arabic': 'Arabic',
      'english': 'English',
    },
  };

  static String get(BuildContext context, String key) {
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode == 'en' ? 'en' : 'ar';
    return _data[lang]?[key] ?? _data['ar']?[key] ?? key;
  }
}

// Extension for convenience
extension StringLocalization on String {
  String tr(BuildContext context) => AppStrings.get(context, this);
}
