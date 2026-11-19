import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/domain/entities/user_profile.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    if (profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(RouteNames.login);
        }
      });
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.background,
      appBar: AppBar(
        title: Text(isAr ? 'حسابي' : 'My Account'),
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : AppColors.surface,
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
              color: isDark ? const Color(0xFF1E1E2E) : AppColors.surface,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: isDark ? const Color(0xFF2D2D3E) : AppColors.secondary,
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name[0].toUpperCase()
                          : 'U',
                      style: AppTypography.headlineLarge
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.name,
                    style: AppTypography.headlineSmall.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (profile.email != null)
                    Text(
                      profile.email!,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
                      ),
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
                      profile.isVendor
                          ? (isAr ? 'طاهية / بائعة' : 'Cook / Vendor')
                          : (isAr ? 'عميل' : 'Customer'),
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
              title: isAr ? 'حسابي' : 'Account',
              items: [
                _MenuItem(
                  icon: Icons.favorite_border,
                  label: isAr ? 'المفضلة' : 'Favorites',
                  onTap: () =>
                      context.push('${RouteNames.customerProfile}/favorites'),
                ),
                _MenuItem(
                  icon: Icons.location_on_outlined,
                  label: isAr ? 'العناوين المحفوظة' : 'Saved Addresses',
                  onTap: () =>
                      context.push('${RouteNames.customerProfile}/addresses'),
                ),
                _MenuItem(
                  icon: Icons.receipt_long_outlined,
                  label: isAr ? 'سجل الطلبات' : 'Order History',
                  onTap: () => context.go(RouteNames.customerOrders),
                ),
              ],
            ),

            if (!profile.isVendor)
              _MenuSection(
                title: isAr ? 'البيع في ست الكل' : 'Selling on Set El Kol',
                items: [
                  _MenuItem(
                    icon: Icons.storefront_outlined,
                    label: isAr
                        ? 'أصبح بائعاً (انضمي كطاهية منزلية)'
                        : 'Become a Vendor',
                    onTap: () => _switchRole(context, ref),
                    color: AppColors.accent,
                  ),
                ],
              ),

            if (profile.isVendor)
              _MenuSection(
                title: isAr ? 'متجري' : 'My Kitchen',
                items: [
                  _MenuItem(
                    icon: Icons.dashboard_outlined,
                    label: isAr ? 'لوحة التحكم' : 'Vendor Dashboard',
                    onTap: () => context.go(RouteNames.vendorDashboard),
                    color: AppColors.accent,
                  ),
                  _MenuItem(
                    icon: Icons.person_outline,
                    label: isAr ? 'العودة لوضع العميل' : 'Switch to Customer',
                    onTap: () => _switchRole(context, ref),
                    color: AppColors.primary,
                  ),
                ],
              ),

            if (profile.isAdmin)
              _MenuSection(
                title: isAr ? 'إدارة النظام 🛡️' : 'Admin Management 🛡️',
                items: [
                  _MenuItem(
                    icon: Icons.admin_panel_settings_outlined,
                    label:
                        isAr ? 'لوحة تحكم الإدارة (Admin)' : 'Admin Dashboard',
                    color: AppColors.pickupBadge,
                    onTap: () => context.go(RouteNames.adminDashboard),
                  ),
                ],
              ),

            _MenuSection(
              title: isAr ? 'الإعدادات والدعم' : 'Settings & Support',
              items: [
                _MenuItem(
                  icon: themeMode == ThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : (themeMode == ThemeMode.light
                          ? Icons.light_mode_rounded
                          : Icons.brightness_auto_rounded),
                  label: isAr
                      ? 'المظهر (${_getThemeLabel(themeMode, isAr)})'
                      : 'Appearance (${_getThemeLabel(themeMode, isAr)})',
                  onTap: () => _showThemeModal(context, ref),
                ),
                _MenuItem(
                  icon: Icons.language_outlined,
                  label:
                      isAr ? 'اللغة (العربية 🇪🇬)' : 'Language (English 🇬🇧)',
                  onTap: () => _showLanguageModal(context, ref),
                ),
                _MenuItem(
                  icon: Icons.support_agent_outlined,
                  label: isAr
                      ? 'المساعدة والدعم (Gmail & اتصالات)'
                      : 'Help & Support (Gmail & Calls)',
                  onTap: () {
                    debugPrint(
                        '>>> [ProfileScreen] Help & Support tapped! <<<');
                    context.push(RouteNames.support);
                  },
                ),
                _MenuItem(
                  icon: Icons.logout,
                  label: isAr ? 'تسجيل الخروج' : 'Logout',
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

  String _getThemeLabel(ThemeMode mode, bool isAr) {
    switch (mode) {
      case ThemeMode.dark:
        return isAr ? 'داكن 🌙' : 'Dark 🌙';
      case ThemeMode.light:
        return isAr ? 'فاتح ☀️' : 'Light ☀️';
      case ThemeMode.system:
        return isAr ? 'تلقائي 🌓' : 'Automatic 🌓';
    }
  }

  void _showThemeModal(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeModeProvider);
    final isAr = ref.read(localeProvider).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAr ? 'اختر مظهر التطبيق' : 'Choose App Theme',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildThemeOption(
                context: sheetCtx,
                ref: ref,
                mode: ThemeMode.system,
                title: isAr ? 'تلقائي (حسب نظام الجهاز)' : 'Automatic (System Default)',
                subtitle: isAr
                    ? 'يتغير تلقائياً مع مظهر هاتفك'
                    : 'Matches your phone system theme',
                icon: Icons.brightness_auto_rounded,
                isSelected: currentMode == ThemeMode.system,
                isDark: isDark,
              ),
              Divider(color: isDark ? Colors.white12 : Colors.grey.shade200),
              _buildThemeOption(
                context: sheetCtx,
                ref: ref,
                mode: ThemeMode.light,
                title: isAr ? 'الوضع الفاتح' : 'Light Mode',
                subtitle: isAr ? 'ألوان ساطعة وواضحة' : 'Bright and clear colors',
                icon: Icons.light_mode_rounded,
                isSelected: currentMode == ThemeMode.light,
                isDark: isDark,
              ),
              Divider(color: isDark ? Colors.white12 : Colors.grey.shade200),
              _buildThemeOption(
                context: sheetCtx,
                ref: ref,
                mode: ThemeMode.dark,
                title: isAr ? 'الوضع الليلي (الداكن)' : 'Dark Mode',
                subtitle: isAr ? 'مريح للعين وتوفير للبطارية' : 'Easy on eyes and saves battery',
                icon: Icons.dark_mode_rounded,
                isSelected: currentMode == ThemeMode.dark,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
  }) {
    return ListTile(
      leading: Icon(icon,
          color: isSelected ? AppColors.primary : (isDark ? Colors.grey.shade400 : Colors.grey)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.white : AppColors.textPrimary),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
        Navigator.of(context).pop();
      },
    );
  }

  void _showLanguageModal(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'اختيار لغة التطبيق / Choose Language',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Text('🇪🇬', style: TextStyle(fontSize: 24)),
                  title: const Text('العربية (Egyptian Arabic)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: isAr
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: isAr ? AppColors.primary : Colors.grey.shade200),
                  ),
                  tileColor: isAr ? AppColors.primary.withOpacity(0.05) : null,
                  onTap: () {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(const Locale('ar'));
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                  title: const Text('English (الإنجليزية)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: !isAr
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color:
                            !isAr ? AppColors.primary : Colors.grey.shade200),
                  ),
                  tileColor: !isAr ? AppColors.primary.withOpacity(0.05) : null,
                  onTap: () {
                    ref
                        .read(localeProvider.notifier)
                        .setLocale(const Locale('en'));
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
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
        context.go(RouteNames.vendorDashboard);
      } else {
        context.showSnack('تم التبديل إلى وضع العميل ✓');
        context.go(RouteNames.customerHome);
      }
    }
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'تسجيل الخروج',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'هل تريد تأكيد تسجيل الخروج والعودة للشاشة الرئيسية؟',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go(RouteNames.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('تسجيل الخروج'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
            ),
          ),
        ),
        Material(
          color: isDark ? const Color(0xFF1E1E2E) : AppColors.surface,
          child: Column(
            children: items.map((item) => _buildTile(context, item, isDark)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, _MenuItem item, bool isDark) {
    return ListTile(
      leading:
          Icon(item.icon, color: item.color ?? AppColors.primary, size: 22),
      title: Text(
        item.label,
        style: AppTypography.bodyMedium.copyWith(
          color: item.color ?? (isDark ? Colors.white : AppColors.textPrimary),
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 14, color: isDark ? Colors.grey.shade500 : AppColors.textHint),
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
