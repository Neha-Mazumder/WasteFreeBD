import 'package:wastefreebd/common/services/supabase_service.dart';

class NotificationService {
  final SupabaseService _supabaseService = SupabaseService();

  /// Send a pickup request notification
  /// This would be called when a user requests a pickup
  Future<void> sendPickupRequestNotification({
    required String userId,
    required String location,
    String? additionalInfo,
  }) async {
    try {
      final title =
          'New Pickup Request from $location${additionalInfo != null ? ' - $additionalInfo' : ''}';

      await _supabaseService.createNotification(
        title: title,
        type: 'pickup_request',
      );

      print('✓ Pickup request notification sent');
    } catch (e) {
      print('Error sending pickup request notification: $e');
      rethrow;
    }
  }

  /// Send a dustbin full alert notification
  /// This would be called when IoT sensors detect dustbin is full
  Future<void> sendDustbinFullAlert({
    required String dustbinId,
    required String location,
    required double fillPercentage,
  }) async {
    try {
      final title =
          'Dustbin Full Alert at $location (${fillPercentage.toStringAsFixed(0)}% full)';

      await _supabaseService.createNotification(
        title: title,
        type: 'dustbin_full',
      );

      print('✓ Dustbin full alert notification sent');
    } catch (e) {
      print('Error sending dustbin full alert: $e');
      rethrow;
    }
  }

  /// Send a generic notification
  Future<void> sendNotification({
    required String title,
    required String type,
  }) async {
    try {
      await _supabaseService.createNotification(
        title: title,
        type: type,
      );

      print('✓ Notification sent: $title');
    } catch (e) {
      print('Error sending notification: $e');
      rethrow;
    }
  }
}
