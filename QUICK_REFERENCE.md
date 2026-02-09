# 🎯 Quick Reference - Role-Based Access Control

## 📱 Login Credentials

### Test Accounts (Development Only)

| Role | Email | Password | Redirect |
|------|-------|----------|----------|
| **Admin** | `admin@gmail.com` | `654321` | Admin Dashboard |
| **Management** | `management@gmail.com` | `54321` | Management Portal |
| **Accountant** | `accountant@gmail.com` | `4321` | Accounting Panel |
| **User** | Register new | Any | User Dashboard |

---

## 🗺️ Role-Based Dashboards

### 👨‍💼 Admin Dashboard
- **Route**: `/admin/dashboard`
- **Access**: All system features
- **Features**:
  - Financial Overview
  - Inventory Management
  - Waste Stock Tracking
  - Worker Management

### 🏢 Management Dashboard
- **Route**: `/management/inventory`
- **Access**: Management features only
- **Features**:
  - Inventory Management
  - Worker Management
  - Waste Stock Tracking

### 💼 Accountant Dashboard
- **Route**: `/accountant/finance`
- **Access**: Finance & Accounting
- **Features**:
  - Financial Overview
  - Worker Management

### 👤 User Dashboard
- **Route**: `/dashboard`
- **Access**: User features only
- **Features**:
  - Waste Pickup Request
  - Donate Items
  - Van Tracking
  - Payment

---

## 🔐 Authentication Flow

```
START
  ↓
LOGIN SCREEN
  ↓
ENTER EMAIL & PASSWORD
  ↓
CLICK "LOG IN"
  ↓
AuthService.signIn()
  ↓
  ├─→ CHECK TEST CREDENTIALS
  │    ├─→ MATCH → Return Role
  │    └─→ NO → Check Supabase
  │
  └─→ CHECK SUPABASE
       ├─→ FOUND → Get Role from DB
       │    ├─→ ADMIN → /admin/dashboard
       │    ├─→ MANAGEMENT → /management/inventory
       │    ├─→ ACCOUNTANT → /accountant/finance
       │    └─→ USER → /dashboard
       │
       └─→ ERROR → Show Error Message
```

---

## 📁 Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App configuration & routing |
| `lib/common/services/auth_service.dart` | Authentication logic |
| `lib/common/screens/login_screen.dart` | Login UI & form |
| `lib/common/screens/signup_screen.dart` | Registration UI & form |

---

## 💻 Code Snippets

### Get AuthService Instance
```dart
final authService = AuthService();
```

### Sign In User
```dart
final result = await AuthService().signIn(
  email: 'admin@gmail.com',
  password: '654321',
);

if (result['success']) {
  print('Role: ${result['role']}');
}
```

### Sign Up User
```dart
final result = await AuthService().signUp(
  email: 'newuser@gmail.com',
  password: 'password123',
  fullName: 'John Doe',
  role: UserRole.user,
);
```

### Check Authentication
```dart
bool isLoggedIn = AuthService().isAuthenticated();
User? user = AuthService().getCurrentUser();
```

### Sign Out
```dart
await AuthService().signOut();
Navigator.of(context).pushReplacementNamed('/login');
```

---

## 🧪 Testing Checklist

- [ ] Admin login with test credentials
- [ ] Management login with test credentials
- [ ] Accountant login with test credentials
- [ ] New user registration
- [ ] Login with registered email
- [ ] Error handling (wrong password)
- [ ] Password visibility toggle
- [ ] Form validation
- [ ] Test credentials dialog display

---

## 🛠️ Troubleshooting

### Login Not Working
1. Check email format
2. Verify password is correct
3. Check Supabase connection
4. Review console logs for errors

### User Not Redirected
1. Verify role is correctly assigned
2. Check route names in main.dart
3. Ensure screen files are imported

### Supabase Connection Issues
1. Verify URL and API key in main.dart
2. Check internet connection
3. Review Supabase project settings

### Password Reset
- Feature coming soon
- Currently shows placeholder message

---

## 📊 User Roles Hierarchy

```
ADMIN (Full Access)
  ├── View All Dashboards
  ├── Access All Features
  └── Manage All Users

MANAGEMENT (Management Access)
  ├── Inventory Management
  ├── Worker Management
  └── Waste Stock Tracking

ACCOUNTANT (Finance Access)
  ├── Financial Overview
  └── Worker Management

USER (User Access)
  ├── Dashboard
  ├── Waste Pickup
  ├── Donations
  ├── Van Tracking
  └── Payments
```

---

## 🔄 Session Management

### Current Session
```dart
User? currentUser = AuthService().getCurrentUser();
UserRole role = await AuthService().getCurrentUserRole();
```

### Check if Session Exists
```dart
if (AuthService().isAuthenticated()) {
  // User is logged in
} else {
  // Redirect to login
}
```

---

## 📝 Database Schema

### user_profiles Table
```sql
Column      | Type      | Description
------------|-----------|------------------
id          | UUID      | User ID (Supabase Auth)
email       | TEXT      | User email (unique)
full_name   | TEXT      | User's full name
role        | TEXT      | admin/management/accountant/user
created_at  | TIMESTAMP | Account creation time
```

---

## 🚀 Deployment Checklist

- [ ] Remove test credentials from auth_service.dart
- [ ] Enable Supabase Row-Level Security (RLS)
- [ ] Set up email verification
- [ ] Configure strong password requirements
- [ ] Add rate limiting to login endpoint
- [ ] Set up password reset flow
- [ ] Configure CORS policies
- [ ] Test all roles in production
- [ ] Set up monitoring & logging
- [ ] Create admin recovery account

---

## 📞 Quick Support

**Test Credentials Not Working?**
- Make sure you're on the login screen
- Click "View Test Credentials" button to see all options

**Forgot Your Password?**
- Click "Forgot Password?" (feature coming soon)

**Account Not Created?**
- Go to sign-up screen
- Fill in all required fields
- Tap "CREATE ACCOUNT"

---

**Version**: 1.0.0  
**Last Updated**: January 16, 2026
