import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/firebase_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_smart_image.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/data/demo_data_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../customer/presentation/providers/customer_providers.dart';
import '../providers/vendor_providers.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  const AddEditProductScreen({super.key, this.productId});
  final String? productId;

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _prepTimeCtrl = TextEditingController(text: '45');
  final _imageUrlCtrl = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedImageUrl;
  bool _isVegetarian = false;
  bool _isSpicy = false;
  bool _isAvailable = true;
  bool _isFeatured = false;
  bool _isLoading = false;

  bool get isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    // Default to first preset image if adding new product
    if (!isEditing && DemoDataService.dishPresets.isNotEmpty) {
      _selectedImageUrl = DemoDataService.dishPresets.first.imageUrl;
      _imageUrlCtrl.text = _selectedImageUrl!;
    }

    if (isEditing) {
      _loadProduct();
    }
  }

  bool _verifyOwnership(Map<String, dynamic> data) {
    final currentUserId = ref.read(firebaseAuthProvider).currentUser?.uid;
    final profile = ref.read(authProvider).profile;
    final isAdmin = profile?.isAdmin == true;
    final ownerVendorId = data['vendor_id']?.toString();

    if (currentUserId != null &&
        ownerVendorId != null &&
        ownerVendorId != currentUserId &&
        !isAdmin) {
      if (mounted) {
        context.showSnack('غير مصرح لك بتعديل هذه الأكلة لأنها تابعة لمطبخ آخر.',
            isError: true);
        context.pop();
      }
      return false;
    }
    return true;
  }

  Future<void> _loadProduct() async {
    final demoProducts = DemoDataService.instance.rawProducts;
    final match =
        demoProducts.where((p) => p['id'] == widget.productId).toList();
    if (match.isNotEmpty) {
      if (!_verifyOwnership(match.first)) return;
      _fillFromMap(match.first);
      return;
    }

    try {
      final db = ref.read(firebaseDatabaseProvider);
      final snapshot = await db.ref('products/${widget.productId!}').get();
      if (snapshot.exists && snapshot.value is Map && mounted) {
        final map = Map<String, dynamic>.from(snapshot.value as Map);
        map['id'] ??= widget.productId;
        if (!_verifyOwnership(map)) return;
        _fillFromMap(map);
      }
    } catch (_) {}
  }

  void _fillFromMap(Map<String, dynamic> data) {
    setState(() {
      _nameCtrl.text = data['name'] as String? ?? '';
      _descCtrl.text = data['description'] as String? ?? '';
      _priceCtrl.text = (data['price'] as num?)?.toString() ?? '';
      _qtyCtrl.text = (data['available_quantity'] as int?)?.toString() ?? '';
      _prepTimeCtrl.text =
          (data['preparation_time_minutes'] as int?)?.toString() ?? '45';
      _selectedCategoryId = data['category_id'] as String?;
      _selectedImageUrl = data['image_url'] as String?;
      if (_selectedImageUrl != null) {
        _imageUrlCtrl.text = _selectedImageUrl!;
      }
      _isVegetarian = data['is_vegetarian'] as bool? ?? false;
      _isSpicy = data['is_spicy'] as bool? ?? false;
      _isAvailable = data['is_available'] as bool? ?? true;
      _isFeatured = data['is_featured'] as bool? ?? false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _prepTimeCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  void _applyDishPreset(DishPhotoPreset preset, {bool imageOnly = false}) {
    setState(() {
      _selectedImageUrl = preset.imageUrl;
      _imageUrlCtrl.text = preset.imageUrl;

      if (!imageOnly) {
        _nameCtrl.text = preset.title;
        _descCtrl.text = preset.suggestedDescription;
        _priceCtrl.text = preset.suggestedPrice.toStringAsFixed(0);
        _qtyCtrl.text = preset.suggestedQuantity.toString();
        _prepTimeCtrl.text = preset.suggestedPrepTime.toString();

        final categories = ref.read(categoriesProvider).asData?.value ??
            DemoDataService.instance.categories;
        final matchedCat = categories
            .where((c) =>
                c.name.contains(preset.categoryName) ||
                preset.categoryName.contains(c.name))
            .toList();
        if (matchedCat.isNotEmpty) {
          _selectedCategoryId = matchedCat.first.id;
        }
      }
    });

    if (imageOnly) {
      context.showSnack('تم تعيين صورة "${preset.title}" بنجاح 🍲');
    } else {
      context.showSnack('تم اختيار "${preset.title}" وتعبئة البيانات المقترحة ✨');
    }
  }

  void _showPresetPickerModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'اختيار صورة طعام جاهزة 🍲',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.grey),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'اختر صورة شهية لأكلتك دون الحاجة لتصويرها (تحافظ على اسم وسعر وجبتك):',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemCount: DemoDataService.dishPresets.length,
                itemBuilder: (c, idx) {
                  final preset = DemoDataService.dishPresets[idx];
                  final isSelected = _selectedImageUrl == preset.imageUrl;
                  return InkWell(
                    onTap: () {
                      _applyDishPreset(preset, imageOnly: true);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white12 : AppColors.cardBorder),
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: AppSmartImage(
                              imageUrl: preset.imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              preset.title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 75,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64String = base64Encode(bytes);
        final dataUri = 'data:image/jpeg;base64,$base64String';
        setState(() {
          _selectedImageUrl = dataUri;
          _imageUrlCtrl.text = dataUri;
        });
      }
    } catch (e) {
      if (mounted) context.showSnack('تعذر اختيار الصورة: $e', isError: true);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final auth = ref.read(firebaseAuthProvider);
      final userId = auth.currentUser?.uid ?? 'demo-vendor-omahmed-002';
      final productId =
          widget.productId ?? 'prod-${DateTime.now().millisecondsSinceEpoch}';

      final finalImageUrl = _selectedImageUrl ??
          (_imageUrlCtrl.text.trim().isNotEmpty
              ? _imageUrlCtrl.text.trim()
              : DemoDataService.dishPresets.first.imageUrl);

      final productData = {
        'id': productId,
        'vendor_id': userId,
        'category_id': _selectedCategoryId ?? 'cat-1',
        'name': _nameCtrl.text.trim(),
        'description':
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'price': double.parse(_priceCtrl.text.trim()),
        'image_url': finalImageUrl,
        'available_quantity':
            _qtyCtrl.text.trim().isEmpty ? 10 : int.parse(_qtyCtrl.text.trim()),
        'preparation_time_minutes': _prepTimeCtrl.text.trim().isEmpty
            ? 30
            : int.parse(_prepTimeCtrl.text.trim()),
        'is_vegetarian': _isVegetarian,
        'is_spicy': _isSpicy,
        'is_available': _isAvailable,
        'is_featured': _isFeatured,
      };

      if (isEditing) {
        await ref.read(vendorProductServiceProvider).editMeal(
              productId: widget.productId!,
              updates: productData,
            );
      } else {
        await ref.read(vendorProductServiceProvider).addMeal(productData);
      }

      if (!mounted) return;
      context.showSnack(isEditing
          ? 'تم تحديث الأكلة بنجاح ✓'
          : 'تم إضافة الأكلة إلى المنيو بنجاح ✓');

      context.pop();
    } catch (e) {
      if (!mounted) return;
      context.showSnack('حدث خطأ أثناء الحفظ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmDelete() {
    final mealName = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()
        : 'هذه الأكلة';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded,
                color: AppColors.error, size: 28),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'حذف الأكلة من المنيو',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من رغبتك في حذف "$mealName" من قائمة الطعام؟',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم إخفاء الوجبة فوراً من تطبيق العملاء، مع الحفاظ الكامل على سجل الطلبات السابقة.',
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              setState(() => _isLoading = true);
              try {
                await ref
                    .read(vendorProductServiceProvider)
                    .deleteMeal(widget.productId!);
                if (!mounted) return;
                context.showSnack('تم حذف "$mealName" من المنيو بنجاح ✓');
                context.pop();
              } catch (e) {
                if (!mounted) return;
                context.showSnack('حدث خطأ أثناء الحذف: $e', isError: true);
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories =
        categoriesAsync.asData?.value ?? DemoDataService.instance.categories;

    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل الأكلة' : 'إضافة أكلة بيتي جديدة'),
        centerTitle: true,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'حذف الأكلة',
              onPressed: _isLoading ? null : _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageHeader(),
              const SizedBox(height: 16),
              _buildDishPresetsSelector(),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: 'تفاصيل الأكلة',
                icon: Icons.restaurant_menu_rounded,
                children: [
                  AppTextField(
                    controller: _nameCtrl,
                    label: 'اسم الأكلة / الطبق *',
                    hint:
                        'مثال: محشي مشكل، ملوخية بالفراخ، صينية مكرونة بشاميل',
                    prefix: const Icon(Icons.fastfood_outlined, size: 20),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'أدخل اسم الأكلة'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'التصنيف *',
                      prefixIcon: const Icon(Icons.category_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: AppRadius.input),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategoryId,
                        isDense: true,
                        isExpanded: true,
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Text(
                              cat.name,
                              style: AppTypography.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategoryId = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _descCtrl,
                    label: 'وصف الأكلة وطريقة عملها',
                    hint:
                        'اذكري مكوناتك وسرك في الطبخ، مثل: بالسمن البلدي، خلطة أرز خاصة...',
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'السعر والكمية المتاحة',
                icon: Icons.payments_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _priceCtrl,
                          label: 'السعر (ج.م) *',
                          hint: 'مثال: 120',
                          keyboardType: TextInputType.number,
                          prefix: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('ج.م',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary)),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'أدخل السعر';
                            }
                            final parsed = double.tryParse(v.trim());
                            if (parsed == null || parsed <= 0) {
                              return 'سعر غير صالح';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _qtyCtrl,
                          label: 'الكمية الجاهزة *',
                          hint: 'مثال: 10 وجبات',
                          keyboardType: TextInputType.number,
                          prefix:
                              const Icon(Icons.inventory_2_outlined, size: 20),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'أدخل الكمية';
                            }
                            final parsed = int.tryParse(v.trim());
                            if (parsed == null || parsed < 0) {
                              return 'كمية غير صالحة';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _prepTimeCtrl,
                    label: 'وقت التحضير والتجهيز (بالدقائق)',
                    hint: 'مثال: 45 دقيقة',
                    keyboardType: TextInputType.number,
                    prefix: const Icon(Icons.timer_outlined, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'خيارات التوفر والمميزات',
                icon: Icons.tune_rounded,
                children: [
                  SwitchListTile(
                    title: Text(
                      'متاح للطلب الآن',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'يظهر في المنيو ويمكن للعملاء طلبه مباشرة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                    value: _isAvailable,
                    onChanged: (v) => setState(() => _isAvailable = v),
                    activeColor: AppColors.success,
                    contentPadding: EdgeInsets.zero,
                  ),
                  Divider(height: 1, color: isDark ? Colors.white12 : AppColors.divider),
                  SwitchListTile(
                    title: Text(
                      'أكلة مميزة (في واجهة التطبيق ✨)',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'عرض الأكلة في قسم "المميز ✨" على الصفحة الرئيسية',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                    value: _isFeatured,
                    onChanged: (v) => setState(() => _isFeatured = v),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  Divider(height: 1, color: isDark ? Colors.white12 : AppColors.divider),
                  SwitchListTile(
                    title: Text(
                      'أكل نباتي / صيامي 🌱',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'مناسب لمن يفضلون الأكل النباتي والصيامي',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                    value: _isVegetarian,
                    onChanged: (v) => setState(() => _isVegetarian = v),
                    activeColor: AppColors.success,
                    contentPadding: EdgeInsets.zero,
                  ),
                  Divider(height: 1, color: isDark ? Colors.white12 : AppColors.divider),
                  SwitchListTile(
                    title: Text(
                      'أكل حار (سبايسي 🌶️)',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'إضافة شطة وتوابل حارة للوجبة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                    value: _isSpicy,
                    onChanged: (v) => setState(() => _isSpicy = v),
                    activeColor: AppColors.warning,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppButton(
                label: isEditing ? 'حفظ التعديلات' : 'نشر الأكلة في المنيو 🚀',
                onPressed: _save,
                isLoading: _isLoading,
              ),
              if (isEditing) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _confirmDelete,
                  icon:
                      const Icon(Icons.delete_outline, color: AppColors.error),
                  label: const Text(
                    'حذف هذه الأكلة من المنيو',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.button,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: AppRadius.card,
        border: Border.all(color: isDark ? Colors.white12 : AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildImageHeader() {
    final hasImage = _selectedImageUrl != null && _selectedImageUrl!.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: isDark ? Colors.white12 : AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage) ...[
            AppSmartImage(
              imageUrl: _selectedImageUrl,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4)
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ] else ...[
            Container(
              color: isDark ? const Color(0xFF262638) : AppColors.secondary.withOpacity(0.5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined,
                      size: 48, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text('أضيفي صورة شهية للأكلة البيتي',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary)),
                ],
              ),
            ),
          ],
          Positioned(
            bottom: 12,
            right: 12,
            left: 12,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showPresetPickerModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.95),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.auto_awesome,
                        size: 16, color: AppColors.accent),
                    label: const Text('صورة جاهزة 🍲',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.photo_library_outlined,
                        size: 16, color: AppColors.primary),
                    label: const Text('المعرض',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined,
                        size: 16, color: AppColors.primary),
                    label: const Text('الكاميرا',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          if (hasImage)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        color: AppColors.success, size: 14),
                    SizedBox(width: 4),
                    Text('صورة حقيقية محددة',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDishPresetsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.accent, size: 18),
            const SizedBox(width: 6),
            Text(
              'أو اختاري من أكلات ست الكل الجاهزة (صور وأسعار حقيقية):',
              style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 135,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: DemoDataService.dishPresets.length,
            itemBuilder: (context, index) {
              final preset = DemoDataService.dishPresets[index];
              final isSelected = _selectedImageUrl == preset.imageUrl;

              return GestureDetector(
                onTap: () => _applyDishPreset(preset),
                child: Container(
                  width: 115,
                  margin: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : AppColors.cardBorder,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.15)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            preset.imageUrl.startsWith('assets/')
                                ? Image.asset(preset.imageUrl,
                                    fit: BoxFit.cover)
                                : CachedNetworkImage(
                                    imageUrl: preset.imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                            if (isSelected)
                              Container(
                                color: AppColors.primary.withOpacity(0.25),
                                child: const Center(
                                  child: Icon(Icons.check_circle,
                                      color: Colors.white, size: 28),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset.categoryName,
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              preset.title,
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${preset.suggestedPrice.toStringAsFixed(0)} ج.م',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
