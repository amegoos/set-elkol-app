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
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/extensions/build_context_ext.dart';
import '../../../../core/data/demo_data_service.dart';
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
  XFile? _pickedImageFile;
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

  Future<void> _loadProduct() async {
    final demoProducts = DemoDataService.instance.rawProducts;
    final match =
        demoProducts.where((p) => p['id'] == widget.productId).toList();
    if (match.isNotEmpty) {
      _fillFromMap(match.first);
      return;
    }

    try {
      final db = ref.read(firebaseDatabaseProvider);
      final snapshot = await db.ref('products/${widget.productId!}').get();
      if (snapshot.exists && snapshot.value is Map && mounted) {
        final map = Map<String, dynamic>.from(snapshot.value as Map);
        map['id'] ??= widget.productId;
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

  void _applyDishPreset(DishPhotoPreset preset) {
    setState(() {
      _selectedImageUrl = preset.imageUrl;
      _imageUrlCtrl.text = preset.imageUrl;
      _pickedImageFile = null;

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
    });

    context.showSnack('تم اختيار "${preset.title}" وتعبئة البيانات المقترحة ✨');
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _pickedImageFile = picked;
          _selectedImageUrl = picked.path;
          _imageUrlCtrl.text = picked.path;
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
      final db = ref.read(firebaseDatabaseProvider);
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
        'updated_at': DateTime.now().toIso8601String(),
      };

      DemoDataService.instance.addOrUpdateProduct(productData);

      try {
        if (!isEditing) {
          productData['created_at'] = DateTime.now().toIso8601String();
        }
        await db.ref('products/$productId').update(productData);
      } catch (err) {
        debugPrint('[ProductSave] Firebase sync error: $err');
      }

      if (!mounted) return;
      context.showSnack(isEditing
          ? 'تم تحديث الأكلة بنجاح ✓'
          : 'تم إضافة الأكلة إلى المنيو بنجاح ✓');

      ref.invalidate(myProductsProvider);
      ref.invalidate(featuredProductsProvider);
      ref.invalidate(popularProductsProvider);
      ref.invalidate(productsByCategoryProvider);

      context.pop();
    } catch (e) {
      if (!mounted) return;
      context.showSnack('حدث خطأ أثناء الحفظ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    title: const Text('متاح للطلب الآن'),
                    subtitle:
                        const Text('يظهر في المنيو ويمكن للعملاء طلبه مباشرة'),
                    value: _isAvailable,
                    onChanged: (v) => setState(() => _isAvailable = v),
                    activeColor: AppColors.success,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('أكلة مميزة (في واجهة التطبيق)'),
                    subtitle: const Text(
                        'عرض الأكلة في قسم "المميز ✨" على الصفحة الرئيسية'),
                    value: _isFeatured,
                    onChanged: (v) => setState(() => _isFeatured = v),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('أكل نباتي / صيامي'),
                    value: _isVegetarian,
                    onChanged: (v) => setState(() => _isVegetarian = v),
                    activeColor: AppColors.success,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('أكل حار (سبايسي 🌶️)'),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              Text(title,
                  style: AppTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.bold)),
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

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
            if (_pickedImageFile != null && !kIsWeb)
              Image.file(File(_pickedImageFile!.path), fit: BoxFit.cover)
            else if (_selectedImageUrl!.startsWith('assets/'))
              Image.asset(_selectedImageUrl!, fit: BoxFit.cover)
            else
              CachedNetworkImage(
                imageUrl: _selectedImageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.secondary,
                  child: const Center(
                      child: Icon(Icons.restaurant_rounded,
                          size: 48, color: AppColors.primary)),
                ),
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
              color: AppColors.secondary.withOpacity(0.5),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 48, color: AppColors.primary),
                  SizedBox(height: 8),
                  Text('أضيفي صورة شهية للأكلة البيتي',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
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
                        size: 18, color: AppColors.primary),
                    label: const Text('من المعرض',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
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
                        size: 18, color: AppColors.primary),
                    label: const Text('التقاط بالكاميرا',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
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
