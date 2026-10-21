import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/domain/entities/user_profile.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;

    if (profile == null) {
      return const Scaffold(body: AppLoadingSpinner());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('حسابي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(RouteNames.notifications),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.surface,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.secondary,
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name[0].toUpperCase()
                          : 'U',
                      style: AppTypography.headlineLarge
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(profile.name, style: AppTypography.headlineSmall),
                  if (profile.email != null)
                    Text(
                      profile.email!,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: profile.isVendor
                          ? AppColors.vendorBadge.withOpacity(0.12)
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      profile.isVendor ? 'بائع' : 'عميل',
                      style: AppTypography.labelMedium.copyWith(
                        color: profile.isVendor
                            ? AppColors.vendorBadge
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Menu items
            _MenuSection(
              title: 'حسابي',
              items: [
                _MenuItem(
                  icon: Icons.favorite_border,
                  label: 'المفضلة',
                  onTap: () =>
                      context.push('${RouteNames.customerProfile}/favorites'),
                ),
                _MenuItem(
                  icon: Icons.location_on_outlined,
                  label: 'عناوين التوصيل',
                  onTap: () =>
                      context.push('${RouteNames.customerProfile}/addresses'),
                ),
                _MenuItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'طلباتي',
                  onTap: () => context.go(RouteNames.customerOrders),
                ),
              ],
            ),

            if (!profile.isVendor)
              _MenuSection(
                title: 'البيع',
                items: [
                  _MenuItem(
                    icon: Icons.storefront_outlined,
                    label: 'أصبح بائعاً',
                    onTap: () => _switchRole(context, ref),
                    color: AppColors.accent,
                  ),
                ],
              ),

            if (profile.isVendor)
              _MenuSection(
                title: 'متجري',
                items: [
                  _MenuItem(
                    icon: Icons.dashboard_outlined,
                    label: 'لوحة التحكم',
                    onTap: () => context.go(RouteNames.vendorDashboard),
                    color: AppColors.accent,
                  ),
                  _MenuItem(
                    icon: Icons.person_outline,
                    label: 'العودة لعميل',
                    onTap: () => _switchRole(context, ref),
                    color: AppColors.primary,
                  ),
                ],
              ),

            _MenuSection(
              title: 'الوضع التجريبي والإدارة 🛡️',
              items: [
                _MenuItem(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'لوحة تحكم الإدارة (Admin Dashboard)',
                  color: AppColors.pickupBadge,
                  onTap: () {
                    ref
                        .read(authProvider.notifier)
                        .signInAsDemo(UserRole.admin);
                    context.go(RouteNames.adminDashboard);
                  },
                ),
                _MenuItem(
                  icon: Icons.restaurant_menu_rounded,
                  label: 'التحويل لحساب ست الكل (Vendor)',
                  color: AppColors.vendorBadge,
                  onTap: () {
                    ref
                        .read(authProvider.notifier)
                        .signInAsDemo(UserRole.vendor);
                    context.go(RouteNames.vendorDashboard);
                  },
                ),
              ],
            ),

            _MenuSection(
              title: 'الإعدادات',
              items: [
                _MenuItem(
                  icon: Icons.language_outlined,
                  label: 'اللغة',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.help_outline,
                  label: 'المساعدة والدعم',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.logout,
                  label: 'تسجيل الخروج',
                  color: AppColors.error,
                  onTap: () => _confirmLogout(context, ref),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _switchRole(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(authProvider.notifier);
    final error = await notifier.switchRole();
    if (!context.mounted) return;
    if (error != null) {
      context.showSnack(error, isError: true);
    } else {
      final newProfile = ref.read(authProvider).profile;
      if (newProfile?.isVendor == true) {
        context.showSnack('تم التبديل إلى وضع البائع ✓');
        context.go(RouteNames.vendorSetup);
      } else {
        context.showSnack('تم التبديل إلى وضع العميل ✓');
        context.go(RouteNames.customerHome);
      }
    }
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('لا')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).signOut();
            },
            child: const Text('نعم', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});
  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
        Container(
          color: AppColors.surface,
          child: Column(
            children: items.map((item) => _buildTile(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTile(_MenuItem item) {
    return ListTile(
      leading:
          Icon(item.icon, color: item.color ?? AppColors.primary, size: 22),
      title: Text(
        item.label,
        style: AppTypography.bodyMedium.copyWith(
          color: item.color ?? AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 14, color: AppColors.textHint),
      onTap: item.onTap,
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
}
