import 'package:equatable/equatable.dart';

enum PromoCodeType {
  percentage,
  fixedAmount,
  freeDelivery;

  static PromoCodeType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'percentage':
        return PromoCodeType.percentage;
      case 'fixed_amount':
      case 'fixedamount':
        return PromoCodeType.fixedAmount;
      case 'free_delivery':
      case 'freedelivery':
        return PromoCodeType.freeDelivery;
      default:
        return PromoCodeType.percentage;
    }
  }

  String get dbValue {
    switch (this) {
      case PromoCodeType.percentage:
        return 'percentage';
      case PromoCodeType.fixedAmount:
        return 'fixed_amount';
      case PromoCodeType.freeDelivery:
        return 'free_delivery';
    }
  }
}

class PromoCode extends Equatable {
  const PromoCode({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minOrderAmount = 0,
    this.maxDiscount,
    this.usageLimit,
    this.usageCount = 0,
    this.userUsageLimit = 1,
    required this.validFrom,
    required this.validUntil,
    this.isActive = true,
    this.applicableVendors,
    this.applicableCategories,
  });

  final String id;
  final String code;
  final PromoCodeType type;
  final double value;
  final double minOrderAmount;
  final double? maxDiscount;
  final int? usageLimit;
  final int usageCount;
  final int userUsageLimit;
  final DateTime validFrom;
  final DateTime validUntil;
  final bool isActive;
  final List<String>? applicableVendors;
  final List<String>? applicableCategories;

  factory PromoCode.fromJson(Map<String, dynamic> json) {
    return PromoCode(
      id: json['id'] as String? ?? '',
      code: (json['code'] as String? ?? '').toUpperCase().trim(),
      type: PromoCodeType.fromString(json['type'] as String? ?? 'percentage'),
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (json['max_discount'] as num?)?.toDouble(),
      usageLimit: json['usage_limit'] as int?,
      usageCount: json['usage_count'] as int? ?? 0,
      userUsageLimit: json['user_usage_limit'] as int? ?? 1,
      validFrom: DateTime.tryParse(json['valid_from'] as String? ?? '') ??
          DateTime.now(),
      validUntil: DateTime.tryParse(json['valid_until'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 30)),
      isActive: json['is_active'] as bool? ?? true,
      applicableVendors: (json['applicable_vendors'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      applicableCategories: (json['applicable_categories'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'type': type.dbValue,
      'value': value,
      'min_order_amount': minOrderAmount,
      'max_discount': maxDiscount,
      'usage_limit': usageLimit,
      'usage_count': usageCount,
      'user_usage_limit': userUsageLimit,
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'is_active': isActive,
      'applicable_vendors': applicableVendors,
      'applicable_categories': applicableCategories,
    };
  }

  @override
  List<Object?> get props => [
        id,
        code,
        type,
        value,
        minOrderAmount,
        maxDiscount,
        usageLimit,
        usageCount,
        userUsageLimit,
        validFrom,
        validUntil,
        isActive,
        applicableVendors,
        applicableCategories,
      ];
}

class PromoValidationResult {
  const PromoValidationResult({
    required this.isValid,
    this.discountAmount = 0.0,
    this.isFreeDelivery = false,
    this.errorMessage,
    this.promo,
  });

  final bool isValid;
  final double discountAmount;
  final bool isFreeDelivery;
  final String? errorMessage;
  final PromoCode? promo;

  factory PromoValidationResult.failure(String message) {
    return PromoValidationResult(
      isValid: false,
      errorMessage: message,
    );
  }

  factory PromoValidationResult.success({
    required PromoCode promo,
    required double discountAmount,
    bool isFreeDelivery = false,
  }) {
    return PromoValidationResult(
      isValid: true,
      discountAmount: discountAmount,
      isFreeDelivery: isFreeDelivery,
      promo: promo,
    );
  }
}

class PromoValidator {
  static PromoValidationResult validate({
    required PromoCode promo,
    required double subtotal,
    required String vendorId,
    String? categoryId,
    required String userId,
    int userUsageCount = 0,
    double deliveryFee = 0.0,
  }) {
    final now = DateTime.now();

    // 1. Is active check
    if (!promo.isActive) {
      return PromoValidationResult.failure('كود الخصم غير فعال حالياً');
    }

    // 2. Date range check
    if (now.isBefore(promo.validFrom)) {
      return PromoValidationResult.failure('كود الخصم غير متاح بعد');
    }
    if (now.isAfter(promo.validUntil)) {
      return PromoValidationResult.failure('انتهت صلاحية كود الخصم هذا');
    }

    // 3. Minimum order amount
    if (subtotal < promo.minOrderAmount) {
      return PromoValidationResult.failure(
        'الحد الأدنى للطلب لتطبيق هذا الكود هو ${promo.minOrderAmount.toStringAsFixed(0)} ج.م',
      );
    }

    // 4. Global usage limit
    if (promo.usageLimit != null && promo.usageCount >= promo.usageLimit!) {
      return PromoValidationResult.failure(
          'تم استنفاد الحد الأقصى لاستخدام هذا الكود');
    }

    // 5. Per user usage limit
    if (userUsageCount >= promo.userUsageLimit) {
      return PromoValidationResult.failure(
          'لقد استنفدت الحد المسموح لك لاستخدام هذا الكود');
    }

    // 6. Applicable vendors
    if (promo.applicableVendors != null &&
        promo.applicableVendors!.isNotEmpty &&
        !promo.applicableVendors!.contains(vendorId)) {
      return PromoValidationResult.failure(
          'هذا الكود غير ساري مع المطبخ المختار');
    }

    // 7. Applicable categories
    if (promo.applicableCategories != null &&
        promo.applicableCategories!.isNotEmpty &&
        (categoryId == null ||
            !promo.applicableCategories!.contains(categoryId))) {
      return PromoValidationResult.failure(
          'هذا الكود غير ساري على هذا التصنيف');
    }

    // 8. Calculate discount
    double calculatedDiscount = 0.0;
    bool isFreeDelivery = false;

    switch (promo.type) {
      case PromoCodeType.percentage:
        calculatedDiscount = (subtotal * promo.value) / 100.0;
        if (promo.maxDiscount != null &&
            calculatedDiscount > promo.maxDiscount!) {
          calculatedDiscount = promo.maxDiscount!;
        }
        break;
      case PromoCodeType.fixedAmount:
        calculatedDiscount = promo.value > subtotal ? subtotal : promo.value;
        break;
      case PromoCodeType.freeDelivery:
        isFreeDelivery = true;
        calculatedDiscount = deliveryFee;
        break;
    }

    return PromoValidationResult.success(
      promo: promo,
      discountAmount: calculatedDiscount,
      isFreeDelivery: isFreeDelivery,
    );
  }
}
