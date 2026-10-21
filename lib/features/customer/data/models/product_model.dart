import '../../../../core/domain/entities/product.dart';
import '../../../../core/domain/entities/vendor.dart';
import '../../../../core/domain/entities/category.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.vendorId,
    required super.categoryId,
    required super.name,
    required super.price,
    required super.isAvailable,
    required super.isFeatured,
    required super.isVegetarian,
    required super.isSpicy,
    required super.additionalImages,
    required super.createdAt,
    required super.updatedAt,
    super.description,
    super.imageUrl,
    super.availableQuantity,
    super.preparationTimeMinutes,
    super.vendor,
    super.category,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String? ??
          '00000000-0000-0000-0000-000000000001',
      categoryId: json['category_id'] as String? ?? 'cat-1',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      additionalImages: (json['additional_images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      availableQuantity: json['available_quantity'] as int?,
      preparationTimeMinutes: json['preparation_time_minutes'] as int?,
      isAvailable: json['is_available'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      isVegetarian: json['is_vegetarian'] as bool? ?? false,
      isSpicy: json['is_spicy'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vendor_id': vendorId,
        'category_id': categoryId,
        'name': name,
        'description': description,
        'price': price,
        'image_url': imageUrl,
        'additional_images': additionalImages,
        'available_quantity': availableQuantity,
        'preparation_time_minutes': preparationTimeMinutes,
        'is_available': isAvailable,
        'is_featured': isFeatured,
        'is_vegetarian': isVegetarian,
        'is_spicy': isSpicy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
