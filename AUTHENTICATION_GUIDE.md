# 🔐 Role-Based Access Control System - WasteFreeBD

## Overview
This document explains the complete role-based access control (RBAC) system implemented in the WasteFreeBD application.

---

## 📋 System Architecture

### User Roles
The application supports **4 user roles**:

| Role | Email | Password | Access Level |
|------|-------|----------|--------------|
| **Admin** | admin@gmail.com | 654321 | Full access to all admin features |
| **Management** | management@gmail.com | 54321 | Management dashboard features |
| **Accountant** | accountant@gmail.com | 4321 | Financial & accounting features |
| **User** | Any registered email | Any password | User dashboard features |

---

## 🔧 Authentication Service (`auth_service.dart`)

### Key Features:
- **Test Credentials**: Hardcoded test accounts for each role
- **Supabase Integration**: Real user registration and authentication
- **Role Detection**: Automatic role assignment based on email
- **Token Management**: Handles user sessions

### Main Methods:

#### `signIn(email, password)`
Authenticates user and returns role-based access details.

```dart
final result = await _authService.signIn(
  email: 'admin@gmail.com',
  password: '654321',
);

if (result['success']) {
  final role = result['role']; // UserRole.admin
  // Navigate based on role
}
```

#### `signUp(email, password, fullName, role)`
Registers new user in Supabase and assigns default role (User).

```dart
final result = await _authService.signUp(
  email: 'newuser@gmail.com',
  password: 'password123',
  fullName: 'John Doe',
  role: UserRole.user,
);
```

---

## 🛣️ Navigation & Routing

### Login Flow:
```
Login Screen → Auth Service → Role Check → Redirect
                                    ↓
                        ┌─────────┬────────┬──────────┐
                        ↓         ↓        ↓          ↓
                    Admin    Management  Accountant  User
                    ↓         ↓           ↓          ↓
              /admin/dash  /management  /accountant /dashboard
                    ↓         ↓           ↓          ↓
              Admin Pages   Mgmt Pages  Acct Pages  User Pages
```

### Route Mapping:

**Admin Routes** (`/admin/*`):
- `/admin/dashboard` - Admin Dashboard
- `/admin/finance` - Financial Overview
- `/admin/inventory` - Inventory Management
- `/admin/waste_stock` - Waste Stock Management
- `/admin/workers` - Worker Management

**Management Routes** (`/management/*`):
- `/management/inventory` - Inventory Management
- `/management/workers` - Worker Management
- `/management/waste_stock` - Waste Stock Management

**Accountant Routes** (`/accountant/*`):
- `/accountant/finance` - Financial Overview
- `/accountant/workers` - Worker Management

**User Routes**:
- `/dashboard` - User Dashboard
- `/login` - Login Screen
- `/signup` - Sign Up Screen

---

## 💾 Database Integration

### Supabase Table: `user_profiles`

```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL, -- 'admin', 'management', 'accountant', 'user'
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Auto-Insert on Sign Up:
When a new user registers, their profile is automatically created:
```dart
await supabase.from('user_profiles').insert({
  'id': res.user!.id,
  'email': email,
  'full_name': fullName,
  'role': role.toString().split('.').last,
  'created_at': DateTime.now().toIso8601String(),
});
```

---

## 🔑 Login Screen Features

### Test Credentials Display:
Users can tap "View Test Credentials" to see available test accounts:

```
Admin:        admin@gmail.com / 654321
Management:   management@gmail.com / 54321
Accountant:   accountant@gmail.com / 4321
```

### Login Process:
1. User enters email and password
2. Form validation
3. Auth service checks test credentials first (for development)
4. Falls back to Supabase authentication
5. Fetches user role from database
6. Redirects to appropriate dashboard

---

## 📝 Sign-Up Screen Features

### Registration Fields:
- Full Name (required, min 2 chars)
- Email (required, valid format)
- Password (required, min 4 chars)
- Confirm Password (must match)

### Sign-Up Process:
1. Form validation
2. Create user in Supabase Auth
3. Insert user profile with "user" role
4. Show success message
5. Redirect to login

---

## 🎯 Implementation Details

### 1. Main App Configuration
**File**: `lib/main.dart`

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        // Role-based routes...
      },
    );
  }
}
```

### 2. Login Screen Implementation
**File**: `lib/common/screens/login_screen.dart`

```dart
Future<void> _handleLogin() async {
  final result = await _authService.signIn(
    email: email,
    password: password,
  );

  if (result['success']) {
    final UserRole role = result['role'];
    
    switch (role) {
      case UserRole.admin:
        Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        break;
      case UserRole.management:
        Navigator.of(context).pushReplacementNamed('/management/inventory');
        break;
      case UserRole.accountant:
        Navigator.of(context).pushReplacementNamed('/accountant/finance');
        break;
      case UserRole.user:
        Navigator.of(context).pushReplacementNamed('/dashboard');
        break;
    }
  }
}
```

### 3. Auth Service Configuration
**File**: `lib/common/services/auth_service.dart`

```dart
enum UserRole { admin, management, accountant, user }

class AuthService {
  // Test credentials for development
  static const Map<String, Map<String, String>> testCredentials = {
    'admin': {'email': 'admin@gmail.com', 'password': '654321'},
    'management': {'email': 'management@gmail.com', 'password': '54321'},
    'accountant': {'email': 'accountant@gmail.com', 'password': '4321'},
  };
}
```

---

## 🧪 Testing Guide

### Test Scenario 1: Admin Login
```
1. Open app → Login Screen
2. Email: admin@gmail.com
3. Password: 654321
4. Tap "LOG IN"
5. Expected: Redirects to /admin/dashboard
6. Access: All admin features available
```

### Test Scenario 2: Management Login
```
1. Open app → Login Screen
2. Email: management@gmail.com
3. Password: 54321
4. Tap "LOG IN"
5. Expected: Redirects to /management/inventory
6. Access: Management features only
```

### Test Scenario 3: Accountant Login
```
1. Open app → Login Screen
2. Email: accountant@gmail.com
3. Password: 4321
4. Tap "LOG IN"
5. Expected: Redirects to /accountant/finance
6. Access: Accountant features only
```

### Test Scenario 4: New User Registration
```
1. Open app → Login Screen
2. Tap "SIGN UP"
3. Fill form:
   - Full Name: Test User
   - Email: testuser@gmail.com
   - Password: password123
   - Confirm: password123
4. Tap "CREATE ACCOUNT"
5. Expected: User created, redirects to login
6. Login with new credentials
7. Expected: Redirects to /dashboard (user role)
```

---

## 🔄 Session Management

### Check if User is Authenticated:
```dart
bool isLoggedIn = _authService.isAuthenticated();
```

### Get Current User:
```dart
User? currentUser = _authService.getCurrentUser();
```

### Get Current User Role:
```dart
UserRole role = await _authService.getCurrentUserRole();
```

### Sign Out:
```dart
await _authService.signOut();
// Redirects to login screen
```

---

## 🚀 Production Deployment

### Before Going Live:

1. **Remove Test Credentials**: 
   - Delete hardcoded test accounts from auth_service.dart
   - Only use Supabase authentication

2. **Enable Row-Level Security (RLS)**:
   ```sql
   ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
   
   CREATE POLICY "Users can view their own profile"
     ON user_profiles
     FOR SELECT
     USING (auth.uid() = id);
   ```

3. **Set Up Proper Passwords**:
   - Enforce strong password requirements
   - Implement password reset functionality

4. **Enable Email Verification**:
   - Require users to verify their email
   - Set up email confirmation links

5. **Add Rate Limiting**:
   - Prevent brute force attacks
   - Limit login attempts

---

## 📊 File Structure

```
lib/
├── main.dart (✅ Updated)
├── common/
│   ├── screens/
│   │   ├── login_screen.dart (✅ Updated)
│   │   ├── signup_screen.dart (✅ Updated)
│   │   └── ...
│   └── services/
│       ├── auth_service.dart (✅ NEW)
│       ├── payment_store.dart
│       └── supabase_service.dart
├── admin/
│   └── screens/
│       ├── admin_dashboard_screen.dart
│       ├── financial_overview_screen.dart
│       ├── inventory_management_screen.dart
│       ├── waste_stock_screen.dart
│       └── worker_management_screen.dart
├── management/
│   ├── inventory_management_screen.dart
│   ├── worker_management_screen.dart
│   └── waste_stock_screen.dart
├── accountant/
│   ├── financial_overview_screen copy.dart
│   └── worker_management_screen.dart
└── user/
    └── screens/
        ├── dashboard.dart
        ├── payment.dart
        ├── payment_history.dart
        └── ...
```

---

## ✅ Implementation Checklist

- [x] Create AuthService with role detection
- [x] Implement test credentials system
- [x] Update login screen with role-based navigation
- [x] Create sign-up screen with Supabase integration
- [x] Set up role-based routing in main.dart
- [x] Add Supabase database integration
- [x] Test all login scenarios
- [x] Verify role-based access control
- [x] Add error handling and validation

---

## 🔗 Quick Links

- **Supabase Project**: https://app.supabase.com/
- **Auth Service**: `lib/common/services/auth_service.dart`
- **Login Screen**: `lib/common/screens/login_screen.dart`
- **Sign-Up Screen**: `lib/common/screens/signup_screen.dart`
- **Main App**: `lib/main.dart`

---

## 📞 Support

For issues or questions about the authentication system:
1. Check test credentials in the login screen
2. View the "Test Credentials" dialog
3. Ensure Supabase credentials are correct in main.dart
4. Review auth_service.dart for role mapping logic

---

**Last Updated**: January 16, 2026
**Version**: 1.0.0
