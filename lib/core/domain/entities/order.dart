import 'package:equatable/equatable.dart';
import 'order_item.dart';
import 'vendor.dart';
import 'user_profile.dart';
import 'address.dart';

enum OrderStatus {
  pending,
  accepted,
  preparing,
  ready,
  outForDelivery,
  completed,
  cancelled,
}

enum PaymentMethod { cash, instapay, vodafoneCash }

enum PaymentStatus { pending, verified, rejected }

enum FulfillmentType { delivery, pickup }

class Order extends Equatable {
  const Order({
    required this.id,
    required this.customerId,
    required this.vendorId,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.fulfillmentType,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.createdAt,
    required this.updatedAt,
    this.deliveryAddressId,
    this.customerNote,
    this.cancellationReason,
    this.items,
    this.vendor,
    this.customer,
    this.deliveryAddress,
  });

  final String id;
  final String customerId;
  final String vendorId;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final FulfillmentType fulfillmentType;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final OrderStatus orderStatus;
  final String? deliveryAddressId;
  final String? customerNote;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Populated when the query joins order_items.
  final List<OrderItem>? items;
  /// Populated when the query joins vendors.
  final Vendor? vendor;
  /// Populated when the query joins profiles.
  final UserProfile? customer;
  /// Populated when the query joins addresses.
  final Address? deliveryAddress;

  bool get isCancellable =>
      orderStatus == OrderStatus.pending || orderStatus == OrderStatus.accepted;

  bool get isActive =>
      orderStatus != OrderStatus.completed &&
      orderStatus != OrderStatus.cancelled;

  Order copyWith({
    String? id, String? customerId, String? vendorId,
    double? subtotal, double? deliveryFee, double? totalAmount,
    FulfillmentType? fulfillmentType, PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus, OrderStatus? orderStatus,
    String? deliveryAddressId, String? customerNote,
    String? cancellationReason, DateTime? createdAt, DateTime? updatedAt,
    List<OrderItem>? items, Vendor? vendor,
    UserProfile? customer, Address? deliveryAddress,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      vendorId: vendorId ?? this.vendorId,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      totalAmount: totalAmount ?? this.totalAmount,
      fulfillmentType: fulfillmentType ?? this.fulfillmentType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      deliveryAddressId: deliveryAddressId ?? this.deliveryAddressId,
      customerNote: customerNote ?? this.customerNote,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      vendor: vendor ?? this.vendor,
      customer: customer ?? this.customer,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    );
  }

  @override
  List<Object?> get props => [
        id, customerId, vendorId, subtotal, deliveryFee, totalAmount,
        fulfillmentType, paymentMethod, paymentStatus, orderStatus,
        deliveryAddressId, customerNote, cancellationReason,
        createdAt, updatedAt, items, vendor, customer, deliveryAddress,
      ];
}