import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_loading.dart';
import '../providers/vendor_providers.dart';

class VendorEarningsScreen extends ConsumerWidget {
  const VendorEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(vendorEarningsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الأرباح')),
      body: earningsAsync.when(
        data: (e) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.card,
                ),
                child: Column(
                  children: [
                    Text(
                      'إجمالي هذا الشهر',
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${e.monthTotal.toStringAsFixed(0)} ج.م',
                      style: AppTypography.displayMedium.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _EarningCard(
                      label: 'اليوم',
                      value: '${e.todayTotal.toStringAsFixed(0)} ج.م',
                      icon: Icons.today_outlined,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _EarningCard(
                      label: 'هذا الأسبوع',
                      value: '${e.weekTotal.toStringAsFixed(0)} ج.م',
                      icon: Icons.date_range_outlined,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _EarningCard(
                label: 'إجمالي الطلبات المكتملة',
                value: '${e.totalOrders} طلب',
                icon: Icons.shopping_bag_outlined,
                color: AppColors.acceptedStatus,
              ),
            ],
          ),
        ),
        loading: () => const AppLoadingSpinner(),
        error: (e, _) => AppErrorWidget(
          message: 'تعذر تحميل بيانات الأرباح',
          onRetry: () => ref.invalidate(vendorEarningsProvider),
        ),
      ),
    );
  }
}

class _EarningCard extends StatelessWidget {
  const _EarningCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTypography.titleMedium.copyWith(color: color)),
                Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
