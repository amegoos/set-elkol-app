import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/domain/entities/vendor.dart';
import '../../../../core/data/demo_data_service.dart';
import '../../data/models/vendor_data_model.dart';

// ── Vendor Profile ─────────────────────────────────────────────────────────────

final myVendorProfileProvider = FutureProvider<Vendor?>((ref) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final client = ref.watch(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId != null) {
      final data =
          await client.from('vendors').select().eq('id', userId).maybeSingle();
      if (data != null) {
        return VendorDataModel.fromJson(data as Map<String, dynamic>);
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
      id: json['id'] as String,
      status: json['status'] as String? ?? 'pending',
      totalAmount: (json['total_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      createdAt: DateTime.parse(json['created_at'] as String),
      customerName:
          (json['profiles'] as Map<String, dynamic>?)?['full_name'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      items: (json['order_items'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}

final vendorOrdersListProvider = FutureProvider<List<VendorOrder>>((ref) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final client = ref.watch(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId != null) {
      final data = await client
          .from('orders')
          .select('*, profiles(full_name), order_items(*, products(name))')
          .eq('vendor_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final list = (data as List)
          .map((e) => VendorOrder.fromJson(e as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) return list;
    }
  } catch (_) {}
  return demoData.vendorOrders;
});

// ── Vendor Products ────────────────────────────────────────────────────────────

final myProductsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final client = ref.watch(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId != null) {
      final data = await client
          .from('products')
          .select()
          .eq('vendor_id', userId)
          .order('created_at', ascending: false);

      final list = (data as List).cast<Map<String, dynamic>>();
      if (list.isNotEmpty) return list;
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
    final client = ref.watch(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId != null) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(const Duration(days: 7));
      final monthStart = DateTime(now.year, now.month, 1);

      final data = await client
          .from('orders')
          .select('total_amount, created_at, status')
          .eq('vendor_id', userId)
          .neq('status', 'cancelled');

      final orders = (data as List).cast<Map<String, dynamic>>();
      if (orders.isNotEmpty) {
        double todayTotal = 0, weekTotal = 0, monthTotal = 0;
        for (final o in orders) {
          final amount = (o['total_amount'] as num).toDouble();
          final dt = DateTime.parse(o['created_at'] as String);
          if (dt.isAfter(todayStart)) todayTotal += amount;
          if (dt.isAfter(weekStart)) weekTotal += amount;
          if (dt.isAfter(monthStart)) monthTotal += amount;
        }

        return VendorEarnings(
          todayTotal: todayTotal,
          weekTotal: weekTotal,
          monthTotal: monthTotal,
          totalOrders: orders.length,
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
