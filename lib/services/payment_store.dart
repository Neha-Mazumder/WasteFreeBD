import 'package:flutter/foundation.dart';

class PaymentStore {
  // ValueNotifier so UI can listen for updates
  static final ValueNotifier<List<Map<String, dynamic>>> payments = ValueNotifier<List<Map<String, dynamic>>>([]);

  static void addPayment({required String method, required String phone, required int amount}) {
    final entry = {
      'method': method,
      'phone': phone,
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    };
    // Prepend new entry
    payments.value = [entry, ...payments.value];
  }
}
