# 🔐 Role-Based Access Control Implementation Guide

## Overview
This guide explains how to implement and use the role-based access control (RBAC) system in WasteFreeBD.

## 4 User Roles

| Role | Email | Password | Access |
|------|-------|----------|--------|
| **Admin** | admin@gmail.com | 123 | Full system access |
| **Management** | management@gmail.com | 1234 | Inventory & worker management |
| **Accountant** | accountant@gmail.com | 12345 | Financial & reporting |
| **User** | user@gmail.com | 123456 | Waste tracking & services |

---

## Architecture

### 1. Core Models (`lib/models/user_model.dart`)

**UserRole Enum**
```dart
enum UserRole {
  admin,
  management,
  accountant,
  user,
}
```

**AuthUser Model**
- Stores authenticated user information
- Contains: id, email, fullName, role, createdAt

### 2. Services (`lib/services/auth_service.dart`)

**AuthService Singleton**
- Handles login/signup
- Manages test credentials
- Determines role from email
- Queries database for users

**Key Methods:**
```dart
// Sign in user
Future<Map<String, dynamic>> signIn({
  required String email,
  required String password,
})

// Sign up new user
Future<Map<String, dynamic>> signUp({
  required String email,
  required String password,
  required String fullName,
})

// Get test credentials
static Map<String, Map<String, String>> getTestCredentials()
```

### 3. Provider (`lib/providers/auth_provider.dart`)

**AuthProvider (ChangeNotifier)**
- Manages authentication state globally
- Provides current user and role
- Notifies UI on auth changes

**Key Methods:**
```dart
// Set authenticated user
void setUser(AuthUser user)

// Logout
void clearUser()

// Check roles
bool hasRole(UserRole role)
bool hasAnyRole(List<UserRole> roles)
```

### 4. Route Protection (`lib/common/widgets/role_based_route.dart`)

**RoleBasedRoute Widget**
- Wraps screens to check user role
- Shows access denied if unauthorized

**RoleBasedRoutes Helper**
```dart
// Get home route for role
static String getHomeRoute(UserRole role)

// Get available routes for role
static List<String> getAvailableRoutes(UserRole role)

// Check access
static bool hasRouteAccess(UserRole role, String route)
```

---

## Setup Instructions

### Step 1: Update Main App

Update `lib/main.dart`:

```dart
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'common/screens/login_screen_v2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'your_supabase_url',
    anonKey: 'your_anon_key',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        // ... other providers
      ],
      child: MaterialApp(
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (!authProvider.isAuthenticated) {
              return const LoginScreenV2();
            }
            
            // Route based on role
            final homeRoute = RoleBasedRoutes.getHomeRoute(
              authProvider.userRole!,
            );
            
            return Navigator(
              onGenerateRoute: (settings) {
                // Handle role-based routing
              },
            );
          },
        ),
      ),
    );
  }
}
```

### Step 2: Protect Screens with RoleBasedRoute

Wrap dashboard screens:

```dart
class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return RoleBasedRoute(
      allowedRoles: [UserRole.admin],
      userRole: authProvider.userRole,
      child: Scaffold(
        // Admin dashboard content
      ),
    );
  }
}
```

### Step 3: Check Roles in Code

```dart
final authProvider = Provider.of<AuthProvider>(context);

// Check single role
if (authProvider.hasRole(UserRole.admin)) {
  // Show admin features
}

// Check multiple roles
if (authProvider.hasAnyRole([UserRole.admin, UserRole.management])) {
  // Show shared features
}

// Get current user
final user = authProvider.currentUser;
print(user?.email);
print(user?.role.displayName);
```

---

## Route Mapping

### Admin Routes
- `/admin/dashboard` - Dashboard
- `/admin/finance` - Financial overview
- `/admin/inventory` - Inventory management
- `/admin/waste_stock` - Waste stock tracking
- `/admin/workers` - Worker management

### Management Routes
- `/management/dashboard` - Dashboard
- `/management/inventory` - Inventory
- `/management/waste_stock` - Waste stock
- `/management/workers` - Workers

### Accountant Routes
- `/accountant/dashboard` - Dashboard
- `/accountant/finance` - Financial reports
- `/accountant/workers` - Worker info

### User Routes
- `/dashboard` - User dashboard
- `/services` - Services
- `/profile` - Profile
- `/history` - History

---

## Features

### ✅ Test Accounts (Pre-configured)
```
Admin:       admin@gmail.com / 123
Management:  management@gmail.com / 1234
Accountant:  accountant@gmail.com / 12345
User:        user@gmail.com / 123456
```

### ✅ Email-Based Role Assignment
- Email contains "admin" → Admin role
- Email contains "management" → Management role
- Email contains "accountant" → Accountant role
- Otherwise → User role

### ✅ Database Role Storage
- Roles stored in 'signin' table
- Persists across sessions
- Can be updated in Supabase console

### ✅ Global State Management
- AuthProvider tracks current user
- Accessible from any widget
- Notifies UI on changes

### ✅ Route Protection
- RoleBasedRoute wraps sensitive screens
- Automatic redirect on unauthorized access
- User-friendly error messages

---

## Usage Examples

### Login Flow
```dart
// User enters credentials
// AuthService validates against test accounts or database
// On success: Create AuthUser
// AuthProvider.setUser(authUser)
// Navigate to home route based on role
```

### Accessing User Info
```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    final user = authProvider.currentUser;
    if (user != null) {
      return Text('Welcome, ${user.fullName}!');
    }
    return const Text('Not logged in');
  },
)
```

### Protecting a Feature
```dart
Widget buildFeature(BuildContext context) {
  final authProvider = Provider.of<AuthProvider>(context);
  
  if (!authProvider.hasRole(UserRole.admin)) {
    return const Text('Admin only');
  }
  
  return AdminFeature();
}
```

### Logout
```dart
ElevatedButton(
  onPressed: () {
    Provider.of<AuthProvider>(context, listen: false).clearUser();
    Navigator.of(context).pushReplacementNamed('/login');
  },
  child: const Text('Logout'),
)
```

---

## Database Setup (Supabase)

Create 'signin' table with columns:
```sql
- id (uuid, primary key)
- email (text, unique)
- password (text)
- full_name (text)
- role (text) -- admin, management, accountant, user
- created_at (timestamp)
```

---

## Troubleshooting

### Issue: User stays on login screen
**Solution:** Check AuthProvider is in MultiProvider above MaterialApp

### Issue: Role-based route shows access denied
**Solution:** Verify user role matches allowed roles in RoleBasedRoute

### Issue: Can't login with test account
**Solution:** Test credentials are hardcoded in AuthService.testCredentials

### Issue: Role is always 'user'
**Solution:** Update email to contain role name (admin, management, accountant)

---

## Security Notes

⚠️ **Important**: This setup uses hardcoded test credentials for development.

For production:
1. Remove test credentials from code
2. Use Supabase authentication API
3. Implement JWT tokens
4. Hash passwords before storage
5. Use secure session management

---

## File Structure

```
lib/
├── models/
│   └── user_model.dart          # UserRole & AuthUser
├── services/
│   └── auth_service.dart        # Authentication logic
├── providers/
│   └── auth_provider.dart       # State management
├── common/
│   ├── screens/
│   │   └── login_screen_v2.dart # New login UI
│   └── widgets/
│       └── role_based_route.dart # Route protection
└── main.dart                     # App setup
```

---

## Next Steps

1. ✅ Implement AuthProvider in main.dart
2. ✅ Replace LoginScreen with LoginScreenV2
3. ✅ Wrap role-specific screens with RoleBasedRoute
4. ✅ Test login with different test accounts
5. ✅ Verify role-based routing works
6. ✅ Deploy and monitor

