import 'package:equatable/equatable.dart';

/// Domain entity for a vendor/seller.
class Vendor extends Equatable {
  const Vendor({
    required this.id,
    required this.name, // Maps to business_name in DB
    required this.isActive,
    required this.offersDelivery, // Maps to delivery_available
    required this.offersPickup, // Maps to pickup_available
    required this.createdAt,
    this.logoUrl, // Maps to cover_image
    this.description, // Maps to bio
    this.governorate,
    this.area,
    this.rating,
    this.totalReviews,
    this.deliveryFee,
    this.minOrder, // Maps to min_order_amount
    this.deliveryRadiusKm,
    this.avgPrepTimeMinutes,
    this.latitude,
    this.longitude,
    this.isVerified,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String? description;
  final String? governorate;
  final String? area;
  final double? rating;
  final int? totalReviews;
  final bool isActive;
  final bool offersDelivery;
  final bool offersPickup;
  final double? deliveryFee;
  final double? minOrder;
  final double? deliveryRadiusKm;
  final int? avgPrepTimeMinutes;
  final double? latitude;
  final double? longitude;
  final bool? isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Vendor copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? description,
    String? governorate,
    String? area,
    double? rating,
    int? totalReviews,
    bool? isActive,
    bool? offersDelivery,
    bool? offersPickup,
    double? deliveryFee,
    double? minOrder,
    double? deliveryRadiusKm,
    int? avgPrepTimeMinutes,
    double? latitude,
    double? longitude,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vendor(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
      governorate: governorate ?? this.governorate,
      area: area ?? this.area,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isActive: isActive ?? this.isActive,
      offersDelivery: offersDelivery ?? this.offersDelivery,
      offersPickup: offersPickup ?? this.offersPickup,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minOrder: minOrder ?? this.minOrder,
      deliveryRadiusKm: deliveryRadiusKm ?? this.deliveryRadiusKm,
      avgPrepTimeMinutes: avgPrepTimeMinutes ?? this.avgPrepTimeMinutes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        logoUrl,
        description,
        governorate,
        area,
        rating,
        totalReviews,
        isActive,
        offersDelivery,
        offersPickup,
        deliveryFee,
        minOrder,
        deliveryRadiusKm,
        avgPrepTimeMinutes,
        latitude,
        longitude,
        isVerified,
        createdAt,
        updatedAt,
      ];
}
