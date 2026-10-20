import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/domain/entities/product.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../providers/customer_providers.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.vendorId,
  });
  final String productId;
  final String vendorId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(vendorProductsProvider(widget.vendorId));

    return productsAsync.when(
      data: (products) {
        final idx = products.indexWhere((p) => p.id == widget.productId);
        if (idx == -1) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('المنتج غير موجود')));
        }
        return _buildContent(context, products[idx]);
      },
      loading: () => Scaffold(appBar: AppBar(), body: const AppLoadingSpinner()),
      error: (e, _) => Scaffold(appBar: AppBar(), body: AppErrorWidget(message: e.toString())),
    );
  }

  Widget _buildContent(BuildContext context, Product product) {
    final isFavAsync = ref.watch(isFavoriteProvider(product.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            actions: [
              isFavAsync.when(
                data: (fav) => IconButton(
                  icon: Icon(fav ? Icons.favorite : Icons.favorite_border,
                      color: fav ? AppColors.error : null),
                  onPressed: () => _toggleFavorite(product.id, fav),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.secondary,
                        child: const Icon(Icons.restaurant, size: 80, color: AppColors.primary),
                      ),
                    )
                  : Container(
                      color: AppColors.secondary,
                      child: const Icon(Icons.restaurant, size: 80, color: AppColors.primary),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(product.name, style: AppTypography.headlineSmall)),
                      Text(
                        '${product.price.toStringAsFixed(0)} ج.م',
                        style: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (product.isVegetarian) _Tag(label: '🥗 نباتي', color: AppColors.success),
                      if (product.isSpicy) _Tag(label: '🌶 حار', color: AppColors.warning),
                      if (product.preparationTimeMinutes != null)
                        _Tag(label: '⏱ ${product.preparationTimeMinutes} دقيقة', color: AppColors.textSecondary),
                    ],
                  ),
                  if (product.description != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      product.description!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('الكمية', style: AppTypography.titleMedium),
                      const Spacer(),
                      _QuantitySelector(
                        quantity: _quantity,
                        onDecrement: () { if (_quantity > 1) setState(() => _quantity--); },
                        onIncrement: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(
            label: 'أضف للسلة — ${(product.price * _quantity).toStringAsFixed(0)} ج.م',
            onPressed: () {
              for (var i = 0; i < _quantity; i++) {
                ref.read(cartProvider.notifier).addItem(product);
              }
              context.showSnack('تم الإضافة للسلة ✓');
              context.pop();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(String productId, bool isFav) async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    if (isFav) {
      await client.from('favorites').delete()
          .eq('user_id', userId).eq('product_id', productId);
    } else {
      await client.from('favorites').insert({'user_id': userId, 'product_id': productId});
    }
    ref.invalidate(isFavoriteProvider(productId));
    ref.invalidate(favoritesProvider);
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
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
      child: Text(label, style: AppTypography.labelSmall.copyWith(color: color)),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onDecrement,
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.primary,
        ),
        SizedBox(
          width: 36,
          child: Text('$quantity', textAlign: TextAlign.center, style: AppTypography.titleMedium),
        ),
        IconButton(
          onPressed: onIncrement,
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.primary,
        ),
      ],
    );
  }
}
