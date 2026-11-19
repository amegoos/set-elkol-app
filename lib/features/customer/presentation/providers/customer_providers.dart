import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/demo_data_service.dart';
import '../../../../core/domain/entities/category.dart';
import '../../../../core/domain/entities/order_model.dart';
import '../../../../core/domain/entities/product.dart';
import '../../../../core/domain/entities/promo_code.dart';
import '../../../../core/domain/entities/vendor.dart';
import '../../../../core/network/firebase_providers.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/vendor_model.dart';

export '../../../../core/domain/entities/order_model.dart';

// ── Cart State ────────────────────────────────────────────────────────────────

class CartItem {
  CartItem({required this.product, required this.quantity});
  final Product product;
  int quantity;
}

class CartState {
  CartState({
    this.items = const {},
    this.appliedPromo,
    this.promoDiscount = 0.0,
    this.isFreeDelivery = false,
  });

  final Map<String, CartItem> items; // productId -> CartItem
  final PromoCode? appliedPromo;
  final double promoDiscount;
  final bool isFreeDelivery;

  double get subtotal => items.values
      .fold(0, (sum, item) => sum + item.product.price * item.quantity);

  double get totalAfterDiscount =>
      (subtotal - promoDiscount).clamp(0, double.infinity);

  int get totalItems =>
      items.values.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  /// Returns the set of distinct vendor IDs in the cart.
  Set<String> get vendorIds => items.values
      .map((i) => i.product.vendorId)
      .where((id) => id.isNotEmpty)
      .toSet();

  /// Primary vendor ID or first vendor ID in cart
  String? get vendorId => items.values.firstOrNull?.product.vendorId;

  /// Primary vendor or first vendor entity in cart
  Vendor? get vendor => items.values.firstOrNull?.product.vendor;

  /// Group items by vendorId: Map<vendorId, List<CartItem>>
  Map<String, List<CartItem>> get itemsByVendor {
    final map = <String, List<CartItem>>{};
    for (final item in items.values) {
      final vId = item.product.vendorId;
      map.putIfAbsent(vId, () => []).add(item);
    }
    return map;
  }

  /// Whether the cart contains items from multiple vendors.
  bool get isMultiVendor => vendorIds.length > 1;

  /// Combined delivery fee calculation:
  /// Standard delivery base 20 EGP + 10 EGP for each additional kitchen if multi-vendor.
  double get estimatedDeliveryFee {
    if (isFreeDelivery) return 0.0;
    if (isEmpty) return 0.0;
    if (isMultiVendor) {
      return 20.0 + (vendorIds.length - 1) * 10.0;
    }
    return vendor?.deliveryFee ?? 20.0;
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  /// Multi-vendor cart supported! Any product from any vendor can be added.
  /// Always returns false (no conflict).
  bool addItem(Product product) {
    final newItems = Map<String, CartItem>.from(state.items);
    if (newItems.containsKey(product.id)) {
      newItems[product.id]!.quantity++;
    } else {
      newItems[product.id] = CartItem(product: product, quantity: 1);
    }
    state = CartState(
      items: newItems,
      appliedPromo: state.appliedPromo,
      promoDiscount: state.promoDiscount,
      isFreeDelivery: state.isFreeDelivery,
    );
    return false;
  }

  void removeItem(String productId) {
    final newItems = Map<String, CartItem>.from(state.items);
    newItems.remove(productId);
    state = CartState(
      items: newItems,
      appliedPromo: state.appliedPromo,
      promoDiscount: state.promoDiscount,
      isFreeDelivery: state.isFreeDelivery,
    );
  }

  void updateQuantity(String productId, int qty) {
    if (qty <= 0) {
      removeItem(productId);
      return;
    }
    final newItems = Map<String, CartItem>.from(state.items);
    if (newItems.containsKey(productId)) {
      newItems[productId]!.quantity = qty;
      state = CartState(
        items: newItems,
        appliedPromo: state.appliedPromo,
        promoDiscount: state.promoDiscount,
        isFreeDelivery: state.isFreeDelivery,
      );
    }
  }

  void clear() {
    state = CartState();
  }

  void applyPromo({
    required PromoCode promo,
    required double discount,
    bool isFreeDelivery = false,
  }) {
    state = CartState(
      items: state.items,
      appliedPromo: promo,
      promoDiscount: discount,
      isFreeDelivery: isFreeDelivery,
    );
  }

  void removePromo() {
    state = CartState(
      items: state.items,
      appliedPromo: null,
      promoDiscount: 0.0,
      isFreeDelivery: false,
    );
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

// ── Categories ─────────────────────────────────────────────────────────────────

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final db = ref.watch(firebaseDatabaseProvider);
    final snapshot = await db.ref('categories').get();
    if (snapshot.exists && snapshot.value != null) {
      final data = snapshot.value;
      if (data is Map) {
        final list = data.entries.map((e) {
          final map = Map<String, dynamic>.from(e.value as Map);
          map['id'] ??= e.key;
          return CategoryModel.fromJson(map);
        }).toList();
        if (list.isNotEmpty) return list;
      }
    }
  } catch (e) {
    debugPrint('[CategoriesProvider] Firebase fetch error: $e');
  }
  return demoData.categories;
});

// ── Selected Category ──────────────────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// ── Shared Root Products Provider (Single Network Call + Instant Cache) ───────

final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  final demoData = ref.watch(demoDataServiceProvider);
  final db = ref.watch(firebaseDatabaseProvider);

  // Single subscription for live updates across the whole app
  final sub = db.ref('products').onValue.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => sub.cancel());

  final Map<String, Product> productMap = {};

  // 1. Authentic Egyptian dishes from presets
  for (final p in demoData.products) {
    productMap[p.id] = p;
  }

  // 2. Realtime Database products added by vendors
  try {
    final snapshot = await db.ref('products').get();
    if (snapshot.exists && snapshot.value != null && snapshot.value is Map) {
      final data = snapshot.value as Map;
      for (final e in data.entries) {
        final map = Map<String, dynamic>.from(e.value as Map);
        map['id'] ??= e.key;
        final prod = ProductModel.fromJson(map);
        productMap[prod.id] = prod;
      }
    }
  } catch (e) {
    debugPrint('[AllProductsProvider] Firebase fetch note: $e');
  }

  return productMap.values.toList();
});

// ── Featured Products (Instant derived filter, zero redundant network calls) ─

final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final all = await ref.watch(allProductsProvider.future);
  return all.where((p) => p.isFeatured && p.isAvailable).toList();
});

// ── Popular Products (Instant derived filter) ────────────────────────────────

final popularProductsProvider = FutureProvider<List<Product>>((ref) async {
  final all = await ref.watch(allProductsProvider.future);
  return all.where((p) => p.isAvailable).toList();
});

// ── Products by Category (Instant derived filter) ────────────────────────────

final productsByCategoryProvider =
    FutureProvider.family<List<Product>, String?>((ref, categoryId) async {
  final all = await ref.watch(allProductsProvider.future);
  if (categoryId == null) return all.where((p) => p.isAvailable).toList();
  return all.where((p) => p.isAvailable && p.categoryId == categoryId).toList();
});

// ── All Active Vendors ─────────────────────────────────────────────────────────

final vendorsProvider = FutureProvider<List<Vendor>>((ref) async {
  final demoData = ref.watch(demoDataServiceProvider);
  final Map<String, Vendor> vendorMap = {};

  // 1. Seed with authentic Egyptian kitchen presets
  for (final v in demoData.vendors) {
    vendorMap[v.id] = v;
  }

  // 2. Merge with vendors registered in Firebase RTDB
  try {
    final db = ref.watch(firebaseDatabaseProvider);
    final snapshot = await db.ref('vendors').get();
    if (snapshot.exists && snapshot.value != null && snapshot.value is Map) {
      final data = snapshot.value as Map;
      for (final e in data.entries) {
        final map = Map<String, dynamic>.from(e.value as Map);
        map['id'] ??= e.key;
        final vendor = VendorModel.fromJson(map);
        if (vendor.isActive) {
          vendorMap[vendor.id] = vendor;
        }
      }
    }
  } catch (e) {
    debugPrint('[VendorsProvider] Firebase fetch note: $e');
  }

  return vendorMap.values.toList();
});

// ── Vendor Detail ──────────────────────────────────────────────────────────────

final vendorDetailProvider =
    FutureProvider.family<Vendor?, String>((ref, vendorId) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final db = ref.watch(firebaseDatabaseProvider);
    final snapshot = await db.ref('vendors/$vendorId').get();
    if (snapshot.exists && snapshot.value != null) {
      final map = Map<String, dynamic>.from(snapshot.value as Map);
      map['id'] ??= vendorId;
      return VendorModel.fromJson(map);
    }
  } catch (e) {
    debugPrint('[VendorDetailProvider] Firebase fetch error: $e');
  }

  return demoData.vendors.firstWhere(
    (v) => v.id == vendorId,
    orElse: () => demoData.vendors.first,
  );
});

// ── Vendor Products ────────────────────────────────────────────────────────────

final vendorProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, vendorId) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final db = ref.watch(firebaseDatabaseProvider);
    final snapshot = await db.ref('products').get();
    if (snapshot.exists && snapshot.value != null) {
      final data = snapshot.value;
      if (data is Map) {
        final list = data.entries
            .map((e) {
              final map = Map<String, dynamic>.from(e.value as Map);
              map['id'] ??= e.key;
              return ProductModel.fromJson(map);
            })
            .where((p) =>
                p.isAvailable && (vendorId.isEmpty || p.vendorId == vendorId))
            .toList();
        if (list.isNotEmpty) return list;
      }
    }
  } catch (e) {
    debugPrint('[VendorProductsProvider] Firebase fetch error: $e');
  }

  return demoData.products
      .where((p) => p.vendorId == vendorId || vendorId.isEmpty)
      .toList();
});

// ── Search ────────────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Product>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final demoData = ref.watch(demoDataServiceProvider);
  if (query.isEmpty) return [];

  try {
    final db = ref.watch(firebaseDatabaseProvider);
    final snapshot = await db.ref('products').get();
    if (snapshot.exists && snapshot.value != null) {
      final data = snapshot.value;
      if (data is Map) {
        final list = data.entries
            .map((e) {
              final map = Map<String, dynamic>.from(e.value as Map);
              map['id'] ??= e.key;
              return ProductModel.fromJson(map);
            })
            .where((p) =>
                p.isAvailable &&
                (p.name.toLowerCase().contains(query) ||
                    (p.description?.toLowerCase().contains(query) ?? false) ||
                    (p.category?.name.toLowerCase().contains(query) ?? false)))
            .toList();
        if (list.isNotEmpty) return list;
      }
    }
  } catch (e) {
    debugPrint('[SearchResultsProvider] Firebase fetch error: $e');
  }

  return demoData.products.where((p) {
    return p.name.toLowerCase().contains(query) ||
        (p.description?.toLowerCase().contains(query) ?? false) ||
        (p.category?.name.toLowerCase().contains(query) ?? false);
  }).toList();
});

// ── Favorites ─────────────────────────────────────────────────────────────────

final favoritesProvider = FutureProvider<List<Product>>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  final userId = auth.currentUser?.uid;
  if (userId == null) return [];

  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final db = ref.watch(firebaseDatabaseProvider);
    final snapshot = await db.ref('favorites/$userId').get();
    if (snapshot.exists && snapshot.value is Map) {
      final favMap = snapshot.value as Map;
      final productIds = favMap.keys.map((k) => k.toString()).toSet();
      return demoData.products.where((p) => productIds.contains(p.id)).toList();
    }
  } catch (e) {
    debugPrint('[FavoritesProvider] Firebase fetch error: $e');
  }
  return [];
});

// ── Toggle Favorite ────────────────────────────────────────────────────────────

final isFavoriteProvider =
    FutureProvider.family<bool, String>((ref, productId) async {
  final auth = ref.watch(firebaseAuthProvider);
  final userId = auth.currentUser?.uid;
  if (userId == null) return false;

  try {
    final db = ref.watch(firebaseDatabaseProvider);
    final snapshot = await db.ref('favorites/$userId/$productId').get();
    return snapshot.exists && snapshot.value == true;
  } catch (_) {
    return false;
  }
});

// ── Customer Orders ────────────────────────────────────────────────────────────

final customerOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final auth = ref.watch(firebaseAuthProvider);
    final userId = auth.currentUser?.uid;
    if (userId != null) {
      final db = ref.watch(firebaseDatabaseProvider);
      final snapshot = await db
          .ref('orders')
          .orderByChild('customer_id')
          .equalTo(userId)
          .get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        final list = data.entries.map((e) {
          final map = Map<String, dynamic>.from(e.value as Map);
          map['id'] ??= e.key;
          return OrderModel.fromJson(map);
        }).toList();
        if (list.isNotEmpty) return list;
      }
    }
  } catch (e) {
    debugPrint('[CustomerOrders] Firebase fetch fallback to demo: $e');
  }

  return demoData.customerOrders;
});

final orderDetailProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final db = ref.watch(firebaseDatabaseProvider);
    final snapshot = await db.ref('orders/$orderId').get();
    if (snapshot.exists && snapshot.value is Map) {
      final map = Map<String, dynamic>.from(snapshot.value as Map);
      map['id'] ??= orderId;
      return OrderModel.fromJson(map);
    }
  } catch (e) {
    debugPrint('[OrderDetail] Firebase fetch fallback to demo: $e');
  }

  return demoData.getCustomerOrderById(orderId);
});
