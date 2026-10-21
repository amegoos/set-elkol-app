import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class VendorShell extends StatelessWidget {
  const VendorShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.navBackground,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
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
                    label: 'الرئيسية',
                    index: 0,
                    current: shell.currentIndex,
                    onTap: () => shell.goBranch(0)),
                _NavItem(
                    icon: Icons.inventory_2_outlined,
                    activeIcon: Icons.inventory_2,
                    label: 'المنتجات',
                    index: 1,
                    current: shell.currentIndex,
                    onTap: () => shell.goBranch(1)),
                _NavItem(
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long,
                    label: 'الطلبات',
                    index: 2,
                    current: shell.currentIndex,
                    onTap: () => shell.goBranch(2)),
                _NavItem(
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart,
                    label: 'الأرباح',
                    index: 3,
                    current: shell.currentIndex,
                    onTap: () => shell.goBranch(3)),
                _NavItem(
                    icon: Icons.storefront_outlined,
                    activeIcon: Icons.storefront,
                    label: 'متجري',
                    index: 4,
                    current: shell.currentIndex,
                    onTap: () => shell.goBranch(4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.index,
      required this.current,
      required this.onTap});
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final VoidCallback onTap;
  bool get isActive => index == current;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon,
                color: isActive ? AppColors.accent : AppColors.navUnselected,
                size: 24),
            const SizedBox(height: 2),
            Text(label,
                style: AppTypography.labelSmall.copyWith(
                  color: isActive ? AppColors.accent : AppColors.navUnselected,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }
}
