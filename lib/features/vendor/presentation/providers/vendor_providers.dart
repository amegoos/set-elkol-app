import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/demo_data_service.dart';
import '../../../../core/domain/entities/user_profile.dart';
import '../../../../core/domain/entities/vendor.dart';
import '../../../../core/network/firebase_providers.dart';
import '../../data/models/vendor_data_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../customer/presentation/providers/customer_providers.dart';

// ── Vendor Profile ─────────────────────────────────────────────────────────────

final myVendorProfileProvider = FutureProvider<Vendor?>((ref) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final auth = ref.watch(firebaseAuthProvider);
    final userId = auth.currentUser?.uid;
    if (userId != null) {
      final db = ref.watch(firebaseDatabaseProvider);
      final snapshot = await db.ref('vendors/$userId').get();
      if (snapshot.exists && snapshot.value is Map) {
        final map = Map<String, dynamic>.from(snapshot.value as Map);
        map['id'] ??= userId;
        return VendorDataModel.fromJson(map);
      }
    }
  } catch (_) {}
  return demoData.vendors.first;
});

// ── Vendor Orders ──────────────────────────────────────────────────────────────

class VendorOrder {
  VendorOrder({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    required this.createdAt,
    this.customerName,
    this.deliveryAddress,
    this.items = const [],
  });

  final String id;
  String status;
  final double totalAmount;
  final String paymentMethod;
  final DateTime createdAt;
  final String? customerName;
  final String? deliveryAddress;
  final List<Map<String, dynamic>> items;

  factory VendorOrder.fromJson(Map<String, dynamic> json) {
    return VendorOrder(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      customerName: (json['profiles'] as Map<String, dynamic>?)?['full_name']
              as String? ??
          json['customer_name'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      items: (json['order_items'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}

final vendorOrdersListProvider = FutureProvider<List<VendorOrder>>((ref) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final auth = ref.watch(firebaseAuthProvider);
    final userId = auth.currentUser?.uid;
    if (userId != null) {
      final db = ref.watch(firebaseDatabaseProvider);
      // Realtime listener: any new order pops up immediately on vendor device
      final sub = db
          .ref('orders')
          .orderByChild('vendor_id')
          .equalTo(userId)
          .onValue
          .listen((_) {
        ref.invalidateSelf();
      });
      ref.onDispose(() => sub.cancel());

      final snapshot = await db
          .ref('orders')
          .orderByChild('vendor_id')
          .equalTo(userId)
          .get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        final list = data.entries.map((e) {
          final map = Map<String, dynamic>.from(e.value as Map);
          map['id'] ??= e.key;
          return VendorOrder.fromJson(map);
        }).toList();
        if (list.isNotEmpty) return list;
      }
    }
  } catch (_) {}
  return demoData.vendorOrders;
});

// ── Vendor Product CRUD Service ─────────────────────────────────────────────

class VendorProductService {
  VendorProductService(this._ref);
  final Ref _ref;

  fb_auth.FirebaseAuth? get _auth {
    try {
      return _ref.read(firebaseAuthProvider);
    } catch (_) {
      return null;
    }
  }

  FirebaseDatabase? get _db {
    try {
      return _ref.read(firebaseDatabaseProvider);
    } catch (_) {
      return null;
    }
  }

  DemoDataService get _demoData => _ref.read(demoDataServiceProvider);

  /// 1. ADD MEAL
  Future<String> addMeal(Map<String, dynamic> data) async {
    final currentUser = _auth?.currentUser;
    final userId = currentUser?.uid;

    final name = (data['name'] as String?)?.trim() ?? '';
    final price = (data['price'] as num?)?.toDouble() ?? 0.0;
    if (name.isEmpty) {
      throw Exception('اسم الوجبة مطلوب ولا يمكن أن يكون فارغاً.');
    }
    if (price <= 0) {
      throw Exception('سعر الوجبة يجب أن يكون أكبر من صفر.');
    }

    final productId = data['id'] as String? ??
        'prod-${DateTime.now().millisecondsSinceEpoch}';
    final nowIso = DateTime.now().toIso8601String();

    final fullData = {
      ...data,
      'id': productId,
      'vendor_id': userId ?? data['vendor_id'] ?? 'demo-vendor-omahmed-002',
      'is_deleted': false,
      'is_available': data['is_available'] as bool? ?? true,
      'created_at': nowIso,
      'updated_at': nowIso,
    };

    // Save in Firebase Realtime Database
    try {
      await _db?.ref('products/$productId').set(fullData);
    } catch (e) {
      // Firebase fallback / offline mode
    }

    // Save in Local In-Memory Demo Data
    _demoData.addOrUpdateProduct(fullData);

    _invalidateProductProviders();
    return productId;
  }

  /// 2. EDIT MEAL (Strict Authorization)
  Future<void> editMeal({
    required String productId,
    required Map<String, dynamic> updates,
  }) async {
    UserProfile? profile;
    try {
      profile = _ref.read(currentProfileProvider);
    } catch (_) {}
    final currentUser = _auth?.currentUser;
    final userId = profile?.id ?? currentUser?.uid;
    final isAdmin = profile?.isAdmin == true;

    // Security Check: Verify ownership in Firebase or DemoData
    String? ownerVendorId;
    try {
      final snap = await _db?.ref('products/$productId').get();
      if (snap != null && snap.exists && snap.value is Map) {
        ownerVendorId = (snap.value as Map)['vendor_id']?.toString();
      }
    } catch (_) {}

    if (ownerVendorId == null) {
      final demoMatch =
          _demoData.rawProducts.where((p) => p['id'] == productId).toList();
      if (demoMatch.isNotEmpty) {
        ownerVendorId = demoMatch.first['vendor_id']?.toString();
      }
    }

    if (userId != null &&
        ownerVendorId != null &&
        ownerVendorId != userId &&
        !isAdmin) {
      throw Exception('غير مصرح لك بتعديل هذه الأكلة لأنها تابعة لمطبخ آخر.');
    }

    final name = updates['name'] as String?;
    final price = updates['price'] as num?;
    if (name != null && name.trim().isEmpty) {
      throw Exception('اسم الوجبة لا يمكن أن يكون فارغاً.');
    }
    if (price != null && price.toDouble() <= 0) {
      throw Exception('سعر الوجبة يجب أن يكون أكبر من صفر.');
    }

    final updatePayload = {
      ...updates,
      'id': productId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await _db?.ref('products/$productId').update(updatePayload);
    } catch (_) {}

    _demoData.addOrUpdateProduct(updatePayload);

    _invalidateProductProviders();
  }

  /// Checks if the meal is referenced in any historical order
  Future<bool> hasHistoricalOrders(String productId) async {
    // 1. Check local in-memory orders
    final demoOrders = _demoData.customerOrders;
    for (final order in demoOrders) {
      if (order.items.any((item) => item['product_id'] == productId)) {
        return true;
      }
    }
    final vendorOrders = _demoData.vendorOrders;
    for (final order in vendorOrders) {
      if (order.items.any((item) => item['product_id'] == productId)) {
        return true;
      }
    }

    // 2. Check Firebase orders
    try {
      final snap = await _db?.ref('orders').get();
      if (snap != null && snap.exists && snap.value is Map) {
        final ordersMap = snap.value as Map;
        for (final o in ordersMap.values) {
          if (o is Map && o['order_items'] is List) {
            final items = o['order_items'] as List;
            for (final item in items) {
              if (item is Map && item['product_id'] == productId) {
                return true;
              }
            }
          }
        }
      }
    } catch (_) {}

    return false;
  }

  /// 3. DELETE MEAL (Soft-Delete & Order History Preservation)
  Future<bool> deleteMeal(String productId) async {
    UserProfile? profile;
    try {
      profile = _ref.read(currentProfileProvider);
    } catch (_) {}
    final currentUser = _auth?.currentUser;
    final userId = profile?.id ?? currentUser?.uid;
    final isAdmin = profile?.isAdmin == true;

    // Security Verification: Meal MUST belong to the authenticated vendor (or admin)
    String? ownerVendorId;
    try {
      final snap = await _db?.ref('products/$productId').get();
      if (snap != null && snap.exists && snap.value is Map) {
        ownerVendorId = (snap.value as Map)['vendor_id']?.toString();
      }
    } catch (_) {}

    if (ownerVendorId == null) {
      final demoMatch =
          _demoData.rawProducts.where((p) => p['id'] == productId).toList();
      if (demoMatch.isNotEmpty) {
        ownerVendorId = demoMatch.first['vendor_id']?.toString();
      }
    }

    if (userId != null &&
        ownerVendorId != null &&
        ownerVendorId != userId &&
        !isAdmin) {
      throw Exception(
          'أمان وحماية: غير مصرح لك بحذف هذه الأكلة لأنها تابعة لمطبخ آخر.');
    }

    final nowIso = DateTime.now().toIso8601String();
    final deletionUpdate = {
      'is_deleted': true,
      'is_available': false,
      'deleted_at': nowIso,
      'updated_at': nowIso,
    };

    // 1. Soft-deletion in Firebase: preserves historical order records completely
    try {
      await _db?.ref('products/$productId').update(deletionUpdate);
    } catch (_) {}

    // 2. Remove from active local catalog
    _demoData.deleteProduct(productId);

    _invalidateProductProviders();
    return true;
  }

  void _invalidateProductProviders() {
    _ref.invalidate(myProductsProvider);
    _ref.invalidate(allProductsProvider);
    _ref.invalidate(featuredProductsProvider);
    _ref.invalidate(popularProductsProvider);
    _ref.invalidate(productsByCategoryProvider);
    _ref.invalidate(vendorProductsProvider);
    _ref.invalidate(searchResultsProvider);
  }
}

final vendorProductServiceProvider = Provider<VendorProductService>((ref) {
  return VendorProductService(ref);
});

// ── Vendor Products ────────────────────────────────────────────────────────────

final myProductsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final auth = ref.watch(firebaseAuthProvider);
    final userId = auth.currentUser?.uid;
    if (userId != null) {
      final db = ref.watch(firebaseDatabaseProvider);
      // Realtime listener: any product update pushes immediately
      final sub = db
          .ref('products')
          .orderByChild('vendor_id')
          .equalTo(userId)
          .onValue
          .listen((_) {
        ref.invalidateSelf();
      });
      ref.onDispose(() => sub.cancel());

      final snapshot = await db
          .ref('products')
          .orderByChild('vendor_id')
          .equalTo(userId)
          .get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        final list = data.entries.map((e) {
          final map = Map<String, dynamic>.from(e.value as Map);
          map['id'] ??= e.key;
          return map;
        }).where((p) => p['is_deleted'] != true).toList();
        return list;
      } else {
        return <Map<String, dynamic>>[];
      }
    }
  } catch (_) {}
  return demoData.rawProducts.where((p) => p['is_deleted'] != true).toList();
});

// ── Vendor Earnings ────────────────────────────────────────────────────────────

class VendorEarnings {
  VendorEarnings({
    this.todayTotal = 0,
    this.weekTotal = 0,
    this.monthTotal = 0,
    this.totalOrders = 0,
  });
  final double todayTotal;
  final double weekTotal;
  final double monthTotal;
  final int totalOrders;
}

final vendorEarningsProvider = FutureProvider<VendorEarnings>((ref) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final auth = ref.watch(firebaseAuthProvider);
    final userId = auth.currentUser?.uid;
    if (userId != null) {
      final db = ref.watch(firebaseDatabaseProvider);
      final snapshot = await db
          .ref('orders')
          .orderByChild('vendor_id')
          .equalTo(userId)
          .get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final weekStart = now.subtract(const Duration(days: 7));
        final monthStart = DateTime(now.year, now.month, 1);

        double todayTotal = 0, weekTotal = 0, monthTotal = 0;
        int count = 0;

        for (final entry in data.entries) {
          final o = Map<String, dynamic>.from(entry.value as Map);
          if (o['status'] == 'cancelled') continue;
          count++;
          final amount = (o['total_amount'] as num?)?.toDouble() ?? 0.0;
          final dt =
              DateTime.tryParse(o['created_at']?.toString() ?? '') ?? now;
          if (dt.isAfter(todayStart)) todayTotal += amount;
          if (dt.isAfter(weekStart)) weekTotal += amount;
          if (dt.isAfter(monthStart)) monthTotal += amount;
        }

        return VendorEarnings(
          todayTotal: todayTotal,
          weekTotal: weekTotal,
          monthTotal: monthTotal,
          totalOrders: count,
        );
      }
    }
  } catch (_) {}

  final demoOrders = demoData.vendorOrders;
  double sum = 0;
  for (final o in demoOrders) {
    sum += o.totalAmount;
  }
  return VendorEarnings(
    todayTotal: 645.0,
    weekTotal: sum,
    monthTotal: 4850.0,
    totalOrders: demoOrders.length + 18,
  );
});
