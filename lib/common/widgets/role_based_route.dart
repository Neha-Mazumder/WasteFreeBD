import 'package:flutter/material.dart';
import '../../models/user_model.dart';

/// Widget to protect routes based on user role
class RoleBasedRoute extends StatelessWidget {
  final Widget child;
  final List<UserRole> allowedRoles;
  final UserRole? userRole;
  final VoidCallback? onUnauthorized;

  const RoleBasedRoute({
    Key? key,
    required this.child,
    required this.allowedRoles,
    this.userRole,
    this.onUnauthorized,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!allowedRoles.contains(userRole)) {
      if (onUnauthorized != null) {
        onUnauthorized!();
      }
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have permission to access this page.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return child;
  }
}

/// Navigator observer to handle route protection
class RoleBasedNavigatorObserver extends NavigatorObserver {
  final UserRole? userRole;
  final Map<String, List<UserRole>> protectedRoutes;

  RoleBasedNavigatorObserver({
    this.userRole,
    this.protectedRoutes = const {},
  });

  @override
  void didPush(Route route, Route? previousRoute) {
    _checkRouteAccess(route);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (newRoute != null) {
      _checkRouteAccess(newRoute);
    }
  }

  void _checkRouteAccess(Route route) {
    final routeName = route.settings.name;
    if (routeName == null || userRole == null) return;

    final allowedRoles = protectedRoutes[routeName];
    if (allowedRoles != null && !allowedRoles.contains(userRole)) {
      // Route is protected and user doesn't have access
      print('Access denied to route: $routeName for role: ${userRole?.value}');
    }
  }
}

/// Helper to get role-based routes
class RoleBasedRoutes {
  /// Get home route based on user role
  static String getHomeRoute(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return '/admin/dashboard';
      case UserRole.management:
        return '/management/dashboard';
      case UserRole.accountant:
        return '/accountant/dashboard';
      case UserRole.user:
        return '/dashboard';
    }
  }

  /// Get all available routes for a role
  static List<String> getAvailableRoutes(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return [
          '/admin/dashboard',
          '/admin/finance',
          '/admin/inventory',
          '/admin/waste_stock',
          '/admin/workers',
        ];
      case UserRole.management:
        return [
          '/management/dashboard',
          '/management/inventory',
          '/management/waste_stock',
          '/management/workers',
        ];
      case UserRole.accountant:
        return [
          '/accountant/dashboard',
          '/accountant/finance',
          '/accountant/workers',
        ];
      case UserRole.user:
        return [
          '/dashboard',
          '/services',
          '/profile',
          '/history',
        ];
    }
  }

  /// Check if role has access to route
  static bool hasRouteAccess(UserRole role, String route) {
    return getAvailableRoutes(role).contains(route);
  }
}
