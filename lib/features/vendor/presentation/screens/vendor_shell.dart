import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class VendorShell extends ConsumerWidget {
  const VendorShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);
    final isAr = locale.languageCode == 'ar';

    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black45 : AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: isAr ? 'الرئيسية' : 'Dashboard',
                  index: 0,
                  current: shell.currentIndex,
                  isDark: isDark,
                  onTap: () => shell.goBranch(0, initialLocation: shell.currentIndex == 0),
                ),
                _NavItem(
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  label: isAr ? 'المنتجات' : 'Products',
                  index: 1,
                  current: shell.currentIndex,
                  isDark: isDark,
                  onTap: () => shell.goBranch(1, initialLocation: shell.currentIndex == 1),
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: isAr ? 'الطلبات' : 'Orders',
                  index: 2,
                  current: shell.currentIndex,
                  isDark: isDark,
                  onTap: () => shell.goBranch(2, initialLocation: shell.currentIndex == 2),
                ),
                _NavItem(
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
                  label: isAr ? 'الأرباح' : 'Earnings',
                  index: 3,
                  current: shell.currentIndex,
                  isDark: isDark,
                  onTap: () => shell.goBranch(3, initialLocation: shell.currentIndex == 3),
                ),
                _NavItem(
                  icon: Icons.storefront_outlined,
                  activeIcon: Icons.storefront,
                  label: isAr ? 'متجري' : 'My Kitchen',
                  index: 4,
                  current: shell.currentIndex,
                  isDark: isDark,
                  onTap: () => shell.goBranch(4, initialLocation: shell.currentIndex == 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final bool isDark;
  final VoidCallback onTap;
  bool get isActive => index == current;

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.accentLight : AppColors.accent;
    final unselectedColor = isDark ? Colors.white60 : AppColors.navUnselected;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeColor : unselectedColor,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isActive ? activeColor : unselectedColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
