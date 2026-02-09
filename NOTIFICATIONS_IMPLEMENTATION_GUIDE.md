# Real-Time Notifications System Implementation Guide

## Overview
This guide explains how to use the real-time notifications system in WasteFreeBD to send pickup requests and dustbin full alerts from users to the admin dashboard.

## System Architecture

### Database Layer
- **Table**: `public.notifications`
- **Columns**: id (UUID), title, type, status, created_at, updated_at
- **Trigger**: `notifications_broadcast_trigger` - Broadcasts all changes via Supabase Realtime
- **RLS Policies**: Public read/write access enabled

### Flutter Layer
- **Model**: `NotificationModel` - Represents a notification
- **Provider**: `NotificationProvider` - Manages real-time notification stream
- **Service**: `NotificationService` - Helper methods to send notifications
- **UI Widget**: `NotificationCard` - Displays individual notifications

### Admin Dashboard
- Real-time notification listener initialized on dashboard load
- Notifications appear instantly in a dedicated panel at the top
- "Mark Complete" button updates status and dashboard stats
- Pending count displayed in the "Pending Issues" stat card

---

## Usage Examples

### 1. Send a Pickup Request Notification (User Side)

```dart
import 'package:wastefreebd/services/notification_service.dart';

final notificationService = NotificationService();

// When user requests a pickup
await notificationService.sendPickupRequestNotification(
  userId: 'user123',
  location: 'Dhanmondi, Dhaka',
  additionalInfo: 'Heavy trash pile, needs immediate pickup',
);
```

### 2. Send a Dustbin Full Alert (IoT/Sensor Side)

```dart
import 'package:wastefreebd/services/notification_service.dart';

final notificationService = NotificationService();

// When IoT sensor detects dustbin is full
await notificationService.sendDustbinFullAlert(
  dustbinId: 'db_001',
  location: 'Gulshan Circle, Dhaka',
  fillPercentage: 95.5,
);
```

### 3. Send Generic Notification

```dart
import 'package:wastefreebd/services/notification_service.dart';

final notificationService = NotificationService();

// Generic notification
await notificationService.sendNotification(
  title: 'Custom notification message',
  type: 'other',
);
```

---

## Integration Steps

### Step 1: Setup Database (Already Done)
Execute the SQL from `NOTIFICATIONS_SETUP.sql` in your Supabase SQL editor:
- Creates `notifications` table
- Creates broadcast function
- Sets up real-time triggers
- Enables Row Level Security

### Step 2: Add Dependencies (Already Done)
```yaml
dependencies:
  uuid: ^4.0.0  # For generating unique IDs
```

### Step 3: Initialize Notification Listener in Admin Dashboard (Already Done)
```dart
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
```

### Step 4: Use in Your Screens

#### In User/Home Screen (Send Pickup Request)
```dart
import 'package:wastefreebd/services/notification_service.dart';

class HomeScreen extends StatelessWidget {
  final notificationService = NotificationService();

  void _requestPickup() async {
    try {
      await notificationService.sendPickupRequestNotification(
        userId: currentUserId,
        location: 'My Address',
        additionalInfo: 'Need waste collection',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Pickup request sent to admin')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _requestPickup,
      child: const Text('Request Pickup'),
    );
  }
}
```

#### In Alert Screen (Send Dustbin Alert)
```dart
import 'package:wastefreebd/services/notification_service.dart';

class AlertScreen extends StatelessWidget {
  final notificationService = NotificationService();

  void _reportDustbinFull() async {
    try {
      await notificationService.sendDustbinFullAlert(
        dustbinId: 'db_location_001',
        location: 'Near Market Area',
        fillPercentage: 98.0,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Dustbin full alert sent')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _reportDustbinFull,
      child: const Text('Report Dustbin Full'),
    );
  }
}
```

---

## Admin Dashboard Behavior

### What Happens When:

#### 1. User Sends Pickup Request
```
Timeline:
T0: User clicks "Request Pickup" → Notification inserted into DB
T1: Database trigger fires → Broadcast function sends real-time event
T2: Admin's NotificationProvider receives update (< 100ms)
T3: UI updates instantly:
    - New notification card appears with pickup icon
    - Pending Issues card increases by +1
    - Pending requests count displays in header
```

#### 2. Admin Clicks "Mark Complete"
```
Timeline:
T0: Admin clicks "Mark Complete" button on notification card
T1: completeNotification() called:
    - Update notification.status = 'completed'
    - Update dashboard_stats:
      ✓ pending_issues -1
      ✓ pickups_today +1
      ✓ active_trucks +1
T2: Database triggers fire → Real-time broadcasts
T3: Admin dashboard updates:
    - Notification card disappears
    - Pending Issues card decreases by -1
    - Pickups Today increases by +1
    - Active Trucks increases by +1
T4: Success snackbar shows: "✓ Pickup completed successfully"
```

---

## Real-Time Data Flow

```
User App                          Database                    Admin App
    │                                 │                            │
    │─ Send Notification ────────→ notifications table             │
    │                                 │                            │
    │                           ┌─ Trigger fires                   │
    │                           │  Broadcast changes               │
    │                           └─────────────────────────────→ Real-time listener
    │                                 │                            │
    │                                 │                      ┌─ NotificationProvider
    │                                 │                      │  updates notifications
    │                                 │                      └─ UI refreshes
    │                                 │                            │
    │   ← ← ← ← ← ← Admin clicks Complete ← ← ← ← ← ← ← ← ← ← ← │
    │                                 │                            │
    │                           ┌─ Update status                   │
    │                           │  Update dashboard_stats          │
    │                           └─ Trigger fires                   │
    │                                 │                            │
    │                           ┌─ Broadcast changes               │
    │                           └─────────────────────────────→ Updates UI
```

---

## File Structure

```
lib/
├── models/
│   └── notification_model.dart          # Notification data model
├── providers/
│   └── notification_provider.dart       # Real-time notification provider
├── services/
│   └── notification_service.dart        # Service to send notifications
├── admin/
│   ├── screens/
│   │   └── admin_dashboard_screen.dart  # Updated to show notifications
│   └── widgets/
│       └── notification_card.dart       # Notification UI components
└── supabase_client.dart                 # Supabase initialization

Root files:
├── NOTIFICATIONS_SETUP.sql              # Database setup script
└── pubspec.yaml                         # Updated with uuid dependency
```

---

## Testing the System

### Test 1: Manual Notification Creation
1. Go to your Supabase dashboard
2. Navigate to SQL Editor
3. Run:
```sql
INSERT INTO public.notifications (title, type, status)
VALUES ('Test pickup from Dhanmondi', 'pickup_request', 'pending');
```
4. Watch the admin dashboard - notification should appear instantly

### Test 2: Complete a Notification
1. In the admin app, click "Mark Complete" on any notification
2. Observe:
   - Notification card disappears
   - Pending Issues decreases by 1
   - Pickups Today increases by 1

### Test 3: Multiple Notifications
1. Send multiple notifications from different users
2. Verify all appear in the admin dashboard
3. Complete them in any order

---

## Performance Considerations

1. **Real-Time Subscription**: Uses Supabase PostGres Changes - very efficient
2. **Queries**: Indexed on status and created_at for fast filtering
3. **UI Updates**: Consumer widget only rebuilds when needed
4. **Database Triggers**: Minimal overhead, only logs and broadcasts

---

## Security & Permissions

All RLS policies are set to allow public access for development. **For production**, consider:

```sql
-- Production: Restrict to authenticated users
ALTER POLICY "Allow public read notifications" ON public.notifications
  USING (auth.role() = 'authenticated');

ALTER POLICY "Allow public insert notifications" ON public.notifications
  WITH CHECK (
    auth.role() = 'authenticated' 
    AND auth.uid()::text = user_id
  );
```

---

## Troubleshooting

### Notifications not appearing on admin dashboard?
1. Check Supabase dashboard > Realtime > Check if "notifications" table is enabled
2. Verify RLS policies are correctly set
3. Check NotificationProvider is initialized: `Provider.of<NotificationProvider>(context, listen: false).initializeNotificationListener();`

### Duplicate notifications?
1. Check if notifications are being inserted multiple times
2. Verify network connectivity
3. Check browser console for errors

### "Mark Complete" not working?
1. Verify `dashboard_stats` table exists and has data
2. Check Supabase logs for permission errors
3. Ensure user_id is correctly passed to completeNotification()

---

## Next Steps

1. ✅ Execute NOTIFICATIONS_SETUP.sql in Supabase
2. ✅ Run `flutter pub get` to install dependencies
3. ✅ Integrate NotificationService into user screens
4. ✅ Test with manual SQL inserts
5. ✅ Monitor real-time updates on admin dashboard
