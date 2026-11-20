import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';

/// Screen displaying Terms of Service, Privacy Policy, and Data Safety for Set El Kol.
/// Fully compliant with Apple App Store Guideline 5.1.1 and Google Play Policy.
class LegalScreen extends ConsumerStatefulWidget {
  const LegalScreen({super.key});

  @override
  ConsumerState<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends ConsumerState<LegalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF12121C) : const Color(0xFFF9F9FB);
    final cardColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('الشروط وسياسة الخصوصية'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor:
              isDark ? Colors.grey.shade400 : AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'الخصوصية', icon: Icon(Icons.privacy_tip_outlined, size: 20)),
            Tab(text: 'الشروط', icon: Icon(Icons.gavel_outlined, size: 20)),
            Tab(text: 'حذف البيانات', icon: Icon(Icons.security_outlined, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPrivacyTab(cardColor, isDark),
          _buildTermsTab(cardColor, isDark),
          _buildDataSafetyTab(cardColor, isDark),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab(Color cardColor, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderBadge(
            title: 'سياسة الخصوصية (Privacy Policy)',
            subtitle: 'تطبيق ست الكل يلتزم بحماية خصوصية بياناتك بالكامل.',
            icon: Icons.shield_outlined,
            color: AppColors.primary,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildPolicyCard(
            cardColor: cardColor,
            isDark: isDark,
            icon: Icons.contact_page_outlined,
            title: '1. البيانات التي نجمعها',
            content:
                '• الاسم والبريد الإلكتروني ورقم الهاتف لإنشاء الحساب وتأكيد الطلبات.\n'
                '• عنوان التوصيل المحدد من قبلك لتوصيل الوجبات بدقة.\n'
                '• سجل الطلبات والمأكولات المفضلة لتسهيل إعادة الطلب.',
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            cardColor: cardColor,
            isDark: isDark,
            icon: Icons.lock_outline,
            title: '2. كيف نستخدم بياناتك ونحميها',
            content:
                '• نستخدم بياناتك فقط لمعالجة وتوصيل طلبات الأكل المنزلي والتواصل معك.\n'
                '• جميع البيانات مشفرة باستخدام تقنيات Google Firebase و HTTPS المعتمدة عالمياً.\n'
                '• لا نقوم إطلاقاً ببيع أو مشاركة بياناتك مع أي طرف ثالث لأغراض إعلانية.',
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            cardColor: cardColor,
            isDark: isDark,
            icon: Icons.manage_accounts_outlined,
            title: '3. حقوقك وحذف الحساب',
            content:
                '• لديك الحق الكامل في تعديل بياناتك الشخصية في أي وقت من شاشة الملف الشخصي.\n'
                '• يمكنك حذف حسابك وجميع بياناتك نهائياً من زر "حذف الحساب" المتاح في إعدادات التطبيق دون أي تعقيد.',
          ),
          const SizedBox(height: 24),
          _buildSupportFooter(isDark),
        ],
      ),
    );
  }

  Widget _buildTermsTab(Color cardColor, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderBadge(
            title: 'شروط وأحكام الاستخدام (Terms of Service)',
            subtitle: 'القواعد والضمانات المنظمة لخدمة ست الكل للأكل البيتي المصري.',
            icon: Icons.assignment_outlined,
            color: AppColors.accent,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildPolicyCard(
            cardColor: cardColor,
            isDark: isDark,
            icon: Icons.store_outlined,
            title: '1. طبيعة منصة ست الكل',
            content:
                '• تطبيق ست الكل هو منصة وسيطة متخصصة تربط الطاهيات وربات البيوت الماهرات بالعملاء الباحثين عن أكل بيتي مصري أصيل ونظيف.\n'
                '• تلتزم الطاهيات بتجهيز الوجبات طازجة طبقاً لأعلى معايير النظافة والجودة المنزلية.',
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            cardColor: cardColor,
            isDark: isDark,
            icon: Icons.delivery_dining_outlined,
            title: '2. الطلبات وسياسة التوصيل',
            content:
                '• يتم تجهيز الطلب فور تأكيده من المطبخ وإرسال إشعار للعميل.\n'
                '• مندوب التوصيل يتبع المسار المحدد للوصول في الوقت التقديري المحدد.\n'
                '• يحق للعميل فحص الوجبة والتأكد من استلامها مغلفة تماماً بحالة ممتازة.',
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            cardColor: cardColor,
            isDark: isDark,
            icon: Icons.published_with_changes_outlined,
            title: '3. الإلغاء والتعويض',
            content:
                '• يمكن للعميل إلغاء الطلب مجاناً طالما كان في حالة "قيد الانتظار" وقبل بدء المطبخ في التحضير.\n'
                '• في حال حدوث أي خطأ في الأصناف أو عدم مطابقتها، يضمن فريق الدعم تعويض العميل فوراً بعد التواصل.',
          ),
          const SizedBox(height: 24),
          _buildSupportFooter(isDark),
        ],
      ),
    );
  }

  Widget _buildDataSafetyTab(Color cardColor, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderBadge(
            title: 'أمان البيانات وحذف الحساب (Data Deletion)',
            subtitle: 'تحكم كامل وشفاف في بياناتك الشخصية.',
            icon: Icons.verified_user_outlined,
            color: const Color(0xFF2E7D32),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildPolicyCard(
            cardColor: cardColor,
            isDark: isDark,
            icon: Icons.delete_forever_outlined,
            title: 'كيف تحذف حسابك وبياناتك؟',
            content:
                '1. افتح تبويب "حسابي" (Profile) من الشريط السفلي.\n'
                '2. انزل إلى قسم "الإعدادات والدعم".\n'
                '3. اضغط على خيار "حذف الحساب" باللون الأحمر.\n'
                '4. أكّد العملية في النافذة المنبثقة، وسيتم فوراً:\n'
                '   • مسح ملفك الشخصي بالكامل من قاعدة البيانات.\n'
                '   • حذف عنوانك ورقم هاتفك وسجل نشاطك.\n'
                '   • تسجيل خروجك نهائياً وحذف الحساب من سيرفرات Firebase.',
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            cardColor: cardColor,
            isDark: isDark,
            icon: Icons.security_rounded,
            title: 'الامتثال لمعايير Apple & Google',
            content:
                '• يتوافق تطبيق ست الكل بشكل كامل مع متطلبات متجر آبل App Store Review Guideline 5.1.1.\n'
                '• يتوافق مع معايير Google Play Data Safety للخصوصية وحماية المستهلك.\n'
                '• لا يتم تخزين أي بيانات بنكية أو بطاقات دفع على سيرفراتنا إطلاقاً.',
          ),
          const SizedBox(height: 24),
          _buildSupportFooter(isDark),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headlineSmall.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard({
    required Color cardColor,
    required bool isDark,
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headlineSmall.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.grey.shade300 : const Color(0xFF4A4A5A),
              height: 1.55,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportFooter(bool isDark) {
    return Column(
      children: [
        Text(
          'تطبيق ست الكل - الإصدار 2.0.0 (نوفمبر 2026)',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => context.push(RouteNames.support),
          icon: const Icon(Icons.support_agent, size: 18),
          label: const Text('هل لديك استفسار؟ تواصلي مع فريق الدعم'),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
