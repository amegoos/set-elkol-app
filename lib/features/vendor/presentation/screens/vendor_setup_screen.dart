import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class VendorSetupScreen extends ConsumerStatefulWidget {
  const VendorSetupScreen({super.key});

  @override
  ConsumerState<VendorSetupScreen> createState() => _VendorSetupScreenState();
}

class _VendorSetupScreenState extends ConsumerState<VendorSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _feeCtrl = TextEditingController(text: '20');
  final _minOrderCtrl = TextEditingController(text: '50');
  final _radiusCtrl = TextEditingController(text: '5');
  final _prepTimeCtrl = TextEditingController(text: '45');
  String? _selectedGov;
  bool _offersDelivery = true;
  bool _offersPickup = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _areaCtrl.dispose();
    _feeCtrl.dispose();
    _minOrderCtrl.dispose();
    _radiusCtrl.dispose();
    _prepTimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await client.from('vendors').upsert({
        'id': userId,
        'business_name': _nameCtrl.text.trim(),
        'bio': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'governorate': _selectedGov,
        'area': _areaCtrl.text.trim().isEmpty ? null : _areaCtrl.text.trim(),
        'delivery_fee': _feeCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_feeCtrl.text),
        'min_order_amount': _minOrderCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_minOrderCtrl.text),
        'delivery_radius_km': _radiusCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_radiusCtrl.text),
        'avg_prep_time_minutes': _prepTimeCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_prepTimeCtrl.text),
        'offers_delivery': _offersDelivery,
        'offers_pickup': _offersPickup,
        'delivery_available': _offersDelivery,
        'pickup_available': _offersPickup,
        'is_active': true,
        'is_verified': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update profile role
      await ref.read(authProvider.notifier).setRole(
            UserRole.vendor,
          );

      if (!mounted) return;
      context.go(RouteNames.vendorDashboard);
    } catch (e) {
      if (!mounted) return;
      context.showSnack('حدث خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('إعداد متجرك')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('أهلاً بك كبائع! 🏪', style: AppTypography.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'أخبرنا عن متجرك لنساعد العملاء في العثور عليك.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              AppTextField(
                controller: _nameCtrl,
                label: 'اسم المتجر *',
                hint: 'مثال: مطبخ أم أحمد',
                prefix: const Icon(Icons.store_outlined, size: 20),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'أدخل اسم المتجر' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _descCtrl,
                label: 'وصف المتجر',
                hint: 'عرّف بنفسك وبأصناف أكلك...',
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _selectedGov,
                decoration: const InputDecoration(
                  labelText: 'المحافظة',
                  prefixIcon: Icon(Icons.map_outlined, size: 20),
                ),
                items: AppConstants.egyptGovernorates
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedGov = v),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _areaCtrl,
                label: 'المنطقة / الحي',
                hint: 'مثال: مدينة نصر، التجمع الخامس',
                prefix: const Icon(Icons.location_on_outlined, size: 20),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _feeCtrl,
                label: 'رسوم التوصيل (ج.م)',
                hint: 'مثال: 20',
                keyboardType: TextInputType.number,
                prefix: const Icon(Icons.delivery_dining_outlined, size: 20),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _minOrderCtrl,
                label: 'حد أدنى للطلب (ج.م)',
                hint: 'مثال: 50',
                keyboardType: TextInputType.number,
                prefix: const Icon(Icons.shopping_cart_outlined, size: 20),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _radiusCtrl,
                label: 'نطاق التوصيل (كم)',
                hint: 'مثال: 5',
                keyboardType: TextInputType.number,
                prefix: const Icon(Icons.map_outlined, size: 20),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _prepTimeCtrl,
                label: 'متوسط وقت التحضير (دقيقة)',
                hint: 'مثال: 45',
                keyboardType: TextInputType.number,
                prefix: const Icon(Icons.timer_outlined, size: 20),
              ),
              const SizedBox(height: 20),
              Text('طرق التوصيل', style: AppTypography.titleMedium),
              SwitchListTile(
                title: const Text('توصيل للعميل'),
                value: _offersDelivery,
                onChanged: (v) => setState(() => _offersDelivery = v),
                activeColor: AppColors.primary,
              ),
              SwitchListTile(
                title: const Text('استلام ذاتي'),
                value: _offersPickup,
                onChanged: (v) => setState(() => _offersPickup = v),
                activeColor: AppColors.primary,
              ),
              const SizedBox(height: 28),
              AppButton(
                label: 'إنشاء المتجر',
                onPressed: _submit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
