import 'package:equatable/equatable.dart';

enum UserRole { customer, vendor, admin }

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.email,
    this.profileImage,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? profileImage;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCustomer => role == UserRole.customer;
  bool get isVendor => role == UserRole.vendor;
  bool get isAdmin => role == UserRole.admin;

  UserProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? profileImage,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        profileImage,
        role,
        createdAt,
        updatedAt,
      ];
}
