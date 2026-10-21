import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_loading.dart';
import '../providers/customer_providers.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('تتبع الطلب')),
      body: orderAsync.when(
        data: (order) {
          if (order == null) return const Center(child: Text('لم يُوجد الطلب'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Success banner for new orders
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: AppRadius.card,
                    border:
                        Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('تم تأكيد طلبك! 🎉',
                                style: AppTypography.titleMedium),
                            Text(
                              'رقم الطلب: ${widget.orderId.substring(0, 8).toUpperCase()}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Status tracker
                Text('حالة الطلب', style: AppTypography.titleLarge),
                const SizedBox(height: 16),
                _OrderStatusTracker(status: order.status),
                const SizedBox(height: 24),

                // Order details
                Text('تفاصيل الطلب', style: AppTypography.titleMedium),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.card,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                          label: 'البائع', value: order.vendorName ?? '-'),
                      const Divider(height: 16),
                      _DetailRow(
                          label: 'طريقة الدفع',
                          value: _paymentLabel(order.paymentMethod)),
                      const Divider(height: 16),
                      _DetailRow(
                        label: 'الإجمالي',
                        value: '${order.totalAmount.toStringAsFixed(0)} ج.م',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const AppLoadingSpinner(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
      ),
    );
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'cash':
        return 'كاش عند الاستلام';
      case 'instapay':
        return 'InstaPay';
      case 'vodafoneCash':
        return 'فودافون كاش';
      default:
        return method;
    }
  }
}

class _OrderStatusTracker extends StatelessWidget {
  const _OrderStatusTracker({required this.status});
  final String status;

  static const steps = [
    ('pending', 'في الانتظار', Icons.hourglass_empty),
    ('accepted', 'مقبول', Icons.thumb_up_outlined),
    ('preparing', 'قيد التحضير', Icons.restaurant_menu),
    ('ready', 'جاهز', Icons.check_circle_outline),
    ('out_for_delivery', 'في الطريق', Icons.delivery_dining),
    ('delivered', 'تم التسليم', Icons.home_outlined),
  ];

  int get _currentIndex {
    final idx = steps.indexWhere((s) => s.$1 == status);
    return idx == -1 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex;
    return Column(
      children: List.generate(steps.length, (i) {
        final (id, label, icon) = steps[i];
        final isDone = i < current;
        final isCurrent = i == current;
        final color = isCurrent
            ? AppColors.primary
            : isDone
                ? AppColors.success
                : AppColors.textHint;

        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primary.withOpacity(0.1)
                        : isDone
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: isCurrent ? 2 : 1),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (i < steps.length - 1)
                  Container(
                    width: 2,
                    height: 28,
                    color: isDone ? AppColors.success : AppColors.divider,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: color,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.label, required this.value, this.isBold = false});
  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
