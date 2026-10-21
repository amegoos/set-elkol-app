import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/domain/entities/product.dart';
import '../../../../core/domain/entities/vendor.dart';
import '../../../../core/domain/entities/category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../presentation/providers/customer_providers.dart';
import '../../../../core/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ───────────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            toolbarHeight: 70,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلاً، ${profile?.name.split(' ').first ?? 'ضيف'} 👋',
                  style: AppTypography.titleMedium,
                ),
                Text(
                  'إيه اللي تطلبه النهارده؟',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'لوحة تحكم ست الكل (Vendor)',
                icon: const Icon(Icons.restaurant_menu_rounded,
                    color: AppColors.vendorBadge),
                onPressed: () {
                  ref.read(authProvider.notifier).signInAsDemo(UserRole.vendor);
                  context.go(RouteNames.vendorDashboard);
                },
              ),
              IconButton(
                tooltip: 'لوحة تحكم الإدارة (Admin)',
                icon: const Icon(Icons.admin_panel_settings_outlined,
                    color: Color(0xFF6A1B9A)),
                onPressed: () {
                  ref.read(authProvider.notifier).signInAsDemo(UserRole.admin);
                  context.go(RouteNames.adminDashboard);
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push(RouteNames.notifications),
              ),
            ],
          ),

          // ── Search Bar ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GestureDetector(
                onTap: () => context.go(RouteNames.search),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.search,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'ابحث عن أكل بيتي، طاجن، أو اسم المطبخ...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Hero Banner (Matching Image 2 Dashboard Hero) ────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryContainer,
                    AppColors.accentContainer
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
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
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'طبيخ اليوم 👩‍🍳',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'أكل بيتي طازج بانتظارك',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'خدمة توصيل سريعة لجميع أنحاء القاهرة والجيزة',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => context.go(RouteNames.search),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.textPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward, size: 14),
                          label: const Text('استكشف المنيو',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Hero Dish Circle (Image 2 aesthetic)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
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

          // ── Categories ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Text('الأقسام 🍽️', style: AppTypography.titleLarge),
                ),
                categories.when(
                  data: (cats) => SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: cats.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return _CategoryChip(
                            label: 'الكل 🥘',
                            isSelected: selectedCat == null,
                            onTap: () => ref
                                .read(selectedCategoryProvider.notifier)
                                .state = null,
                          );
                        }
                        final cat = cats[i - 1];
                        return _CategoryChip(
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
                    height: 50,
                    child: Center(child: AppLoadingSpinner()),
                  ),
                  error: (e, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // ── Featured ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Text('المميز ✨', style: AppTypography.titleLarge),
                ),
                featuredProducts.when(
                  data: (products) => SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: products.length,
                      itemBuilder: (_, i) =>
                          _FeaturedCard(product: products[i]),
                    ),
                  ),
                  loading: () => const SizedBox(
                    height: 220,
                    child: Center(child: AppLoadingSpinner()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child:
                        AppErrorWidget(message: 'تعذر تحميل المنتجات المميزة'),
                  ),
                ),
              ],
            ),
          ),

          // ── Popular Vendors ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('بائعين قريبين 🏪', style: AppTypography.titleLarge),
                    ],
                  ),
                ),
                vendors.when(
                  data: (vs) => SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: vs.length,
                      itemBuilder: (_, i) => _VendorChip(vendor: vs[i]),
                    ),
                  ),
                  loading: () => const SizedBox(
                    height: 130,
                    child: Center(child: AppLoadingSpinner()),
                  ),
                  error: (e, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // ── Popular Products ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text('الأكثر طلباً 🔥', style: AppTypography.titleLarge),
            ),
          ),
          popularProducts.when(
            data: (products) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ProductCard(product: products[i]),
                  childCount: products.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: AppLoadingSpinner(),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: AppErrorWidget(message: 'تعذر تحميل المنتجات'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.inputBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Featured Card ─────────────────────────────────────────────────────────────

class _FeaturedCard extends ConsumerWidget {
  const _FeaturedCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context
          .push('/home/vendor/${product.vendorId}/product/${product.id}'),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 130,
                        color: AppColors.shimmer,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 130,
                        color: AppColors.secondary,
                        child: const Icon(Icons.restaurant,
                            color: AppColors.primary, size: 40),
                      ),
                    )
                  : Container(
                      height: 130,
                      color: AppColors.secondary,
                      child: const Icon(Icons.restaurant,
                          color: AppColors.primary, size: 40),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toStringAsFixed(0)} ج.م',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
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

// ── Vendor Chip ───────────────────────────────────────────────────────────────

class _VendorChip extends StatelessWidget {
  const _VendorChip({required this.vendor});
  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/home/vendor/${vendor.id}'),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.secondary,
              backgroundImage: vendor.logoUrl != null
                  ? CachedNetworkImageProvider(vendor.logoUrl!)
                  : null,
              child: vendor.logoUrl == null
                  ? Text(
                      vendor.name.characters.first,
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              vendor.name,
              style: AppTypography.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (vendor.rating != null && vendor.rating! > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: AppColors.starActive, size: 12),
                  Text(
                    vendor.rating!.toStringAsFixed(1),
                    style: AppTypography.labelSmall.copyWith(fontSize: 10),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── Product Card ──────────────────────────────────────────────────────────────

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context
          .push('/home/vendor/${product.vendorId}/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.shimmer),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.secondary,
                          child: const Icon(Icons.restaurant,
                              color: AppColors.primary),
                        ),
                      )
                    : Container(
                        color: AppColors.secondary,
                        child: const Center(
                          child: Icon(Icons.restaurant,
                              color: AppColors.primary, size: 36),
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: AppTypography.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(0)} ج.م',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final conflict = ref
                                .read(cartProvider.notifier)
                                .addItem(product);
                            if (conflict) {
                              _showConflictDialog(context, ref);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('تم الإضافة للسلة ✓')),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ],
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

  void _showConflictDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('السلة من بائع آخر'),
        content: const Text(
            'سلتك تحتوي على منتجات من بائع مختلف. هل تريد إفراغ السلة والبدء من جديد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              ref.read(cartProvider.notifier).addItem(product);
              Navigator.of(context).pop();
            },
            child: const Text('نعم، ابدأ من جديد'),
          ),
        ],
      ),
    );
  }
}
