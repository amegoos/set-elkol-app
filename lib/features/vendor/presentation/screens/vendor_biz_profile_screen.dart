import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/firebase_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/vendor_providers.dart';

class VendorBizProfileScreen extends ConsumerStatefulWidget {
  const VendorBizProfileScreen({super.key});

  @override
  ConsumerState<VendorBizProfileScreen> createState() =>
      _VendorBizProfileScreenState();
}

class _VendorBizProfileScreenState
    extends ConsumerState<VendorBizProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  String? _selectedGov;
  bool _offersDelivery = true;
  bool _offersPickup = false;
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _areaCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myVendorProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('بيانات المتجر')),
      body: profileAsync.when(
        data: (vendor) {
          if (!_initialized && vendor != null) {
            _nameCtrl.text = vendor.name;
            _descCtrl.text = vendor.description ?? '';
            _areaCtrl.text = vendor.area ?? '';
            _feeCtrl.text = vendor.deliveryFee?.toStringAsFixed(0) ?? '';
            _selectedGov = vendor.governorate;
            _offersDelivery = vendor.offersDelivery;
            _offersPickup = vendor.offersPickup;
            _initialized = true;
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                    controller: _nameCtrl,
                    label: 'اسم المتجر',
                    prefix: const Icon(Icons.store_outlined, size: 20)),
                const SizedBox(height: 14),
                AppTextField(
                    controller: _descCtrl, label: 'وصف المتجر', maxLines: 3),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedGov,
                  decoration: const InputDecoration(
                      labelText: 'المحافظة',
                      prefixIcon: Icon(Icons.map_outlined, size: 20)),
                  items: AppConstants.egyptGovernorates
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGov = v),
                ),
                const SizedBox(height: 14),
                AppTextField(
                    controller: _areaCtrl,
                    label: 'المنطقة / الحي',
                    prefix: const Icon(Icons.location_on_outlined, size: 20)),
                const SizedBox(height: 20),
                Text('خيارات التوصيل', style: AppTypography.titleMedium),
                const SizedBox(height: 8),
                SwitchListTile(
                    title: const Text('توصيل للعميل'),
                    value: _offersDelivery,
                    onChanged: (v) => setState(() => _offersDelivery = v),
                    activeColor: AppColors.primary),
                SwitchListTile(
                    title: const Text('استلام ذاتي'),
                    value: _offersPickup,
                    onChanged: (v) => setState(() => _offersPickup = v),
                    activeColor: AppColors.primary),
                if (_offersDelivery) ...[
                  const SizedBox(height: 8),
                  AppTextField(
                      controller: _feeCtrl,
                      label: 'رسوم التوصيل (ج.م)',
                      keyboardType: TextInputType.number,
                      prefix:
                          const Icon(Icons.delivery_dining_outlined, size: 20)),
                ],
                const SizedBox(height: 28),
                AppButton(
                    label: 'حفظ التغييرات',
                    onPressed: _save,
                    isLoading: _isLoading),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
        loading: () => const AppLoadingSpinner(),
        error: (e, _) => AppErrorWidget(message: 'تعذر تحميل بيانات المتجر'),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final auth = ref.read(firebaseAuthProvider);
      final db = ref.read(firebaseDatabaseProvider);
      final userId = auth.currentUser?.uid ??
          ref.read(currentProfileProvider)?.id ??
          'demo-vendor-omahmed-002';

      await db.ref('vendors/$userId').update({
        'id': userId,
        'business_name': _nameCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'description':
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'governorate': _selectedGov,
        'area': _areaCtrl.text.trim().isEmpty ? null : _areaCtrl.text.trim(),
        'offers_delivery': _offersDelivery,
        'offers_pickup': _offersPickup,
        'delivery_fee': _feeCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_feeCtrl.text),
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      context.showSnack('تم حفظ التغييرات ✓');
      ref.invalidate(myVendorProfileProvider);
    } catch (e) {
      if (!mounted) return;
      context.showSnack('حدث خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
