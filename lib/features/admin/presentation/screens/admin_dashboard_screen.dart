import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/domain/entities/user_profile.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/data/demo_data_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _switchToRole(UserRole targetRole) {
    ref.read(authProvider.notifier).signInAsDemo(targetRole);
    context.showSnack(
      targetRole == UserRole.customer
          ? 'تم التحويل إلى وضع العميل (Sara) 🛒'
          : 'تم التحويل إلى وضع ست الكل / البائعة (Om Ahmed) 👩‍🍳',
    );
    if (targetRole == UserRole.customer) {
      context.go(RouteNames.customerHome);
    } else {
      context.go(RouteNames.vendorDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final demoData = ref.watch(demoDataServiceProvider);
    final rawProducts = demoData.rawProducts;
    final vendors = demoData.vendors;
    final orders = demoData.vendorOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded,
                color: AppColors.primary, size: 26),
            SizedBox(width: 8),
            Text('لوحة تحكم الإدارة — ست الكل',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go(RouteNames.login);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'الإحصائيات العامة 📊'),
            Tab(text: 'المطابخ الشريكة 👩‍🍳'),
            Tab(text: 'الطلبات المباشرة 📦'),
            Tab(text: 'قائمة الأكلات 🍲'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Quick Demo Role Switcher Bar ──────────────────────────────
          _buildRoleSwitcherBanner(),

          // ── Tab Views ──────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(
                    rawProducts.length, vendors.length, orders.length),
                _buildVendorsTab(vendors),
                _buildOrdersTab(orders),
                _buildProductsTab(rawProducts),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSwitcherBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.swap_horiz_rounded,
              color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'تبديل سريع للعرض التجريبي:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _switchToRole(UserRole.customer),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              side: const BorderSide(color: AppColors.primary),
            ),
            icon: const Icon(Icons.person, size: 14, color: AppColors.primary),
            label: const Text('عميل',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _switchToRole(UserRole.vendor),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vendorBadge,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.restaurant_menu, size: 14),
            label: const Text('ست الكل',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── 1. Overview Tab ────────────────────────────────────────────────────────
  Widget _buildOverviewTab(
      int productsCount, int vendorsCount, int ordersCount) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 4 Main KPI Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'إجمالي المبيعات',
                  value: '48,500 ج.م',
                  subtitle: '+18% هذا الأسبوع 📈',
                  icon: Icons.monetization_on_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'طلبات اليوم',
                  value: '24 طلب',
                  subtitle: '8 قيد التجهيز ⏳',
                  icon: Icons.delivery_dining_rounded,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'المطابخ الشريكة',
                  value: '$vendorsCount مطبخ',
                  subtitle: '15 موثق بالعلامة الزرقاء ✓',
                  icon: Icons.storefront_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'الأكلات المتاحة',
                  value: '$productsCount أكلة',
                  subtitle: 'بأصناف وأسعار حقيقية',
                  icon: Icons.ramen_dining_rounded,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Platform Commission Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentDark, AppColors.accent],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: AppRadius.card,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 36),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أرباح عمولة المنصة (10%)',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '4,850.00 ج.م',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Text(
                  'مستحقة الصرف',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Platform Quality & Safety Controls
          Text('إجراءات التحكم والمراقبة',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          Card(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.accentContainer,
                    child: Icon(Icons.verified_user_rounded,
                        color: AppColors.success),
                  ),
                  title: const Text('توثيق المطابخ وشهادات الصحة'),
                  subtitle:
                      const Text('فحص نظافة المطبخ وجودة التغليف قبل التفعيل'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _tabController.animateTo(1),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    child:
                        Icon(Icons.fastfood_rounded, color: AppColors.primary),
                  ),
                  title: const Text('مراجعة أسعار الأكلات والكميات'),
                  subtitle: const Text(
                      'التأكد من التزام المطابخ بالأسعار العادلة ومطابقة الصور'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _tabController.animateTo(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              Text(title,
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.textSecondary)),
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: AppTypography.titleLarge
                  .copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── 2. Vendors Tab ─────────────────────────────────────────────────────────
  Widget _buildVendorsTab(List vendors) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vendors.length,
      itemBuilder: (context, index) {
        final v = vendors[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: v.logoUrl ??
                        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=200&q=80',
                    width: 65,
                    height: 65,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              v.name,
                              style: AppTypography.titleSmall
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified,
                                    color: AppColors.success, size: 13),
                                SizedBox(width: 3),
                                Text('موثق',
                                    style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${v.governorate ?? "القاهرة"} — ${v.area ?? "مدينة نصر"}',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 15),
                          const SizedBox(width: 3),
                          Text(
                              '${v.rating ?? 4.9} (${v.totalReviews ?? 120} تقييم)',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text('حد أدنى: ${v.minOrder ?? 80} ج.م',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 3. Orders Tab ──────────────────────────────────────────────────────────
  Widget _buildOrdersTab(List orders) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final o = orders[index];
        final isCompleted = o.status == 'completed';
        final isPreparing = o.status == 'preparing';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'طلب #${o.id.substring(o.id.length > 6 ? o.id.length - 6 : 0)}',
                        style: AppTypography.titleSmall
                            .copyWith(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.success.withOpacity(0.12)
                            : (isPreparing
                                ? AppColors.accent.withOpacity(0.12)
                                : AppColors.primary.withOpacity(0.12)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isCompleted
                            ? 'تم التسليم ✓'
                            : (isPreparing
                                ? 'جاري التحضير 👩‍🍳'
                                : 'قيد المراجعة ⏳'),
                        style: TextStyle(
                          color: isCompleted
                              ? AppColors.success
                              : (isPreparing
                                  ? AppColors.accent
                                  : AppColors.primary),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('العميل: ${o.customerName ?? "سارة محمود"}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                if (o.deliveryAddress != null)
                  Text('العنوان: ${o.deliveryAddress}',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'طريقة الدفع: ${o.paymentMethod == "instapay" ? "إنستاباي (InstaPay)" : (o.paymentMethod == "vodafone_cash" ? "فودافون كاش" : "كاش عند الاستلام")}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    Text('${o.totalAmount.toStringAsFixed(0)} ج.م',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 4. Products Tab ────────────────────────────────────────────────────────
  Widget _buildProductsTab(List rawProducts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rawProducts.length,
      itemBuilder: (context, index) {
        final p = rawProducts[index];
        final isAvailable = p['is_available'] as bool? ?? true;
        final qty = p['available_quantity'] ?? 10;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: p['image_url'] as String? ??
                        'https://images.unsplash.com/photo-1541518763669-27fef04b14ea?auto=format&fit=crop&w=200&q=80',
                    width: 75,
                    height: 75,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['name'] as String,
                          style: AppTypography.titleSmall
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('${(p['price'] as num).toStringAsFixed(0)} ج.م',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('الكمية: $qty',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAvailable
                            ? 'متاح للطلب الفوري ✓'
                            : 'غير متوفر حالياً ✕',
                        style: TextStyle(
                          color:
                              isAvailable ? AppColors.success : AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
