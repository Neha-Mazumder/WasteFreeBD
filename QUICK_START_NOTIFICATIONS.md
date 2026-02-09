# Real-Time Notifications - Quick Start Guide

## 🚀 What Was Set Up?

Your WasteFreeBD app now has a complete real-time notification system that:
- ✅ Allows users to send pickup requests & dustbin full alerts
- ✅ Sends instant notifications to admin dashboard (< 100ms)
- ✅ Updates admin stats automatically (pending -1, pickups +1, trucks +1)
- ✅ Persists all notifications in database with audit log

---

## 📋 Quick Setup (3 Steps)

### Step 1: Execute Database Setup SQL
1. Go to: https://supabase.com/dashboard/project/bqsptmtajnovcbvxpxyf/editor/21137?schema=public
2. Open the **SQL Editor** tab
3. Copy and paste the entire content of: **`NOTIFICATIONS_SETUP.sql`**
4. Click **"Run"** button
5. Wait for success message ✓

### Step 2: Update Flutter Dependencies
```bash
cd wastefreebd
flutter pub get
```

### Step 3: Initialize in Your App
Make sure NotificationProvider is wrapped in your app's provider setup:

```dart
// In your main.dart or app setup
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => NotificationProvider()),
    // ... other providers
  ],
  child: MyApp(),
)
```

---

## 🎯 How to Use

### From User Side - Send Pickup Request
```dart
import 'package:wastefreebd/services/notification_service.dart';

final notificationService = NotificationService();

await notificationService.sendPickupRequestNotification(
  userId: 'user123',
  location: 'Dhanmondi, Dhaka',
  additionalInfo: 'Heavy trash pile',
);
```

### From User Side - Report Dustbin Full
```dart
await notificationService.sendDustbinFullAlert(
  dustbinId: 'db_001',
  location: 'Gulshan Circle',
  fillPercentage: 95.0,
);
```

### From Admin Side - Complete Notification
The admin dashboard already has this integrated. Just click "Mark Complete" on any notification card.

---

## 📊 What Happens Automatically?

### Timeline for User Sending Pickup Request:

```
T0: User clicks "Request Pickup"
    ↓
T1: Notification inserted into database
    ↓
T2: Database trigger fires → broadcasts real-time event
    ↓
T3: Admin's phone receives update (< 100ms)
    ↓
T4: Notification card appears with icon & title
    ↓
T5: Pending Issues card shows +1
    ↓
T6: Admin clicks "Mark Complete"
    ↓
T7: Notification status = "completed"
    Dashboard stats updated:
    - pending_issues -1
    - pickups_today +1
    - active_trucks +1
```

---

## 📁 New Files Created

```
lib/
├── models/
│   └── notification_model.dart ..................... Notification data class
├── providers/
│   └── notification_provider.dart ................. Real-time listener & state
├── services/
│   └── notification_service.dart .................. Send notifications helper
├── admin/
│   └── widgets/
│       └── notification_card.dart ................ UI for notifications
├── user/
│   └── screens/
│       └── pickup_request_example_screen.dart .... Example user screen

Root:
├── NOTIFICATIONS_SETUP.sql ...................... Database setup script
├── NOTIFICATIONS_IMPLEMENTATION_GUIDE.md ....... Detailed guide
└── QUICK_START_NOTIFICATIONS.md ................ This file
```

---

## 🧪 Test It Out

### Test 1: Manual Insert (No App Needed)
1. Open Supabase dashboard
2. Go to SQL Editor
3. Run:
```sql
INSERT INTO public.notifications (title, type, status)
VALUES ('Test pickup request', 'pickup_request', 'pending');
```
4. Watch admin dashboard → notification appears instantly ✓

### Test 2: From Your App
1. Integrate the example screen: `pickup_request_example_screen.dart`
2. Navigate to that screen in your app
3. Fill location and click "Send Pickup Request"
4. Go to admin dashboard
5. Notification appears instantly ✓
6. Click "Mark Complete"
7. Verify stats update ✓

---

## 🔄 Real-Time Flow Diagram

```
User Device              Supabase                Admin Device
    │                       │                        │
    │─ Send Request ───────→ notifications table     │
    │                       │                        │
    │                   [Trigger fires]              │
    │                   [Broadcast event]            │
    │                       │                        │
    │                       │ ←─── Real-time stream ─│
    │                       │                        │
    │                       │          ┌─ Update UI  │
    │                       │          │  Show card  │
    │                       │          │  Update +1  │
    │                       │          └─────────────│
    │                       │                        │
    │ ←─ Admin clicks Complete ←─────────────────── │
    │                       │                        │
    │                   [Update status]              │
    │                   [Update stats]               │
    │                       │                        │
    │                   [Trigger fires]              │
    │                   [Broadcast event]            │
    │                       │                        │
    │                       │ ←─ Real-time update ─ │
    │                       │   (stats updated)      │
    │                       │   (card removed)       │
```

---

## 🔧 Integration Points

### In Your User Home Screen
```dart
import 'package:wastefreebd/services/notification_service.dart';

class UserHomeScreen extends StatelessWidget {
  void _onRequestPickupPressed() async {
    final service = NotificationService();
    await service.sendPickupRequestNotification(
      userId: currentUser.id,
      location: userLocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _onRequestPickupPressed,
      child: const Icon(Icons.phone),
    );
  }
}
```

### In Your Alert Screen
```dart
class AlertScreen extends StatelessWidget {
  void _onDustbinAlertPressed() async {
    final service = NotificationService();
    await service.sendDustbinFullAlert(
      dustbinId: 'db_123',
      location: sensorLocation,
      fillPercentage: sensorData.fillPercent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _onDustbinAlertPressed,
      child: const Text('Report Full'),
    );
  }
}
```

---

## ⚙️ Configuration

### To Change Notification Types
Edit `NOTIFICATIONS_SETUP.sql` line with:
```sql
type text not null check (type in ('pickup_request', 'dustbin_full', 'other'))
```
Add your custom type, then re-run the SQL.

### To Add More Fields to Notification
Edit `notification_model.dart` and add fields:
```dart
class NotificationModel {
  final String userId;  // Add this
  final String location; // Add this
  // ...
}
```

---

## 📞 Troubleshooting

### "Notifications not appearing on admin dashboard?"
- [ ] Check SQL ran successfully in Supabase
- [ ] Go to Supabase > Realtime tab > Verify "notifications" is enabled
- [ ] Check browser console for errors
- [ ] Verify NotificationProvider is initialized

### "Notification sent but no update in stats?"
- [ ] Check `dashboard_stats` table exists with data
- [ ] Check Row Level Security (RLS) policies are set correctly
- [ ] Verify user has permissions to update dashboard_stats

### "App crashes when sending notification?"
- [ ] Make sure you ran `flutter pub get`
- [ ] Check uuid package is installed
- [ ] Verify NotificationService import path is correct

---

## 📚 Files Reference

| File | Purpose |
|------|---------|
| `NOTIFICATIONS_SETUP.sql` | Database tables, triggers, functions |
| `notification_model.dart` | Data class for notifications |
| `notification_provider.dart` | Real-time state management |
| `notification_service.dart` | Helper methods to send notifications |
| `notification_card.dart` | UI widget for displaying notifications |
| `pickup_request_example_screen.dart` | Complete example user screen |
| `admin_dashboard_screen.dart` | Updated admin dashboard with notifications |

---

## 🎓 Next Steps

1. ✅ Execute `NOTIFICATIONS_SETUP.sql` in Supabase
2. ✅ Run `flutter pub get`
3. ✅ Test with manual SQL insert
4. ✅ Integrate `NotificationService` into your user screens
5. ✅ Customize notification types and messages for your needs
6. ✅ Update RLS policies for production security

---

## 🎉 That's It!

Your real-time notification system is ready to go. Users can now send pickup requests and alerts, and admins will see them instantly on the dashboard with the ability to mark them complete with automatic stat updates.

**Happy coding!** 🚀
