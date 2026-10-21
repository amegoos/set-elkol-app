import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/promo_code.dart';
import '../network/supabase_client.dart';

class PromoService {
  final SupabaseClient _client;

  PromoService(this._client);

  // Fallback demo promo codes
  static final List<PromoCode> demoPromoCodes = [
    PromoCode(
      id: 'demo-promo-1',
      code: 'SETELKOL20',
      type: PromoCodeType.percentage,
      value: 20.0,
      minOrderAmount: 100.0,
      maxDiscount: 50.0,
      usageLimit: 1000,
      usageCount: 45,
      userUsageLimit: 2,
      validFrom: DateTime.now().subtract(const Duration(days: 10)),
      validUntil: DateTime.now().add(const Duration(days: 60)),
      isActive: true,
    ),
    PromoCode(
      id: 'demo-promo-2',
      code: 'WELCOME50',
      type: PromoCodeType.fixedAmount,
      value: 50.0,
      minOrderAmount: 150.0,
      usageLimit: 500,
      usageCount: 12,
      userUsageLimit: 1,
      validFrom: DateTime.now().subtract(const Duration(days: 5)),
      validUntil: DateTime.now().add(const Duration(days: 90)),
      isActive: true,
    ),
    PromoCode(
      id: 'demo-promo-3',
      code: 'FREEDELIVERY',
      type: PromoCodeType.freeDelivery,
      value: 0.0,
      minOrderAmount: 80.0,
      usageLimit: 200,
      usageCount: 30,
      userUsageLimit: 3,
      validFrom: DateTime.now().subtract(const Duration(days: 2)),
      validUntil: DateTime.now().add(const Duration(days: 30)),
      isActive: true,
    ),
  ];

  /// Validate promo code entered by user
  Future<PromoValidationResult> validatePromoCode({
    required String code,
    required double subtotal,
    required String vendorId,
    String? categoryId,
    required String userId,
    double deliveryFee = 0.0,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return PromoValidationResult.failure('يرجى إدخال كود الخصم');
    }

    try {
      // 1. Fetch promo code from Supabase
      final data = await _client
          .from('promo_codes')
          .select()
          .eq('code', cleanCode)
          .maybeSingle();

      PromoCode? promo;
      int userUsageCount = 0;

      if (data != null) {
        promo = PromoCode.fromJson(data);

        // Fetch user usage count
        final usageData = await _client
            .from('promo_code_usage')
            .select('id')
            .eq('promo_code_id', promo.id)
            .eq('user_id', userId);
        userUsageCount = (usageData as List).length;
      } else {
        // Fallback to demo codes
        final found = demoPromoCodes.where((p) => p.code == cleanCode);
        if (found.isNotEmpty) {
          promo = found.first;
        }
      }

      if (promo == null) {
        return PromoValidationResult.failure('كود الخصم غير صحيح أو غير موجود');
      }

      return PromoValidator.validate(
        promo: promo,
        subtotal: subtotal,
        vendorId: vendorId,
        categoryId: categoryId,
        userId: userId,
        userUsageCount: userUsageCount,
        deliveryFee: deliveryFee,
      );
    } catch (e) {
      debugPrint('[PromoService] Validation error: $e');
      // Graceful fallback to demo codes on error
      final found = demoPromoCodes.where((p) => p.code == cleanCode);
      if (found.isNotEmpty) {
        return PromoValidator.validate(
          promo: found.first,
          subtotal: subtotal,
          vendorId: vendorId,
          categoryId: categoryId,
          userId: userId,
          userUsageCount: 0,
          deliveryFee: deliveryFee,
        );
      }
      return PromoValidationResult.failure('تعذر التحقق من كود الخصم: $e');
    }
  }

  /// Record promo code usage after order completion
  Future<void> recordUsage({
    required String promoCodeId,
    required String userId,
    required String orderId,
    required double discountAmount,
  }) async {
    try {
      await _client.from('promo_code_usage').insert({
        'promo_code_id': promoCodeId,
        'user_id': userId,
        'order_id': orderId,
        'discount_amount': discountAmount,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Increment usage count in promo_codes table
      await _client.rpc('increment_promo_usage', params: {
        'code_id': promoCodeId,
      });
    } catch (e) {
      debugPrint('[PromoService] Record usage error: $e');
    }
  }

  /// Get all promo codes for Admin management
  Future<List<PromoCode>> getAllPromoCodes() async {
    try {
      final data = await _client
          .from('promo_codes')
          .select()
          .order('created_at', ascending: false);

      final list = (data as List)
          .map((e) => PromoCode.fromJson(e as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) return list;
    } catch (e) {
      debugPrint('[PromoService] Error getting promo codes: $e');
    }
    return demoPromoCodes;
  }

  /// Create new promo code (Admin)
  Future<bool> createPromoCode(PromoCode promo) async {
    try {
      await _client.from('promo_codes').insert(promo.toJson());
      return true;
    } catch (e) {
      debugPrint('[PromoService] Create error: $e');
      return false;
    }
  }

  /// Toggle promo code active status (Admin)
  Future<bool> togglePromoStatus(String id, bool isActive) async {
    try {
      await _client.from('promo_codes').update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('[PromoService] Toggle error: $e');
      return false;
    }
  }
}

final promoServiceProvider = Provider<PromoService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PromoService(client);
});

final allPromoCodesProvider = FutureProvider<List<PromoCode>>((ref) async {
  final service = ref.watch(promoServiceProvider);
  return service.getAllPromoCodes();
});
