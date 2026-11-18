import 'package:equatable/equatable.dart';
import 'vendor.dart';
import 'category.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.vendorId,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.isAvailable,
    required this.isFeatured,
    required this.isVegetarian,
    required this.isSpicy,
    required this.additionalImages,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.imageUrl,
    this.availableQuantity,
    this.preparationTimeMinutes,
    this.vendor,
    this.category,
  });

  final String id;
  final String vendorId;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final List<String> additionalImages;
  final int? availableQuantity;
  final int? preparationTimeMinutes;
  final bool isAvailable;
  final bool isFeatured;
  final bool isVegetarian;
  final bool isSpicy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Vendor? vendor;
  final Category? category;

  bool get inStock => availableQuantity == null || (availableQuantity ?? 0) > 0;
  String get vendorName => vendor?.name ?? 'مطبخ ست الكل';

  Product copyWith({
    String? id,
    String? vendorId,
    String? categoryId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    List<String>? additionalImages,
    int? availableQuantity,
    int? preparationTimeMinutes,
    bool? isAvailable,
    bool? isFeatured,
    bool? isVegetarian,
    bool? isSpicy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Vendor? vendor,
    Category? category,
  }) {
    return Product(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      preparationTimeMinutes:
          preparationTimeMinutes ?? this.preparationTimeMinutes,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isSpicy: isSpicy ?? this.isSpicy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      vendor: vendor ?? this.vendor,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        categoryId,
        name,
        description,
        price,
        imageUrl,
        additionalImages,
        availableQuantity,
        preparationTimeMinutes,
        isAvailable,
        isFeatured,
        isVegetarian,
        isSpicy,
        createdAt,
        updatedAt,
        vendor,
        category,
      ];
}
