import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/demo_data_service.dart';
import '../../../../core/domain/entities/vendor.dart';
import '../../../../core/network/firebase_providers.dart';
import '../../data/models/vendor_data_model.dart';

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
        }).toList();
        if (list.isNotEmpty) return list;
      }
    }
  } catch (_) {}
  return demoData.rawProducts;
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
