import 'package:equatable/equatable.dart';

class Address extends Equatable {
  const Address({
    required this.id,
    required this.userId,
    required this.label,
    required this.governorate,
    required this.area,
    required this.streetAddress,
    required this.isDefault,
    required this.createdAt,
    this.buildingDetails,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String userId;

  /// Human-readable label such as "المنزل" or "العمل".
  final String label;

  final String governorate;
  final String area;
  final String streetAddress;
  final String? buildingDetails;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;

  /// Short one-line representation for dropdowns and order summaries.
  String get shortDisplay => '$governorate، $area، $streetAddress';

  Address copyWith({
    String? id,
    String? userId,
    String? label,
    String? governorate,
    String? area,
    String? streetAddress,
    String? buildingDetails,
    double? latitude,
    double? longitude,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      governorate: governorate ?? this.governorate,
      area: area ?? this.area,
      streetAddress: streetAddress ?? this.streetAddress,
      buildingDetails: buildingDetails ?? this.buildingDetails,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        label,
        governorate,
        area,
        streetAddress,
        buildingDetails,
        latitude,
        longitude,
        isDefault,
        createdAt,
      ];
}
