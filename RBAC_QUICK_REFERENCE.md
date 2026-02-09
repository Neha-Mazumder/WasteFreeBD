# 🔐 RBAC Quick Reference

## Test Credentials (Ready to Use)

```
ADMIN:       admin@gmail.com / 123
MANAGEMENT:  management@gmail.com / 1234
ACCOUNTANT:  accountant@gmail.com / 12345
USER:        user@gmail.com / 123456
```

## Quick Implementation

### 1. Check Current User Role
```dart
final authProvider = Provider.of<AuthProvider>(context);
print(authProvider.userRole); // UserRole.admin
print(authProvider.currentUser?.fullName); // Admin User
```

### 2. Protect a Screen
```dart
class AdminScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return RoleBasedRoute(
      allowedRoles: [UserRole.admin],
      userRole: authProvider.userRole,
      child: Scaffold(
        body: Text('Admin only content'),
      ),
    );
  }
}
```

### 3. Show/Hide Features
```dart
if (authProvider.hasRole(UserRole.admin)) {
  // Show admin button
  return AdminButton();
}

if (authProvider.hasAnyRole([UserRole.admin, UserRole.management])) {
  // Show for admin and management
  return ManagementButton();
}
```

### 4. Logout
```dart
ElevatedButton(
  onPressed: () {
    Provider.of<AuthProvider>(context, listen: false).clearUser();
    Navigator.pushReplacementNamed(context, '/');
  },
  child: Text('Logout'),
)
```

## Role Hierarchy

```
Admin (Highest)
  - Full system access
  - All features
  - Can manage all roles

Management
  - Inventory management
  - Worker management
  - Waste stock tracking

Accountant
  - Financial reports
  - Revenue tracking
  - Expense management

User (Lowest)
  - Personal dashboard
  - Service tracking
  - Reward system
```

## User Flows

### Admin Flow
```
Login → AuthService.signIn() → AuthProvider.setUser()
→ RoleBasedRoutes.getHomeRoute(UserRole.admin)
→ /admin/dashboard → Full access to all admin features
```

### Management Flow
```
Login → AuthService.signIn() → AuthProvider.setUser()
→ RoleBasedRoutes.getHomeRoute(UserRole.management)
→ /management/dashboard → Limited to management features
```

### Accountant Flow
```
Login → AuthService.signIn() → AuthProvider.setUser()
→ RoleBasedRoutes.getHomeRoute(UserRole.accountant)
→ /accountant/dashboard → Financial features only
```

### User Flow
```
Login → AuthService.signIn() → AuthProvider.setUser()
→ RoleBasedRoutes.getHomeRoute(UserRole.user)
→ /dashboard → User features
```

## File Locations

| File | Purpose |
|------|---------|
| `lib/models/user_model.dart` | UserRole, AuthUser models |
| `lib/services/auth_service.dart` | Login/signup logic |
| `lib/providers/auth_provider.dart` | Global auth state |
| `lib/common/screens/login_screen_v2.dart` | New login UI |
| `lib/common/widgets/role_based_route.dart` | Route protection |
| `RBAC_SETUP_GUIDE.md` | Detailed setup guide |

## Debugging

### Check if user is logged in
```dart
final authProvider = Provider.of<AuthProvider>(context);
print(authProvider.isAuthenticated); // true/false
```

### Get current user email
```dart
print(authProvider.currentUser?.email);
```

### Get current user role
```dart
print(authProvider.userRole); // UserRole.admin
print(authProvider.userRole?.displayName); // "Administrator"
```

### Check available routes for role
```dart
final routes = RoleBasedRoutes.getAvailableRoutes(UserRole.admin);
print(routes); // ['/admin/dashboard', '/admin/finance', ...]
```

## Error Messages

| Message | Solution |
|---------|----------|
| "Invalid email or password" | Check test credentials or database |
| "Access Denied" | User role not in allowedRoles list |
| "User not authenticated" | Check AuthProvider is in MultiProvider |
| "Route not found" | Verify route is registered in main.dart |

## Testing

### Test Admin Login
1. Open app
2. Enter: `admin@gmail.com` / `123`
3. Should navigate to `/admin/dashboard`
4. Should have access to all admin features

### Test Management Login
1. Enter: `management@gmail.com` / `1234`
2. Should navigate to `/management/dashboard`
3. Should only see management features

### Test Accountant Login
1. Enter: `accountant@gmail.com` / `12345`
2. Should navigate to `/accountant/dashboard`
3. Should only see financial features

### Test User Login
1. Enter: `user@gmail.com` / `123456`
2. Should navigate to `/dashboard`
3. Should see user features

## Common Tasks

### Add new role
1. Add to `UserRole` enum in `user_model.dart`
2. Update `_getRoleFromEmail()` in `auth_service.dart`
3. Add test credentials
4. Update route maps in `role_based_route.dart`

### Restrict a feature to role
```dart
if (!authProvider.hasRole(UserRole.admin)) {
  return SizedBox.shrink(); // Hide
}
return AdminFeature();
```

### Log user info on login
```dart
final user = authProvider.currentUser;
print('User: ${user?.email}');
print('Role: ${user?.role.displayName}');
print('Name: ${user?.fullName}');
```

## Best Practices

✅ **DO:**
- Check role before showing sensitive data
- Use Consumer to rebuild only when auth changes
- Log user actions for security
- Validate permissions server-side (future)
- Use role-based routes consistently

❌ **DON'T:**
- Hardcode user checks in UI
- Show all features and disable them
- Trust client-side role checks for security
- Store passwords in plaintext (update for production)
- Forget to logout before switching accounts

