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
import '../providers/auth_provider.dart';

class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  UserRole? _selected;
  bool _isLoading = false;

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() => _isLoading = true);
    try {
      final error = await ref.read(authProvider.notifier).setRole(_selected!);
      if (!mounted) return;
      if (error != null) {
        context.showSnack(error, isError: true);
      } else {
        if (_selected == UserRole.vendor) {
          context.go(RouteNames.vendorSetup);
        } else {
          context.go(RouteNames.customerHome);
        }
      }
    } catch (e) {
      if (mounted) {
        context.showSnack('حدث خطأ أثناء حفظ الدور المحدد', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                'مرحباً بك في ست الكل! 🎉',
                style: AppTypography.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'اختر دورك للبدء',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              _RoleCard(
                title: 'أنا عميل',
                subtitle: 'أريد الطلب وتذوق أكل بيتي أصيل',
                icon: Icons.shopping_basket_outlined,
                isSelected: _selected == UserRole.customer,
                onTap: () => setState(() => _selected = UserRole.customer),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                title: 'أنا بائع',
                subtitle: 'أريد البيع ومشاركة وصفاتي البيتية',
                icon: Icons.storefront_outlined,
                isSelected: _selected == UserRole.vendor,
                onTap: () => setState(() => _selected = UserRole.vendor),
              ),
              const Spacer(),
              AppButton(
                label: 'تأكيد الاختيار',
                onPressed: _selected != null ? _confirm : null,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.background,
                borderRadius: AppRadius.medium,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
