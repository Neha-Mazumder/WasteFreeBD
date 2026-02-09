import 'package:flutter/foundation.dart';

/// PaymentStore manages payment history and transaction data
class PaymentStore {
  static final ValueNotifier<List<Map<String, dynamic>>> payments =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  /// Add a new payment to the store
  static void addPayment({
    required String method,
    required String phone,
    required double amount,
  }) {
    final payment = {
      'method': method,
      'phone': phone,
      'amount': amount,
      'timestamp': DateTime.now(),
      'status': 'completed',
    };

    payments.value = [...payments.value, payment];
  }

  /// Get all payments
  static List<Map<String, dynamic>> getAllPayments() {
    return payments.value;
  }

  /// Clear payment history
  static void clearPayments() {
    payments.value = [];
  }

  /// Get total amount paid
  static double getTotalAmount() {
    double total = 0.0;
    for (var payment in payments.value) {
      total += (payment['amount'] as num).toDouble();
    }
    return total;
  }

  /// Get payment count
  static int getPaymentCount() {
    return payments.value.length;
  }
}
