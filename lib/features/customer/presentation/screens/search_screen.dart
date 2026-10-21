import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_loading.dart';
import '../providers/customer_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);

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
      body: results.when(
        data: (products) {
          if (ref.watch(searchQueryProvider).isEmpty) {
            return const _SearchSuggestions();
          }
          if (products.isEmpty) {
            return const AppEmptyWidget(
              message: 'لا توجد نتائج. جرب كلمة بحث مختلفة',
              icon: Icons.search_off,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (_, i) {
              final product = products[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: AppColors.secondary,
                          child: const Icon(Icons.restaurant,
                              color: AppColors.primary),
                        ),
                ),
                title: Text(product.name, style: AppTypography.titleSmall),
                subtitle: Text(
                  '${product.price.toStringAsFixed(0)} ج.م',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.primary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
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
  const _SearchSuggestions();

  static const suggestions = [
    'ملوخية',
    'فراخ مشوية',
    'كشري',
    'مسقعة',
    'محشي',
    'ورق عنب',
    'فتة',
    'بسبوسة',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('اقتراحات', style: AppTypography.titleMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map((s) => ActionChip(
                      label: Text(s),
                      onPressed: () {},
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
