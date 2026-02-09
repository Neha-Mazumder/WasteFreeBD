import 'package:flutter/foundation.dart';
import 'package:wastefreebd/common/services/supabase_service.dart';

class PaymentStore {
  // ValueNotifier so UI can listen for updates
  static final ValueNotifier<List<Map<String, dynamic>>> payments =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static final SupabaseService _supabaseService = SupabaseService();

  static Future<void> addPayment(
      {required String method,
      required String phone,
      required int amount}) async {
    final entry = {
      'method': method,
      'phone': phone,
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    };
    // Prepend new entry
    payments.value = [entry, ...payments.value];

    // Add to Supabase (will trigger financial_records update via trigger)
    try {
      await _supabaseService.recordPayment(
        amount: amount.toDouble(),
        description: 'Payment via $method from $phone',
      );
    } catch (e) {
      print('Error saving payment to Supabase: $e');
      // Still keep in local store even if Supabase fails
    }
  }
}
