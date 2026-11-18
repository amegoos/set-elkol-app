import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/data/demo_data_service.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/network/firebase_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading.dart';
import '../providers/customer_providers.dart';
import '../../../vendor/presentation/providers/vendor_providers.dart';
import '../widgets/live_tracking_map_widget.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  bool _isMarkingDelivered = false;

  Future<void> _callDriver(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) context.showSnack('رقم هاتف المندوب: $phoneNumber');
      }
    } catch (_) {
      if (mounted) context.showSnack('رقم هاتف المندوب: $phoneNumber');
    }
  }

  Future<void> _markOrderReceived(String orderId) async {
    setState(() => _isMarkingDelivered = true);
    try {
      final db = ref.read(firebaseDatabaseProvider);
      final nowIso = DateTime.now().toIso8601String();

      // Update in Firebase Realtime Database
      await db.ref('orders/$orderId').update({
        'status': 'delivered',
        'order_status': 'delivered',
        'updated_at': nowIso,
      });

      // Update local demo data
      DemoDataService.instance.updateOrderStatus(orderId, 'delivered');

      ref.invalidate(orderDetailProvider(orderId));
      ref.invalidate(customerOrdersProvider);
      ref.invalidate(vendorOrdersListProvider);

      if (!mounted) return;
      context.showSnack('ألف هنا وشفا! تم استلام الطلب بنجاح 🎉');
    } catch (e) {
      if (mounted) context.showSnack('حدث خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isMarkingDelivered = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('تتبع الطلب (Live Tracking)'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.customerHome);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'الرئيسية',
            onPressed: () => context.go(RouteNames.customerHome),
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('لم يتم العثور على الطلب'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go(RouteNames.customerHome),
                    child: const Text('العودة للرئيسية'),
                  ),
                ],
              ),
            );
          }

          final shortId = widget.orderId.length > 8
              ? widget.orderId.substring(0, 8).toUpperCase()
              : widget.orderId.toUpperCase();

          return Stack(
            children: [
              // ── Main Scroll View ──────────────────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Interactive Live GPS Delivery Map
                    LiveTrackingMapWidget(
                      vendorName: order.vendorName ?? 'مطبخ ست الكل',
                      deliveryAddress: order.deliveryAddress ?? 'عنوان التوصيل',
                      orderStatus: order.status,
                      height: 320,
                    ),

                    // 2. Bottom Sheet Floating Card (Matching the Reference UI Kit)
                    Container(
                      transform: Matrix4.translationValues(0.0, -18.0, 0.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Heading & Order Tag
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.status == 'delivered'
                                        ? 'تم تسليم الطلب بنجاح'
                                        : 'في الطريق إليك 🛵',
                                    style: AppTypography.headlineSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.status == 'delivered'
                                        ? 'بالهناء والشفاء ❤️'
                                        : 'الوصول المتوقع: خلال 20 دقيقة',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color:
                                          AppColors.primary.withOpacity(0.2)),
                                ),
                                child: Text(
                                  '#$shortId',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // 3. Horizontal 4-Stage Stepper Tracker (Like the exact image)
                          _HorizontalOrderStepper(status: order.status),

                          const SizedBox(height: 24),

                          // 4. Delivery Captain Profile Box (Like the exact image)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                // Driver Avatar
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor:
                                          AppColors.primary.withOpacity(0.1),
                                      backgroundImage: const NetworkImage(
                                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check,
                                            size: 10, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),

                                // Driver Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'كابتن أحمد سعيد',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'مندوب توصيل ست الكل (4.9 ⭐)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Call Button
                                Material(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => _callDriver('01067322605'),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.phone_in_talk_rounded,
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 5. Order Summary Snapshot
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                _SummaryRow(
                                  icon: Icons.storefront_outlined,
                                  label: 'المطبخ',
                                  value: order.vendorName ?? 'مطبخ ست الكل',
                                ),
                                const Divider(height: 18),
                                _SummaryRow(
                                  icon: Icons.location_on_outlined,
                                  label: 'التوصيل إلى',
                                  value: order.deliveryAddress ?? 'القاهرة',
                                ),
                                const Divider(height: 18),
                                _SummaryRow(
                                  icon: Icons.payments_outlined,
                                  label: 'الإجمالي المطلوب',
                                  value:
                                      '${order.totalAmount.toStringAsFixed(0)} ج.م (${_paymentLabel(order.paymentMethod)})',
                                  isBold: true,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 6. Primary Action Buttons
                          if (order.status != 'delivered') ...[
                            AppButton(
                              label: 'تأكيد استلام الطلب ✓',
                              isLoading: _isMarkingDelivered,
                              onPressed: () => _markOrderReceived(order.id),
                            ),
                            const SizedBox(height: 10),
                          ],

                          OutlinedButton(
                            onPressed: () =>
                                context.go(RouteNames.customerHome),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: const Text(
                              'العودة للصفحة الرئيسية',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Scaffold(body: AppLoadingSpinner()),
        error: (e, _) => Scaffold(body: AppErrorWidget(message: e.toString())),
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
      case 'vodafone_cash':
        return 'فودافون كاش';
      case 'card':
        return 'بطاقة بنكية';
      default:
        return 'كاش عند الاستلام';
    }
  }
}

class _HorizontalOrderStepper extends StatelessWidget {
  const _HorizontalOrderStepper({required this.status});
  final String status;

  static const stages = [
    ('pending', 'مقبول', Icons.check_circle_outline),
    ('preparing', 'قيد الطبخ', Icons.restaurant_menu_rounded),
    ('out_for_delivery', 'استلام المندوب', Icons.two_wheeler_rounded),
    ('delivered', 'تم التوصيل', Icons.home_rounded),
  ];

  int get _stageIndex {
    switch (status) {
      case 'delivered':
        return 3;
      case 'out_for_delivery':
      case 'ready':
        return 2;
      case 'preparing':
        return 1;
      case 'accepted':
      case 'pending':
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _stageIndex;

    return Column(
      children: [
        // Stepper Icons and connecting lines
        Row(
          children: List.generate(stages.length * 2 - 1, (index) {
            if (index.isOdd) {
              final stepBefore = index ~/ 2;
              final isPassed = stepBefore < activeIndex;
              return Expanded(
                child: Container(
                  height: 3,
                  color: isPassed ? AppColors.primary : Colors.grey.shade300,
                ),
              );
            }

            final stepIdx = index ~/ 2;
            final isCompleted = stepIdx <= activeIndex;
            final isCurrent = stepIdx == activeIndex;

            return Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppColors.primary : Colors.grey.shade300,
                  width: 2,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                stages[stepIdx].$3,
                size: 18,
                color: isCompleted ? Colors.white : Colors.grey.shade400,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),

        // Stage Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: stages.map((s) {
            final idx = stages.indexOf(s);
            final isCurrent = idx == activeIndex;
            return SizedBox(
              width: 70,
              child: Text(
                s.$2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent ? AppColors.primary : Colors.grey.shade600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 18, color: isBold ? AppColors.primary : Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? AppColors.primary : const Color(0xFF1E293B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
