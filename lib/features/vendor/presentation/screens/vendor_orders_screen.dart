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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('طلبات المطبخ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(vendorOrdersListProvider),
            tooltip: 'تحديث الطلبات',
          ),
        ],
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColors[order.status] ?? AppColors.textSecondary;
    final statusLabel = _statusLabels[order.status] ?? order.status;
    final next = _nextStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'طلب #${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: isDark ? Colors.white70 : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'العميل: ${order.customerName ?? 'مجهول'}',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (order.deliveryAddress != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: isDark ? Colors.white70 : AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'التوصيل: ${order.deliveryAddress}',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Order Items breakdown
          if (order.items.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262638) : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'محتويات الوجبات المطلوبة (${order.items.length}):',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...order.items.map((item) {
                    final itemName = item['product_name_snapshot'] ?? item['product_name'] ?? 'وجبة بيتي';
                    final qty = item['quantity'] ?? 1;
                    final price = item['subtotal'] ?? item['unit_price'] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '🍽️ $itemName × $qty',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '$price ج.م',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.primaryLight : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'طريقة الدفع: ${order.paymentMethod == "cash" ? "كاش عند الاستلام" : order.paymentMethod}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
              Text(
                'الإجمالي: ${order.totalAmount.toStringAsFixed(0)} ج.م',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
            ],
          ),

          if (next != null && order.status != 'cancelled') ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => onStatusUpdate(next),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                '→ ${_statusLabels[next] ?? next}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          if (order.status == 'pending') ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => onStatusUpdate('cancelled'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('رفض / إلغاء الطلب'),
            ),
          ],
        ],
      ),
    );
  }
}
