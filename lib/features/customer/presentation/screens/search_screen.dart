import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../providers/customer_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(searchQueryProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSelectSuggestion(String suggestion) {
    _controller.text = suggestion;
    ref.read(searchQueryProvider.notifier).state = suggestion;
  }

  Widget _buildProductThumbnail(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        color: AppColors.secondary,
        child: const Icon(Icons.restaurant, color: AppColors.primary),
      );
    }
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 60,
          height: 60,
          color: AppColors.secondary,
          child: const Icon(Icons.restaurant, color: AppColors.primary),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Container(
        width: 60,
        height: 60,
        color: AppColors.secondary,
        child: const Icon(Icons.restaurant, color: AppColors.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final currentQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'ابحث عن أكل أو بائع...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onChanged: (v) {
            ref.read(searchQueryProvider.notifier).state = v;
          },
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: currentQuery.trim().isEmpty
          ? _SearchSuggestions(onSelect: _onSelectSuggestion)
          : results.when(
              data: (products) {
                if (products.isEmpty) {
                  return const AppEmptyWidget(
                    message: 'لا توجد نتائج. جرب كلمة بحث مختلفة',
                    icon: Icons.search_off,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final product = products[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildProductThumbnail(product.imageUrl),
                      ),
                      title:
                          Text(product.name, style: AppTypography.titleSmall),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.category?.name != null)
                            Text(
                              product.category!.name,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            '${product.price.toStringAsFixed(0)} ج.م',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_shopping_cart,
                            color: AppColors.primary),
                        tooltip: 'إضافة للسلة',
                        onPressed: () {
                          ref.read(cartProvider.notifier).addItem(product);
                          context
                              .showSnack('تمت إضافة ${product.name} للسلة ✓');
                        },
                      ),
                      onTap: () => context.push(
                          '/home/vendor/${product.vendorId}/product/${product.id}'),
                    );
                  },
                );
              },
              loading: () => const AppLoadingSpinner(),
              error: (e, _) => AppErrorWidget(message: e.toString()),
            ),
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  const _SearchSuggestions({required this.onSelect});
  final ValueChanged<String> onSelect;

  static const suggestions = [
    'ملوخية',
    'فراخ مشوية',
    'كشري',
    'مسقعة',
    'محشي',
    'ورق عنب',
    'فتة',
    'بسبوسة',
    'حواوشي',
    'ممبار',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('اقتراحات البحث الرائجة', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map((s) => ActionChip(
                      avatar: const Icon(Icons.search,
                          size: 16, color: AppColors.primary),
                      label: Text(s),
                      backgroundColor: AppColors.primary.withOpacity(0.06),
                      side:
                          BorderSide(color: AppColors.primary.withOpacity(0.2)),
                      onPressed: () => onSelect(s),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
