import 'package:equatable/equatable.dart';
import 'product.dart';

class OrderItem extends Equatable {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productNameSnapshot,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.product,
  });

  final String id;
  final String orderId;
  final String productId;
  /// Snapshot of the product name at time of order to preserve history.
  final String productNameSnapshot;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  /// Populated only when joined with the products table.
  final Product? product;

  OrderItem copyWith({
    String? id, String? orderId, String? productId,
    String? productNameSnapshot, int? quantity,
    double? unitPrice, double? subtotal, Product? product,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
      product: product ?? this.product,
    );
  }

  @override
  List<Object?> get props => [
        id, orderId, productId, productNameSnapshot,
        quantity, unitPrice, subtotal, product,
      ];
}