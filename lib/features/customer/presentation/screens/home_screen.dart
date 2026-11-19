import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/domain/entities/category.dart';
import '../../../../core/domain/entities/product.dart';
import '../../../../core/domain/entities/user_profile.dart';
import '../../../../core/domain/entities/vendor.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_smart_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../presentation/providers/customer_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final categories = ref.watch(categoriesProvider);
    final featuredProducts = ref.watch(featuredProductsProvider);
    final popularProducts = ref.watch(popularProductsProvider);
    final vendors = ref.watch(vendorsProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final cart = ref.watch(cartProvider);
    final allOrders = ref.watch(customerOrdersProvider).asData?.value ?? [];
    final activeOrders = allOrders
        .where((o) => o.status != 'delivered' && o.status != 'cancelled')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // ── Food Delivery Header (Talabat / Food App Style) ────────────────
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 1,
            toolbarHeight: 65,
            title: Row(
              children: [
                // Location Pin & Address (Talabat Style)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'التوصيل إلى',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down,
                              size: 16, color: Colors.grey),
                        ],
                      ),
                      Text(
                        '${profile?.name ?? 'ضيف ست الكل'} — القاهرة',
                        style: const TextStyle(
                          color: Color(0xFF1A1A2E),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (profile?.isAdmin == true)
                IconButton(
                  tooltip: 'لوحة تحكم الإدارة',
                  icon: const Icon(Icons.admin_panel_settings_rounded,
                      color: AppColors.primary),
                  onPressed: () => context.go(RouteNames.adminDashboard),
                ),
              IconButton(
                tooltip: profile?.isVendor == true
                    ? 'لوحة تحكم المطبخ (Vendor)'
                    : 'التبديل إلى حساب طاهية منزلية (Vendor)',
                icon: Icon(
                  Icons.storefront_rounded,
                  color: profile?.isVendor == true
                      ? AppColors.primary
                      : AppColors.accent,
                ),
                onPressed: () async {
                  if (profile?.isVendor == true) {
                    context.go(RouteNames.vendorDashboard);
                  } else {
                    await ref.read(authProvider.notifier).switchRole();
                    if (context.mounted) {
                      context.showSnack('تم التبديل إلى لوحة تحكم المطبخ ✓');
                      context.go(RouteNames.vendorDashboard);
                    }
                  }
                },
              ),
              // Quick Language Switcher Pill
              Consumer(
                builder: (context, ref, _) {
                  final loc = ref.watch(localeProvider);
                  final isAr = loc.languageCode == 'ar';
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    child: InkWell(
                      onTap: () =>
                          ref.read(localeProvider.notifier).toggleLocale(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(isAr ? '🇬🇧' : '🇪🇬',
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              isAr ? 'EN' : 'عربي',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Cart with badge (Amazon / Talabat Style)
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined,
                        color: Color(0xFF1A1A2E)),
                    onPressed: () => context.go(RouteNames.cart),
                  ),
                  if (cart.totalItems > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cart.totalItems}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── Search Bar with Quick Chips ───────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: GestureDetector(
                onTap: () => context.go(RouteNames.search),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'بتدور على إيه؟ (طاجن، محشي، كشري، ملوخية...)',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.tune_rounded,
                          color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Active Order Live Tracking Banner ──────────────────────────────
          if (activeOrders.isNotEmpty)
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () =>
                    context.push('/my-orders/${activeOrders.first.id}'),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.two_wheeler_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'طلبك قيد التوصيل الآن!',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 6),
                                Text('• مباشر',
                                    style: TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Text(
                              'من ${activeOrders.first.vendorName ?? "ست الكل"} — اضغط لتتبع المندوب بالخريطة',
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ),

          // ── Fast Delivery & Deals Banner (Talabat / Amazon Pro Banner) ───
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFBE185D), Color(0xFFD63384)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt, color: Colors.amber, size: 14),
                              SizedBox(width: 3),
                              Text(
                                'توصيل سريع ساخن 🛵',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'طبيخ بيتي أصيل بخصم 25%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'أكل بيتي مضمون من إيد أشهر شيفات وستات مصر',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => context.go(RouteNames.search),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryDark,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'اطلب الآن ❯',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=400&q=80',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Category Pills (Food Style) ───────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'أقسام الأكلات 🍽️',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                categories.when(
                  data: (cats) => SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: cats.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return _CategoryPill(
                            label: 'الكل 🥘',
                            isSelected: selectedCat == null,
                            onTap: () => ref
                                .read(selectedCategoryProvider.notifier)
                                .state = null,
                          );
                        }
                        final cat = cats[i - 1];
                        return _CategoryPill(
                          label: cat.name,
                          isSelected: selectedCat == cat.id,
                          onTap: () => ref
                              .read(selectedCategoryProvider.notifier)
                              .state = cat.id,
                        );
                      },
                    ),
                  ),
                  loading: () => const SizedBox(
                      height: 44, child: Center(child: AppLoadingSpinner())),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // ── Deals of the Day (Amazon / Talabat Flash Deals) ───────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'أكلات مميزة وعروض اليوم ✨',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.timer_outlined,
                                color: Colors.amber, size: 14),
                            SizedBox(width: 3),
                            Text(
                              'عروض طازجة',
                              style: TextStyle(
                                  color: Colors.brown,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                featuredProducts.when(
                  data: (products) => SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: products.length,
                      itemBuilder: (_, i) =>
                          _FoodDealCard(product: products[i]),
                    ),
                  ),
                  loading: () => const SizedBox(
                      height: 250, child: Center(child: AppLoadingSpinner())),
                  error: (e, _) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: AppErrorWidget(message: 'تعذر تحميل المنتجات'),
                  ),
                ),
              ],
            ),
          ),

          // ── Partner Home Kitchens (ستات الكل الموثقين) ────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'أشهر مطابخ ست الكل 👩‍🍳',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                vendors.when(
                  data: (vs) => SizedBox(
                    height: 125,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: vs.length,
                      itemBuilder: (_, i) => _VendorFoodCard(vendor: vs[i]),
                    ),
                  ),
                  loading: () => const SizedBox(
                      height: 125, child: Center(child: AppLoadingSpinner())),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // ── Popular Dishes Grid (Talabat Style Food Cards) ───────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
              child: Row(
                children: [
                  Text(
                    'الأكثر طلباً 🔥',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '(Best Sellers)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          popularProducts.when(
            data: (products) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _FoodProductCard(product: products[i]),
                  childCount: products.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.68,
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: AppLoadingSpinner()),
            error: (_, __) => const SliverToBoxAdapter(
              child: AppErrorWidget(message: 'تعذر تحميل قائمة الأكلات'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Pill ─────────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Food Deal Card (Amazon Deal Style) ────────────────────────────────────────

class _FoodDealCard extends ConsumerWidget {
  const _FoodDealCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context
          .push('/home/vendor/${product.vendorId}/product/${product.id}'),
      child: Container(
        width: 175,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AppSmartImage(
                    imageUrl: product.imageUrl,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'خصم 20%',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        '${product.vendor?.rating ?? 4.8} (45)',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(0)} ج.م',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(product.price * 1.25).toStringAsFixed(0)} ج.م',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Vendor Food Card ──────────────────────────────────────────────────────────

class _VendorFoodCard extends StatelessWidget {
  const _VendorFoodCard({required this.vendor});
  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/home/vendor/${vendor.id}'),
      child: Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryLight.withOpacity(0.2),
              backgroundImage: AppSmartImage.getProvider(vendor.logoUrl),
              child: vendor.logoUrl == null
                  ? Text(
                      vendor.name.characters.first,
                      style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              vendor.name,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 12),
                const SizedBox(width: 2),
                Text(
                  (vendor.rating ?? 4.9).toStringAsFixed(1),
                  style:
                      const TextStyle(fontSize: 10, color: Color(0xFF1A1A2E)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Food Product Card (Talabat + Amazon Add-to-Cart) ──────────────────────────

class _FoodProductCard extends ConsumerWidget {
  const _FoodProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context
          .push('/home/vendor/${product.vendorId}/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: AppSmartImage(
                      imageUrl: product.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (product.isFeatured)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'الأكثر طلباً',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product Details
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 13),
                            const SizedBox(width: 2),
                            Text(
                              '${product.vendor?.rating ?? 4.8}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${product.price.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    // Quick Add to Cart Button (Amazon style)
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(cartProvider.notifier).addItem(product);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'تمت إضافة ${product.name} إلى السلة 🛒'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_shopping_cart, size: 14),
                        label: const Text(
                          'أضف للسلة',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
