import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/domain/entities/product.dart';
import '../../../../core/domain/entities/vendor.dart';
import '../../../../core/domain/entities/category.dart';
import '../../../../core/domain/entities/order_model.dart';
import '../../../../core/domain/entities/promo_code.dart';
import '../../data/models/product_model.dart';
import '../../data/models/vendor_model.dart';
import '../../data/models/category_model.dart';
import '../../../../core/data/demo_data_service.dart';

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
    this.vendorId,
    this.appliedPromo,
    this.promoDiscount = 0.0,
    this.isFreeDelivery = false,
  });

  final Map<String, CartItem> items; // productId -> CartItem
  final String? vendorId; // only one vendor per cart
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

  Vendor? get vendor => items.values.firstOrNull?.product.vendor;
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  /// Returns true if conflict (different vendor), false if added successfully.
  bool addItem(Product product) {
    if (state.vendorId != null && state.vendorId != product.vendorId) {
      return true; // conflict
    }
    final newItems = Map<String, CartItem>.from(state.items);
    if (newItems.containsKey(product.id)) {
      newItems[product.id]!.quantity++;
    } else {
      newItems[product.id] = CartItem(product: product, quantity: 1);
    }
    state = CartState(items: newItems, vendorId: product.vendorId);
    return false;
  }

  void removeItem(String productId) {
    final newItems = Map<String, CartItem>.from(state.items);
    newItems.remove(productId);
    state = CartState(
      items: newItems,
      vendorId: newItems.isEmpty ? null : state.vendorId,
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
      state = CartState(items: newItems, vendorId: state.vendorId);
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
      vendorId: state.vendorId,
      appliedPromo: promo,
      promoDiscount: discount,
      isFreeDelivery: isFreeDelivery,
    );
  }

  void removePromo() {
    state = CartState(
      items: state.items,
      vendorId: state.vendorId,
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
    final client = ref.watch(supabaseClientProvider);
    final data = await client
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('sort_order');

    final list = (data as List)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
    if (list.isNotEmpty) return list;
  } catch (_) {}
  return demoData.categories;
});

// ── Selected Category ──────────────────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// ── Featured Products ──────────────────────────────────────────────────────────

final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final client = ref.watch(supabaseClientProvider);
    final data = await client
        .from('products')
        .select('*, vendors(*)')
        .eq('is_featured', true)
        .eq('is_available', true)
        .order('created_at', ascending: false)
        .limit(10);

    final list = (data as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
    if (list.isNotEmpty) return list;
  } catch (_) {}
  return demoData.products.where((p) => p.isFeatured && p.isAvailable).toList();
});

// ── Popular Products ───────────────────────────────────────────────────────────

final popularProductsProvider = FutureProvider<List<Product>>((ref) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final client = ref.watch(supabaseClientProvider);
    final data = await client
        .from('products')
        .select('*, vendors(*)')
        .eq('is_available', true)
        .order('created_at', ascending: false)
        .limit(20);

    final list = (data as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
    if (list.isNotEmpty) return list;
  } catch (_) {}
  return demoData.products.where((p) => p.isAvailable).toList();
});

// ── Products by Category ───────────────────────────────────────────────────────

final productsByCategoryProvider =
    FutureProvider.family<List<Product>, String?>((ref, categoryId) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final client = ref.watch(supabaseClientProvider);
    var query = client
        .from('products')
        .select('*, vendors(*)')
        .eq('is_available', true);
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    final data = await query.order('created_at', ascending: false).limit(30);
    final list = (data as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
    if (list.isNotEmpty) return list;
  } catch (_) {}

  if (categoryId == null) return demoData.products;
  return demoData.products.where((p) => p.categoryId == categoryId).toList();
});

// ── All Active Vendors ─────────────────────────────────────────────────────────

final vendorsProvider = FutureProvider<List<Vendor>>((ref) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final client = ref.watch(supabaseClientProvider);
    final data = await client
        .from('vendors')
        .select()
        .eq('is_active', true)
        .order('rating', ascending: false)
        .limit(20);

    final list = (data as List)
        .map((e) => VendorModel.fromJson(e as Map<String, dynamic>))
        .toList();
    if (list.isNotEmpty) return list;
  } catch (_) {}
  return demoData.vendors;
});

// ── Vendor Detail ──────────────────────────────────────────────────────────────

final vendorDetailProvider =
    FutureProvider.family<Vendor?, String>((ref, vendorId) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final client = ref.watch(supabaseClientProvider);
    final data =
        await client.from('vendors').select().eq('id', vendorId).maybeSingle();

    if (data != null) return VendorModel.fromJson(data as Map<String, dynamic>);
  } catch (_) {}

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
    final client = ref.watch(supabaseClientProvider);
    final data = await client
        .from('products')
        .select('*, categories(*)')
        .eq('vendor_id', vendorId)
        .eq('is_available', true)
        .order('created_at', ascending: false);

    final list = (data as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
    if (list.isNotEmpty) return list;
  } catch (_) {}

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
    final client = ref.watch(supabaseClientProvider);
    final data = await client
        .from('products')
        .select('*, vendors(*)')
        .ilike('name', '%$query%')
        .eq('is_available', true)
        .limit(30);

    final list = (data as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
    if (list.isNotEmpty) return list;
  } catch (_) {}

  return demoData.products.where((p) {
    return p.name.toLowerCase().contains(query) ||
        (p.description?.toLowerCase().contains(query) ?? false) ||
        (p.category?.name.toLowerCase().contains(query) ?? false);
  }).toList();
});

// ── Favorites ─────────────────────────────────────────────────────────────────

final favoritesProvider = FutureProvider<List<Product>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final data = await client
      .from('favorites')
      .select('products(*, vendors(*))')
      .eq('user_id', userId);

  return (data as List)
      .map((e) => ProductModel.fromJson(e['products'] as Map<String, dynamic>))
      .toList();
});

// ── Toggle Favorite ────────────────────────────────────────────────────────────

final isFavoriteProvider =
    FutureProvider.family<bool, String>((ref, productId) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return false;

  final data = await client
      .from('favorites')
      .select('id')
      .eq('user_id', userId)
      .eq('product_id', productId)
      .maybeSingle();

  return data != null;
});

// ── Customer Orders ────────────────────────────────────────────────────────────

final customerOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final client = ref.watch(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId != null) {
      final data = await client
          .from('orders')
          .select('*, vendors(name), order_items(*, products(name, image_url))')
          .eq('customer_id', userId)
          .order('created_at', ascending: false);

      final list = (data as List)
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) return list;
    }
  } catch (e) {
    debugPrint('[CustomerOrders] Supabase fetch fallback to demo: $e');
  }

  return demoData.customerOrders;
});

final orderDetailProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  final demoData = ref.watch(demoDataServiceProvider);
  try {
    final client = ref.watch(supabaseClientProvider);
    final data = await client
        .from('orders')
        .select(
            '*, vendors(name, logo_url), order_items(*, products(name, image_url))')
        .eq('id', orderId)
        .maybeSingle();

    if (data != null) return OrderModel.fromJson(data as Map<String, dynamic>);
  } catch (e) {
    debugPrint('[OrderDetail] Supabase fetch fallback to demo: $e');
  }

  return demoData.getCustomerOrderById(orderId);
});
