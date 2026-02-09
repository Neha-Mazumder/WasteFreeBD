# Real-Time Notifications - Quick Code Snippets

Copy and paste these snippets directly into your code for quick integration.

---

## 1. Main App Initialization

**Location:** `lib/main.dart`

```dart
import 'package:provider/provider.dart';
import 'package:wastefreebd/providers/notification_provider.dart';

void main() async {
  // ... existing code ...
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Add this:
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
        ),
        // ... other providers ...
      ],
      child: MaterialApp(
        // ... your app config ...
      ),
    );
  }
}
```

---

## 2. User Home Screen - Request Pickup Button

**Location:** `lib/user/screens/home_screen.dart`

```dart
import 'package:wastefreebd/services/notification_service.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;

  void _requestPickup() async {
    if (_currentLocation == null) {
      _showError('Please enable location');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _notificationService.sendPickupRequestNotification(
        userId: supabase.auth.currentUser?.id ?? 'unknown',
        location: _currentLocation!,
        additionalInfo: 'Standard waste collection',
      );

      if (mounted) {
        _showSuccess('✓ Pickup request sent to admin!');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to send request: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF13EC5B),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Pickup'),
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _requestPickup,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.local_shipping),
          label: Text(_isLoading ? 'Sending...' : 'Request Pickup Now'),
        ),
      ),
    );
  }
}
```

---

## 3. IoT/Alert Screen - Report Dustbin Full

**Location:** `lib/user/screens/alert_screen.dart`

```dart
import 'package:wastefreebd/services/notification_service.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;

  void _reportDustbinFull(String dustbinId, String location) async {
    setState(() => _isLoading = true);

    try {
      await _notificationService.sendDustbinFullAlert(
        dustbinId: dustbinId,
        location: location,
        fillPercentage: 95.0, // From IoT sensor
      );

      if (mounted) {
        _showSuccess('✓ Dustbin full alert sent!');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to send alert: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Alert'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _reportDustbinFull('db_001', 'Gulshan'),
              icon: const Icon(Icons.warning),
              label: Text(_isLoading ? 'Sending...' : 'Dustbin Full Alert'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 4. Admin Dashboard Update

**Location:** `lib/admin/screens/admin_dashboard_screen.dart`

Already integrated in the file! Key parts:

```dart
import 'package:provider/provider.dart';
import 'package:wastefreebd/providers/notification_provider.dart';
import 'package:wastefreebd/admin/widgets/notification_card.dart';

// In initState:
@override
void initState() {
  super.initState();
  _loadData();
  // Initialize notification listener
  Future.delayed(const Duration(milliseconds: 500), () {
    if (mounted) {
      Provider.of<NotificationProvider>(context, listen: false)
          .initializeNotificationListener();
    }
  });
}

// In build, add notification panel:
Consumer<NotificationProvider>(
  builder: (context, notificationProvider, child) {
    final pendingNotifications = notificationProvider.notifications
        .where((n) => n.status == 'pending')
        .toList();

    if (pendingNotifications.isNotEmpty) {
      return Column(
        children: [
          // Display notifications...
          ...pendingNotifications.map((notification) {
            return NotificationCard(
              notification: notification,
              onComplete: () async {
                await notificationProvider.completeNotification(
                  notificationId: notification.id,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Pickup completed successfully'),
                      backgroundColor: Color(0xFF13EC5B),
                    ),
                  );
                }
              },
            );
          }).toList(),
        ],
      );
    }
    return const SizedBox.shrink();
  },
)
```

---

## 5. Widget Test for Notifications

**Location:** `test/notification_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wastefreebd/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('Can create notification from JSON', () {
      final json = {
        'id': 'test-123',
        'title': 'Test Pickup',
        'type': 'pickup_request',
        'status': 'pending',
        'created_at': '2024-01-20T10:00:00Z',
      };

      final notification = NotificationModel.fromJson(json);

      expect(notification.id, 'test-123');
      expect(notification.title, 'Test Pickup');
      expect(notification.type, 'pickup_request');
      expect(notification.status, 'pending');
    });

    test('Can convert notification to JSON', () {
      final notification = NotificationModel(
        id: 'test-123',
        title: 'Test Pickup',
        type: 'pickup_request',
        status: 'pending',
      );

      final json = notification.toJson();

      expect(json['id'], 'test-123');
      expect(json['title'], 'Test Pickup');
      expect(json['type'], 'pickup_request');
      expect(json['status'], 'pending');
    });

    test('Can copy with updates', () {
      final notification = NotificationModel(
        title: 'Test',
        type: 'pickup_request',
        status: 'pending',
      );

      final updated = notification.copyWith(status: 'completed');

      expect(updated.status, 'completed');
      expect(updated.title, 'Test'); // Other fields unchanged
    });
  });
}
```

---

## 6. Service Integration Test

**Location:** `test/notification_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wastefreebd/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService();
    });

    test('sendPickupRequestNotification creates notification', () async {
      expect(
        () => service.sendPickupRequestNotification(
          userId: 'user123',
          location: 'Test Location',
          additionalInfo: 'Test Info',
        ),
        completes,
      );
    });

    test('sendDustbinFullAlert creates notification', () async {
      expect(
        () => service.sendDustbinFullAlert(
          dustbinId: 'db_001',
          location: 'Test Location',
          fillPercentage: 95.0,
        ),
        completes,
      );
    });
  });
}
```

---

## 7. Direct Database Testing

**Location:** SQL to run directly in Supabase

```sql
-- Test 1: Insert single notification
INSERT INTO public.notifications (title, type, status)
VALUES ('Test pickup request', 'pickup_request', 'pending')
RETURNING *;

-- Test 2: Insert dustbin alert
INSERT INTO public.notifications (title, type, status)
VALUES ('Dustbin full at location XYZ', 'dustbin_full', 'pending')
RETURNING *;

-- Test 3: View all pending
SELECT * FROM public.notifications
WHERE status = 'pending'
ORDER BY created_at DESC;

-- Test 4: Complete a notification
UPDATE public.notifications
SET status = 'completed'
WHERE id = '...' -- Replace with actual ID
RETURNING *;

-- Test 5: View statistics
SELECT * FROM public.notification_stats;

-- Test 6: View audit log
SELECT * FROM public.notification_audit_log
ORDER BY changed_at DESC;

-- Test 7: Bulk insert for stress testing
INSERT INTO public.notifications (title, type, status)
SELECT
  'Test notification ' || i,
  CASE WHEN i % 2 = 0 THEN 'pickup_request' ELSE 'dustbin_full' END,
  'pending'
FROM generate_series(1, 100) AS t(i)
RETURNING COUNT(*);

-- Test 8: Delete old notifications (older than 30 days)
DELETE FROM public.notifications
WHERE created_at < NOW() - INTERVAL '30 days';

-- Test 9: Count by type
SELECT type, COUNT(*) as count
FROM public.notifications
GROUP BY type;

-- Test 10: Recent activity
SELECT title, type, status, created_at
FROM public.notifications
ORDER BY created_at DESC
LIMIT 10;
```

---

## 8. Error Handling Pattern

```dart
// Pattern for all notification operations
void _safeNotificationOperation(Future Function() operation) async {
  try {
    setState(() => _isLoading = true);
    await operation();
    if (mounted) {
      _showSuccess('Operation completed successfully');
    }
  } on FormatException catch (e) {
    if (mounted) {
      _showError('Invalid format: ${e.message}');
    }
  } on TimeoutException catch (e) {
    if (mounted) {
      _showError('Request timed out. Please try again.');
    }
  } on Exception catch (e) {
    if (mounted) {
      _showError('Error: ${e.toString()}');
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

// Usage:
void _requestPickup() {
  _safeNotificationOperation(() => 
    _notificationService.sendPickupRequestNotification(
      userId: userId,
      location: location,
    )
  );
}
```

---

## 9. Provider Integration Pattern

```dart
// In any Consumer widget:
Consumer<NotificationProvider>(
  builder: (context, notificationProvider, child) {
    // Access state
    final notifications = notificationProvider.notifications;
    final pendingCount = notificationProvider.pendingCount;

    // Call methods
    return Column(
      children: [
        Text('Pending: ${pendingCount}'),
        ...notifications.map((notification) {
          return ListTile(
            title: Text(notification.title),
            subtitle: Text(notification.type),
            trailing: IconButton(
              icon: const Icon(Icons.done),
              onPressed: () => notificationProvider
                  .completeNotification(
                    notificationId: notification.id,
                  ),
            ),
          );
        }).toList(),
      ],
    );
  },
)
```

---

## 10. Real-Time Listener Debug

```dart
// Add to NotificationProvider for debugging
void _handleNotificationChange(dynamic payload) {
  print('🔔 Notification Change Received:');
  print('  Event Type: ${payload['eventType']}');
  print('  Data: ${payload['new']}');
  
  final eventType = payload['eventType'] as String;
  final newData = payload['new'] as Map<String, dynamic>;

  if (eventType == 'INSERT') {
    print('  ✅ New notification inserted');
    final notification = NotificationModel.fromJson(newData);
    _notifications.insert(0, notification);
    _pendingCount++;
  } else if (eventType == 'UPDATE') {
    print('  ✏️ Notification updated');
    // ... update logic
  } else if (eventType == 'DELETE') {
    print('  ❌ Notification deleted');
    // ... delete logic
  }

  print('  Total pending: ${_pendingCount}');
  notifyListeners();
}
```

---

## 11. Performance Monitoring

```dart
// Monitor notification insert performance
Future<void> _monitorPerformance() async {
  final stopwatch = Stopwatch()..start();
  
  try {
    await notificationService.sendPickupRequestNotification(
      userId: 'test',
      location: 'test',
    );
    
    print('⏱️ Insert Time: ${stopwatch.elapsedMilliseconds}ms');
    
    if (stopwatch.elapsedMilliseconds > 1000) {
      print('⚠️ Slow insert detected');
    }
  } finally {
    stopwatch.stop();
  }
}

// Monitor real-time subscription latency
Future<void> _monitorLatency() async {
  final testNotification = {
    'title': 'Latency test at ${DateTime.now()}',
    'type': 'test',
    'status': 'pending',
  };
  
  final insertTime = DateTime.now();
  
  // Listen for update
  notificationProvider.addListener(() {
    if (notificationProvider.notifications.any(
      (n) => n.title.contains('Latency test'),
    )) {
      final latency = DateTime.now().difference(insertTime);
      print('📡 Real-time Latency: ${latency.inMilliseconds}ms');
    }
  });
  
  await supabase.from('notifications').insert(testNotification);
}
```

---

These snippets provide everything needed to integrate the real-time notification system into your app!
