class OrderModel {
  OrderModel({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    required this.createdAt,
    this.vendorName,
    this.deliveryAddress,
    this.items = const [],
  });

  final String id;
  String status;
  final double totalAmount;
  final String paymentMethod;
  final DateTime createdAt;
  final String? vendorName;
  final String? deliveryAddress;
  final List<Map<String, dynamic>> items;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String? ?? '',
      status: json['order_status'] as String? ?? json['status'] as String? ?? 'pending',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      vendorName: (json['vendors'] as Map<String, dynamic>?)?['name'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      items: (json['order_items'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_status': status,
      'status': status,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'delivery_address': deliveryAddress,
      'order_items': items,
    };
  }
}
