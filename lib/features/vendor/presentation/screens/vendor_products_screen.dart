import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/data/demo_data_service.dart';
import '../../../customer/presentation/providers/customer_providers.dart';
import '../providers/vendor_providers.dart';

class VendorProductsScreen extends ConsumerWidget {
  const VendorProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(myProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('منتجاتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('${RouteNames.vendorProducts}/add'),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return AppEmptyWidget(
              message: 'لا توجد منتجات بعد\nأضف أول منتجاتك الآن',
              icon: Icons.inventory_2_outlined,
              actionLabel: 'إضافة منتج',
              onAction: () => context.push('${RouteNames.vendorProducts}/add'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (_, i) {
              final p = products[i];
              return _ProductTile(
                product: p,
                onEdit: () => context.push('${RouteNames.vendorProducts}/${p['id']}/edit'),
                onToggle: () async {
                  final newAvailable = !(p['is_available'] as bool? ?? true);
                  DemoDataService.instance.toggleProductAvailability(p['id'] as String, newAvailable);
                  try {
                    final client = ref.read(supabaseClientProvider);
                    await client.from('products').update({
                      'is_available': newAvailable,
                      'updated_at': DateTime.now().toIso8601String(),
                    }).eq('id', p['id'] as String);
                  } catch (_) {}
                  ref.invalidate(myProductsProvider);
                  ref.invalidate(featuredProductsProvider);
                  ref.invalidate(popularProductsProvider);
                },
              );
            },
          );
        },
        loading: () => const AppLoadingSpinner(),
        error: (e, _) => AppErrorWidget(
          message: 'تعذر تحميل المنتجات',
          onRetry: () => ref.invalidate(myProductsProvider),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onEdit, required this.onToggle});
  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isAvailable = product['is_available'] as bool? ?? true;
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.6,
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
            borderRadius: BorderRadius.circular(8),
            child: product['image_url'] != null
                ? CachedNetworkImage(
                    imageUrl: product['image_url'] as String,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: AppColors.secondary,
                    child: const Icon(Icons.restaurant, color: AppColors.primary),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'] as String, style: AppTypography.titleSmall),
                Text(
                  '${(product['price'] as num).toStringAsFixed(0)} ج.م',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isAvailable ? 'متاح' : 'غير متاح',
                    style: AppTypography.labelSmall.copyWith(
                      color: isAvailable ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
                color: AppColors.primary,
              ),
              Switch(
                value: isAvailable,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
