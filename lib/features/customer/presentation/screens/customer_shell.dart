import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/customer_providers.dart';

class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
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
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: isAr ? 'الرئيسية' : 'Home',
                  index: 0,
                  currentIndex: shell.currentIndex,
                  isDark: isDark,
                  onTap: () => shell.goBranch(0, initialLocation: shell.currentIndex == 0),
                ),
                _NavItem(
                  icon: Icons.search_outlined,
                  activeIcon: Icons.search,
                  label: isAr ? 'بحث' : 'Search',
                  index: 1,
                  currentIndex: shell.currentIndex,
                  isDark: isDark,
                  onTap: () => shell.goBranch(1, initialLocation: shell.currentIndex == 1),
                ),
                _NavItemBadge(
                  icon: Icons.shopping_basket_outlined,
                  activeIcon: Icons.shopping_basket,
                  label: isAr ? 'السلة' : 'Cart',
                  index: 2,
                  currentIndex: shell.currentIndex,
                  badgeCount: cartState.totalItems,
                  isDark: isDark,
                  onTap: () => shell.goBranch(2, initialLocation: shell.currentIndex == 2),
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: isAr ? 'طلباتي' : 'Orders',
                  index: 3,
                  currentIndex: shell.currentIndex,
                  isDark: isDark,
                  onTap: () => shell.goBranch(3, initialLocation: shell.currentIndex == 3),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: isAr ? 'حسابي' : 'Profile',
                  index: 4,
                  currentIndex: shell.currentIndex,
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
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final bool isDark;
  final VoidCallback onTap;

  bool get isActive => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.primaryLight : AppColors.navSelected;
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

class _NavItemBadge extends StatelessWidget {
  const _NavItemBadge({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.badgeCount,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final int badgeCount;
  final bool isDark;
  final VoidCallback onTap;

  bool get isActive => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.primaryLight : AppColors.navSelected;
    final unselectedColor = isDark ? Colors.white60 : AppColors.navUnselected;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? activeColor : unselectedColor,
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textOnPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
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
