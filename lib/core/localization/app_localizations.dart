import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/shared_preferences_provider.dart';

// — Locale Provider —

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

// — Localization Config —

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

// — Inline authentic strings —

class AppStrings {
  static const Map<String, Map<String, String>> _data = {
    'ar': {
      'appName': 'ست الكل',
      'tagline': 'أكل بيتي مصري من إيد أمهاتنا',
      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب جديد',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'name': 'الاسم بالكامل',
      'phone': 'رقم الموبايل',
      'forgotPassword': 'نسيت كلمة المرور؟',
      'sendResetLink': 'إرسال رابط الاستعادة',
      'continueWithGoogle': 'المتابعة مع Google',
      'orDivider': 'أو',
      'customer': 'عميل',
      'vendor': 'طاهية / بائعة',
      'chooseRole': 'اختاري صفتك',
      'iAmCustomer': 'أريد طلب واستكشاف الأكل البيتي',
      'iAmVendor': 'أريد بيع وعرض طبخاتي اللذيذة',
      'home': 'الرئيسية',
      'search': 'بحث',
      'cart': 'السلة',
      'orders': 'طلباتي',
      'profile': 'حسابي',
      'searchHint': 'ابحثي عن وجبة، ملوخية، محشي، طاجن...',
      'categories': 'الأقسام',
      'featured': 'مميز اليوم',
      'popular': 'الأكثر طلباً',
      'nearbyVendors': 'مطابخ قريبة منك',
      'addToCart': 'أضف للسلة',
      'checkout': 'إتمام الطلب',
      'placeOrder': 'تأكيد ودفع الطلب',
      'orderPlaced': 'تم إرسال طلبك بنجاح!',
      'totalAmount': 'الإجمالي',
      'deliveryFee': 'رسوم التوصيل',
      'subtotal': 'المجموع الفرعي',
      'paymentMethod': 'طريقة الدفع',
      'cash': 'الدفع كاش عند الاستلام',
      'instapay': 'إنستاباي (InstaPay)',
      'vodafoneCash': 'فودافون كاش / محافظ إلكترونية',
      'address': 'العنوان',
      'addAddress': 'إضافة عنوان جديد',
      'deliveryNote': 'ملاحظات خاصة للطبخ أو التوصيل',
      'orderStatus': 'حالة الطلب',
      'pending': 'قيد الانتظار',
      'accepted': 'تم قبول الطلب',
      'preparing': 'جاري التحضير بالمطبخ',
      'ready': 'الأكل جاهز للتسليم',
      'outForDelivery': 'خرج مع المندوب',
      'delivered': 'تم التوصيل بنجاح',
      'cancelled': 'تم الإلغاء',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'save': 'حفظ',
      'edit': 'تعديل',
      'delete': 'حذف',
      'loading': 'جاري التحميل...',
      'retry': 'إعادة المحاولة',
      'noResults': 'لا توجد نتائج مطابقة',
      'emptyCart': 'سلة مشترياتك فارغة',
      'emptyOrders': 'لا توجد طلبات سابقة',
      'emptyFavorites': 'لا توجد عناصر في المفضلة',
      'dashboard': 'لوحة التحكم',
      'myProducts': 'أكلاتي ومنتجاتي',
      'myOrders': 'إدارة الطلبات',
      'earnings': 'الأرباح والمبيعات',
      'addProduct': 'إضافة صنف جديد',
      'productName': 'اسم الصنف أو الوجبة',
      'productDescription': 'وصف الوجبة ومكوناتها',
      'price': 'السعر',
      'egp': 'ج.م',
      'notifications': 'الإشعارات',
      'logout': 'تسجيل الخروج',
      'logoutConfirm': 'هل أنتِ متأكدة من تسجيل الخروج؟',
      'yes': 'نعم',
      'no': 'لا',
      'errorGeneral': 'حدث خطأ، يرجى المحاولة مرة أخرى',
      'errorNetwork': 'يرجى التأكد من اتصال الإنترنت',
      'errorInvalidEmail': 'البريد الإلكتروني غير صحيح',
      'errorWeakPassword': 'كلمة المرور يجب ألا تقل عن 8 أحرف',
      'errorEmptyField': 'هذا الحقل مطلوب',
      'successResetEmail': 'تم إرسال رابط استعادة كلمة المرور لبريدك',
      'becomeVendor': 'انضمي كطاهية بائعة',
      'vendorSetup': 'إعداد وتجهيز المطبخ',
      'storeName': 'اسم المطبخ أو المشروع',
      'storeDescription': 'نبذة عن مطبخك وتخصصك',
      'deliveryOptions': 'خيارات التوصيل',
      'delivery': 'توصيل للمنزل',
      'pickup': 'استلام يدوي من المطبخ',
      'governorate': 'المحافظة',
      'area': 'المنطقة / الحي',
      'minOrder': 'الحد الأدنى للطلب',
      'deliveryFeeLabel': 'تكلفة التوصيل',
      'today': 'اليوم',
      'thisWeek': 'هذا الأسبوع',
      'thisMonth': 'هذا الشهر',
      'totalSales': 'إجمالي المبيعات',
      'totalOrders': 'عدد الطلبات',
      'rating': 'التقييم العام',
      'reviews': 'آراء العملاء',
      'writeReview': 'اكتبي تقييمك',
      'favorites': 'المفضلة',
      'myAddresses': 'عناويني المحفوظة',
      'accountSettings': 'إعدادات الحساب',
      'language': 'اللغة',
      'arabic': 'العربية',
      'english': 'English',
    },
    'en': {
      'appName': 'Set El Kol',
      'tagline': 'Authentic Homemade Food from Egyptian Mothers',
      'login': 'Login',
      'signup': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'name': 'Full Name',
      'phone': 'Phone Number',
      'forgotPassword': 'Forgot Password?',
      'sendResetLink': 'Send Reset Link',
      'continueWithGoogle': 'Continue with Google',
      'orDivider': 'or',
      'customer': 'Customer',
      'vendor': 'Home Chef / Vendor',
      'chooseRole': 'Choose Your Role',
      'iAmCustomer': 'I want to discover & order homemade food',
      'iAmVendor': 'I want to sell & share my delicious dishes',
      'home': 'Home',
      'search': 'Search',
      'cart': 'Cart',
      'orders': 'Orders',
      'profile': 'Profile',
      'searchHint': 'Search for molokhia, mahshi, tagine...',
      'categories': 'Categories',
      'featured': 'Today\'s Specials',
      'popular': 'Most Ordered',
      'nearbyVendors': 'Nearby Kitchens',
      'addToCart': 'Add to Cart',
      'checkout': 'Checkout',
      'placeOrder': 'Confirm & Place Order',
      'orderPlaced': 'Order Placed Successfully!',
      'totalAmount': 'Total',
      'deliveryFee': 'Delivery Fee',
      'subtotal': 'Subtotal',
      'paymentMethod': 'Payment Method',
      'cash': 'Cash on Delivery',
      'instapay': 'InstaPay Transfer',
      'vodafoneCash': 'Vodafone Cash / Mobile Wallet',
      'address': 'Address',
      'addAddress': 'Add New Address',
      'deliveryNote': 'Special instructions or food notes',
      'orderStatus': 'Order Status',
      'pending': 'Pending Approval',
      'accepted': 'Order Accepted',
      'preparing': 'Preparing in Kitchen',
      'ready': 'Ready for Pickup / Courier',
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
      'dashboard': 'Vendor Dashboard',
      'myProducts': 'My Dishes',
      'myOrders': 'Manage Orders',
      'earnings': 'Sales & Earnings',
      'addProduct': 'Add New Dish',
      'productName': 'Dish Name',
      'productDescription': 'Ingredients & Description',
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
      'successResetEmail': 'Password reset link sent to your email',
      'becomeVendor': 'Start Selling as a Cook',
      'vendorSetup': 'Setup Kitchen Profile',
      'storeName': 'Kitchen / Brand Name',
      'storeDescription': 'Kitchen Story & Specialties',
      'deliveryOptions': 'Delivery Options',
      'delivery': 'Home Delivery',
      'pickup': 'Kitchen Pickup',
      'governorate': 'Governorate',
      'area': 'Area / District',
      'minOrder': 'Minimum Order',
      'deliveryFeeLabel': 'Delivery Fee',
      'today': 'Today',
      'thisWeek': 'This Week',
      'thisMonth': 'This Month',
      'totalSales': 'Total Revenue',
      'totalOrders': 'Total Orders',
      'rating': 'Rating',
      'reviews': 'Customer Reviews',
      'writeReview': 'Write a Review',
      'favorites': 'Favorites',
      'myAddresses': 'Saved Addresses',
      'accountSettings': 'Account Settings',
      'language': 'Language',
      'arabic': 'العربية',
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
