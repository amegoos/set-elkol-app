import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/supabase_client.dart';

enum PaymentGatewayType {
  card,
  cash,
  instapay,
  vodafoneCash,
}

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? paymentStatus;
  final String? errorMessage;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.paymentStatus,
    this.errorMessage,
  });
}

class PaymentService {
  final SupabaseClient _client;

  PaymentService(this._client);

  /// Process payment for order via gateway or local mobile wallet confirmation
  Future<PaymentResult> processOrderPayment({
    required String orderId,
    required double amount,
    required PaymentGatewayType gateway,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return PaymentResult(success: false, errorMessage: 'المستخدم غير مسجل الدخول');
      }

      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';

      String status = 'pending';
      if (gateway == PaymentGatewayType.cash) {
        status = 'pending'; // Paid upon delivery
      } else if (gateway == PaymentGatewayType.card) {
        // Online Card payment sandbox integration
        status = 'paid';
      } else if (gateway == PaymentGatewayType.instapay || gateway == PaymentGatewayType.vodafoneCash) {
        status = 'pending'; // Pending verification of reference number
      }

      // Store payment record in Supabase `payment_transactions` table
      await _client.from('payment_transactions').insert({
        'order_id': orderId,
        'user_id': user.id,
        'amount': amount,
        'gateway': gateway.name,
        'transaction_id': transactionId,
        'status': status,
        'payload': {
          'gateway_type': gateway.name,
          'details': paymentDetails ?? {},
          'processed_at': DateTime.now().toIso8601String(),
        },
      });

      // Update payment_status on the order table
      await _client.from('orders').update({
        'payment_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      return PaymentResult(
        success: true,
        transactionId: transactionId,
        paymentStatus: status,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'فشل إتمام العملية المالية: $e',
      );
    }
  }
}

final paymentServiceProvider = Provider<PaymentService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PaymentService(client);
});
