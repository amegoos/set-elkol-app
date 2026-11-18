import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_loading.dart';
import '../providers/customer_providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(customerOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('طلباتي')),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const AppEmptyWidget(
              message: 'لا توجد طلبات حتى الآن\nابدأ باستكشاف البائعين',
              icon: Icons.receipt_long_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final order = orders[i];
              return _OrderCard(order: order);
            },
          );
        },
        loading: () => const AppLoadingSpinner(),
        error: (e, _) => AppErrorWidget(
          message: 'تعذر تحميل الطلبات',
          onRetry: () => ref.invalidate(customerOrdersProvider),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final OrderModel order;

  Color get _statusColor {
    switch (order.status) {
      case 'pending':
        return AppColors.pendingStatus;
      case 'accepted':
        return AppColors.acceptedStatus;
      case 'preparing':
        return AppColors.preparingStatus;
      case 'ready':
        return AppColors.readyStatus;
      case 'delivered':
        return AppColors.completedStatus;
      case 'cancelled':
        return AppColors.cancelledStatus;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _statusLabel {
    switch (order.status) {
      case 'pending':
        return 'في الانتظار';
      case 'accepted':
        return 'مقبول';
      case 'preparing':
        return 'قيد التحضير';
      case 'ready':
        return 'جاهز';
      case 'out_for_delivery':
        return 'في الطريق';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغي';
      default:
        return order.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/my-orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.vendorName ?? 'بائع',
                  style: AppTypography.titleSmall,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel,
                    style:
                        AppTypography.labelSmall.copyWith(color: _statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${order.totalAmount.toStringAsFixed(0)} ج.م',
              style:
                  AppTypography.titleMedium.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(order.createdAt),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.map_outlined, size: 14, color: AppColors.primary),
                SizedBox(width: 4),
                Text('تتبع الطلب بالخريطة ❯',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} — ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
