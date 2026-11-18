import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/promo_code.dart';
import '../network/firebase_providers.dart';

class PromoService {
  final FirebaseDatabase _db;

  PromoService(this._db);

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
      // 1. Fetch promo code from Firebase RTDB
      final snapshot = await _db
          .ref('promo_codes')
          .orderByChild('code')
          .equalTo(cleanCode)
          .get();

      PromoCode? promo;
      int userUsageCount = 0;

      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        final entry = data.entries.first;
        final map = Map<String, dynamic>.from(entry.value as Map);
        map['id'] ??= entry.key;
        promo = PromoCode.fromJson(map);

        // Fetch user usage count from `/promo_code_usage`
        final usageSnap = await _db
            .ref('promo_code_usage')
            .orderByChild('user_id')
            .equalTo(userId)
            .get();
        if (usageSnap.exists && usageSnap.value is Map) {
          final usageMap = usageSnap.value as Map;
          userUsageCount = usageMap.values
              .where((v) => (v as Map)['promo_code_id'] == promo!.id)
              .length;
        }
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
      final usageId = _db.ref('promo_code_usage').push().key ??
          'usage_${DateTime.now().millisecondsSinceEpoch}';
      await _db.ref('promo_code_usage/$usageId').set({
        'promo_code_id': promoCodeId,
        'user_id': userId,
        'order_id': orderId,
        'discount_amount': discountAmount,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Increment usage count using Firebase transaction
      final promoRef = _db.ref('promo_codes/$promoCodeId/usage_count');
      await promoRef.runTransaction((mutableData) {
        final current = (mutableData as int?) ?? 0;
        return Transaction.success(current + 1);
      });
    } catch (e) {
      debugPrint('[PromoService] Record usage error: $e');
    }
  }

  /// Get all promo codes for Admin management
  Future<List<PromoCode>> getAllPromoCodes() async {
    try {
      final snapshot = await _db.ref('promo_codes').get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        final list = data.entries.map((e) {
          final map = Map<String, dynamic>.from(e.value as Map);
          map['id'] ??= e.key;
          return PromoCode.fromJson(map);
        }).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('[PromoService] Error getting promo codes: $e');
    }
    return demoPromoCodes;
  }

  /// Create new promo code (Admin)
  Future<bool> createPromoCode(PromoCode promo) async {
    try {
      final id = promo.id.isNotEmpty
          ? promo.id
          : (_db.ref('promo_codes').push().key ??
              'promo_${DateTime.now().millisecondsSinceEpoch}');
      await _db.ref('promo_codes/$id').set(promo.toJson());
      return true;
    } catch (e) {
      debugPrint('[PromoService] Create error: $e');
      return false;
    }
  }

  /// Toggle promo code active status (Admin)
  Future<bool> togglePromoStatus(String id, bool isActive) async {
    try {
      await _db.ref('promo_codes/$id').update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('[PromoService] Toggle error: $e');
      return false;
    }
  }
}

final promoServiceProvider = Provider<PromoService>((ref) {
  final db = ref.watch(firebaseDatabaseProvider);
  return PromoService(db);
});

final allPromoCodesProvider = FutureProvider<List<PromoCode>>((ref) async {
  final service = ref.watch(promoServiceProvider);
  return service.getAllPromoCodes();
});
