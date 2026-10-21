import 'package:equatable/equatable.dart';

/// Domain entity for a food category.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.sortOrder,
    this.iconUrl,
    this.isActive = true,
  });

  final String id;
  final String name; // Arabic name
  final String nameEn; // English name
  final String? iconUrl;
  final int sortOrder;
  final bool isActive;

  Category copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? iconUrl,
    int? sortOrder,
    bool? isActive,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      iconUrl: iconUrl ?? this.iconUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, name, nameEn, iconUrl, sortOrder, isActive];
}
