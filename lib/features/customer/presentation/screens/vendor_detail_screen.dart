import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/domain/entities/product.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_loading.dart';
import '../providers/customer_providers.dart';

class VendorDetailScreen extends ConsumerWidget {
  const VendorDetailScreen({super.key, required this.vendorId});
  final String vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendor = ref.watch(vendorDetailProvider(vendorId));
    final products = ref.watch(vendorProductsProvider(vendorId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: vendor.when(
        data: (v) {
          if (v == null) return const Center(child: Text('لم يُوجد البائع'));
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: v.logoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: v.logoUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.secondary,
                            child: const Icon(Icons.store, size: 60, color: AppColors.primary),
                          ),
                        )
                      : Container(
                          color: AppColors.secondary,
                          child: const Icon(Icons.store, size: 60, color: AppColors.primary),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.name, style: AppTypography.headlineMedium),
                      const SizedBox(height: 8),
                      if (v.description != null)
                        Text(
                          v.description!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (v.rating != null && v.rating! > 0) ...[
                            RatingBarIndicator(
                              rating: v.rating!,
                              itemSize: 16,
                              itemBuilder: (_, __) => const Icon(
                                Icons.star,
                                color: AppColors.starActive,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${v.rating!.toStringAsFixed(1)} (${v.totalReviews ?? 0})',
                              style: AppTypography.labelMedium,
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (v.area != null)
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 14, color: AppColors.textSecondary),
                                Text(
                                  v.area!,
                                  style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (v.offersDelivery && v.deliveryFee != null)
                            _InfoChip(
                              label: 'توصيل ${v.deliveryFee!.toStringAsFixed(0)} ج.م',
                              icon: Icons.delivery_dining,
                              color: AppColors.deliveryBadge,
                            ),
                          const SizedBox(width: 8),
                          if (v.offersPickup)
                            const _InfoChip(
                              label: 'استلام ذاتي',
                              icon: Icons.store_mall_directory_outlined,
                              color: AppColors.pickupBadge,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                sliver: products.when(
                  data: (ps) => SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _ProductListItem(product: ps[i]),
                      childCount: ps.length,
                    ),
                  ),
                  loading: () => const SliverToBoxAdapter(child: AppLoadingSpinner()),
                  error: (e, _) => SliverToBoxAdapter(
                    child: AppErrorWidget(message: 'تعذر تحميل المنتجات'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const AppLoadingSpinner(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _ProductListItem extends ConsumerWidget {
  const _ProductListItem({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/home/vendor/${product.vendorId}/product/${product.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: AppColors.secondary,
                      child: const Icon(Icons.restaurant, color: AppColors.primary),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: AppTypography.titleSmall),
                  if (product.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(0)} ج.م',
                        style: AppTypography.titleSmall.copyWith(color: AppColors.primary),
                      ),
                      GestureDetector(
                        onTap: () {
                          final conflict = ref.read(cartProvider.notifier).addItem(product);
                          if (!conflict) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم الإضافة للسلة ✓')),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
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
