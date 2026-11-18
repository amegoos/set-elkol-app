import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/firebase_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_loading.dart';
import '../providers/vendor_providers.dart';

class VendorOrdersScreen extends ConsumerWidget {
  const VendorOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(vendorOrdersListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الطلبات')),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const AppEmptyWidget(
              message: 'لا توجد طلبات حتى الآن',
              icon: Icons.receipt_long_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (_, i) => _VendorOrderCard(
              order: orders[i],
              onStatusUpdate: (newStatus) async {
                final db = ref.read(firebaseDatabaseProvider);
                await db.ref('orders/${orders[i].id}').update({
                  'status': newStatus,
                  'order_status': newStatus,
                  'updated_at': DateTime.now().toIso8601String(),
                });
                ref.invalidate(vendorOrdersListProvider);
              },
            ),
          );
        },
        loading: () => const AppLoadingSpinner(),
        error: (e, _) => AppErrorWidget(
          message: 'تعذر تحميل الطلبات',
          onRetry: () => ref.invalidate(vendorOrdersListProvider),
        ),
      ),
    );
  }
}

class _VendorOrderCard extends StatelessWidget {
  const _VendorOrderCard({required this.order, required this.onStatusUpdate});
  final VendorOrder order;
  final Function(String) onStatusUpdate;

  static const _statusFlow = [
    'pending',
    'accepted',
    'preparing',
    'ready',
    'out_for_delivery',
    'delivered'
  ];

  static const _statusLabels = {
    'pending': 'في الانتظار',
    'accepted': 'مقبول',
    'preparing': 'قيد التحضير',
    'ready': 'جاهز للاستلام',
    'out_for_delivery': 'في الطريق',
    'delivered': 'تم التسليم',
    'cancelled': 'ملغي',
  };

  static const _statusColors = {
    'pending': AppColors.pendingStatus,
    'accepted': AppColors.acceptedStatus,
    'preparing': AppColors.preparingStatus,
    'ready': AppColors.readyStatus,
    'delivered': AppColors.completedStatus,
    'cancelled': AppColors.cancelledStatus,
  };

  String? get _nextStatus {
    final idx = _statusFlow.indexOf(order.status);
    if (idx == -1 || idx >= _statusFlow.length - 1) return null;
    return _statusFlow[idx + 1];
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[order.status] ?? AppColors.textSecondary;
    final statusLabel = _statusLabels[order.status] ?? order.status;
    final next = _nextStatus;

    return Container(
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
                'طلب #${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                style: AppTypography.titleSmall,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: AppTypography.labelSmall.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'العميل: ${order.customerName ?? 'مجهول'}',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          if (order.deliveryAddress != null)
            Text(
              'التوصيل: ${order.deliveryAddress}',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 4),
          Text(
            '${order.totalAmount.toStringAsFixed(0)} ج.م',
            style: AppTypography.titleSmall.copyWith(color: AppColors.primary),
          ),
          if (next != null && order.status != 'cancelled') ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => onStatusUpdate(next),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
              child: Text('→ ${_statusLabels[next] ?? next}'),
            ),
          ],
          if (order.status == 'pending') ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => onStatusUpdate('cancelled'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 40),
              ),
              child: const Text('رفض / إلغاء'),
            ),
          ],
        ],
      ),
    );
  }
}
