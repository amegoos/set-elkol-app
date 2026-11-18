import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/firebase_providers.dart';

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
  final FirebaseDatabase _db;
  final fb_auth.FirebaseAuth _auth;

  PaymentService(this._db, this._auth);

  /// Process payment for order via gateway or local mobile wallet confirmation
  Future<PaymentResult> processOrderPayment({
    required String orderId,
    required double amount,
    required PaymentGatewayType gateway,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return PaymentResult(
            success: false, errorMessage: 'المستخدم غير مسجل الدخول');
      }

      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';

      String status = 'pending';
      if (gateway == PaymentGatewayType.cash) {
        status = 'pending'; // Paid upon delivery
      } else if (gateway == PaymentGatewayType.card) {
        status = 'paid';
      } else if (gateway == PaymentGatewayType.instapay ||
          gateway == PaymentGatewayType.vodafoneCash) {
        status =
            'pending'; // Pending verification of reference number / receipt
      }

      // Store payment record in Firebase RTDB `/payment_transactions/{transactionId}`
      await _db.ref('payment_transactions/$transactionId').set({
        'order_id': orderId,
        'user_id': user.uid,
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

      // Update payment_status on the order
      await _db.ref('orders/$orderId').update({
        'payment_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return PaymentResult(
        success: true,
        transactionId: transactionId,
        paymentStatus: status,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'فشل في تسجيل وتأكيد العملية: $e',
      );
    }
  }
}

final paymentServiceProvider = Provider<PaymentService>((ref) {
  final db = ref.watch(firebaseDatabaseProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return PaymentService(db, auth);
});
