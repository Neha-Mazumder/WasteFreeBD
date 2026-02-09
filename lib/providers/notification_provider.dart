import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wastefreebd/models/notification_model.dart';
import 'package:wastefreebd/common/services/supabase_service.dart';

class NotificationProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final SupabaseClient _client = Supabase.instance.client;

  List<NotificationModel> _notifications = [];
  int _pendingCount = 0;
  RealtimeChannel? _notificationsChannel;
  bool _isListening = false;

  List<NotificationModel> get notifications => _notifications;
  int get pendingCount => _pendingCount;

  // Initialize real-time listener
  Future<void> initializeNotificationListener() async {
    if (_isListening) return;

    try {
      // Load initial notifications
      await _loadNotifications();

      // Set up real-time subscription
      _notificationsChannel = _client.channel('public:notifications');

      _notificationsChannel
          ?.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              _handleNotificationChange(payload);
            },
          )
          .subscribe();

      _isListening = true;
      print('✓ Notifications real-time listener initialized');
    } catch (e) {
      print('Error initializing notification listener: $e');
    }
  }

  void _handleNotificationChange(PostgresChangePayload payload) {
    final eventType = payload.eventType.toString().split('.').last;
    final newData = payload.newRecord;

    if (eventType == 'insert') {
      final notification = NotificationModel.fromJson(newData);
      _notifications.insert(0, notification);
      _pendingCount++;
    } else if (eventType == 'update') {
      final updatedNotification = NotificationModel.fromJson(newData);
      final index =
          _notifications.indexWhere((n) => n.id == updatedNotification.id);
      if (index != -1) {
        if (_notifications[index].status == 'pending' &&
            updatedNotification.status == 'completed') {
          _pendingCount--;
        }
        _notifications[index] = updatedNotification;
      }
    } else if (eventType == 'delete') {
      final deletedId = newData['id'] as String;
      _notifications.removeWhere((n) => n.id == deletedId);
      _pendingCount = (_pendingCount - 1).clamp(0, double.infinity).toInt();
    }

    notifyListeners();
  }

  Future<void> _loadNotifications() async {
    try {
      final response = await _supabaseService.getNotifications();
      _notifications =
          response.map((json) => NotificationModel.fromJson(json)).toList();
      _pendingCount = _notifications.where((n) => n.status == 'pending').length;
      notifyListeners();
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> createNotification({
    required String title,
    required String type,
  }) async {
    try {
      await _supabaseService.createNotification(
        title: title,
        type: type,
      );
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  Future<void> completeNotification({
    required String notificationId,
  }) async {
    try {
      // Update notification status to completed
      await _supabaseService.completeNotification(
        notificationId: notificationId,
      );

      // Update dashboard stats
      final stats = await _supabaseService.getDashboardStats();
      await _supabaseService.updateDashboardStats(
        pickupsToday: (stats['pickups_today'] as num?)?.toInt() ?? 0 + 1,
        activeTrucks: (stats['active_trucks'] as num?)?.toInt() ?? 0 + 1,
        totalTrucks: (stats['total_trucks'] as num?)?.toInt() ?? 0,
        pendingIssues: ((stats['pending_issues'] as num?)?.toInt() ?? 1) - 1,
        totalProfit: (stats['total_profit'] as num?)?.toDouble() ?? 0,
      );
    } catch (e) {
      print('Error completing notification: $e');
      rethrow;
    }
  }

  Future<void> refreshNotifications() async {
    await _loadNotifications();
  }

  @override
  void dispose() {
    _notificationsChannel?.unsubscribe();
    _isListening = false;
    super.dispose();
  }
}
