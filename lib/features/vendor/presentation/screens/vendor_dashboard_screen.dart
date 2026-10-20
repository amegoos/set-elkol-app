import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/vendor_providers.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final earnings = ref.watch(vendorEarningsProvider);
    final orders = ref.watch(vendorOrdersListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('لوحة التحكم — ست الكل'),
        actions: [
          IconButton(
            tooltip: 'معاينة كـ عميل',
            icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
            onPressed: () {
              ref.read(authProvider.notifier).signInAsDemo(UserRole.customer);
              context.go(RouteNames.customerHome);
            },
          ),
          IconButton(
            tooltip: 'لوحة تحكم الإدارة (Admin)',
            icon: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF6A1B9A)),
            onPressed: () {
              ref.read(authProvider.notifier).signInAsDemo(UserRole.admin);
              context.go(RouteNames.adminDashboard);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(RouteNames.notifications),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, Color(0xFF2D5021)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.card,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      profile?.name.isNotEmpty == true ? profile!.name[0] : 'V',
                      style: AppTypography.titleLarge.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أهلاً، ${profile?.name.split(' ').first ?? 'بائع'}',
                        style: AppTypography.titleMedium.copyWith(color: Colors.white),
                      ),
                      Text(
                        'متجرك شغال! 🌟',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Earnings cards
            Text('الأرباح', style: AppTypography.titleLarge),
            const SizedBox(height: 12),
            earnings.when(
              data: (e) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _StatCard(label: 'اليوم', value: '${e.todayTotal.toStringAsFixed(0)} ج.م', icon: Icons.today, color: AppColors.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(label: 'الأسبوع', value: '${e.weekTotal.toStringAsFixed(0)} ج.م', icon: Icons.date_range, color: AppColors.accent)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _StatCard(label: 'الشهر', value: '${e.monthTotal.toStringAsFixed(0)} ج.م', icon: Icons.calendar_month, color: AppColors.warning)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(label: 'إجمالي الطلبات', value: '${e.totalOrders}', icon: Icons.shopping_bag_outlined, color: AppColors.acceptedStatus)),
                    ],
                  ),
                ],
              ),
              loading: () => const AppLoadingSpinner(),
              error: (e, _) => const AppErrorWidget(message: 'تعذر تحميل الأرباح'),
            ),

            const SizedBox(height: 24),
            Text('آخر الطلبات', style: AppTypography.titleLarge),
            const SizedBox(height: 12),

            orders.when(
              data: (os) {
                final recent = os.take(5).toList();
                if (recent.isEmpty) {
                  return const AppEmptyWidget(
                    message: 'لا توجد طلبات بعد',
                    icon: Icons.receipt_long_outlined,
                  );
                }
                return Column(
                  children: recent.map((o) => _OrderSummaryTile(order: o)).toList(),
                );
              },
              loading: () => const AppLoadingSpinner(),
              error: (e, _) => const AppErrorWidget(message: 'تعذر تحميل الطلبات'),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة منتج'),
                    onPressed: () => context.push('${RouteNames.vendorProducts}/add'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('كل الطلبات'),
                    onPressed: () => context.go(RouteNames.vendorOrders),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.titleLarge.copyWith(color: color)),
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _OrderSummaryTile extends StatelessWidget {
  const _OrderSummaryTile({required this.order});
  final VendorOrder order;

  Color get _statusColor {
    switch (order.status) {
      case 'pending': return AppColors.pendingStatus;
      case 'accepted': return AppColors.acceptedStatus;
      case 'preparing': return AppColors.preparingStatus;
      case 'ready': return AppColors.readyStatus;
      case 'delivered': return AppColors.completedStatus;
      case 'cancelled': return AppColors.cancelledStatus;
      default: return AppColors.textSecondary;
    }
  }

  String get _statusLabel {
    switch (order.status) {
      case 'pending': return 'في الانتظار';
      case 'accepted': return 'مقبول';
      case 'preparing': return 'قيد التحضير';
      case 'ready': return 'جاهز';
      case 'delivered': return 'تم التسليم';
      case 'cancelled': return 'ملغي';
      default: return order.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName ?? 'عميل',
                  style: AppTypography.titleSmall,
                ),
                Text(
                  '${order.totalAmount.toStringAsFixed(0)} ج.م',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel,
              style: AppTypography.labelSmall.copyWith(color: _statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
