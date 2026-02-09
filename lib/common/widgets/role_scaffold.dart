import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RoleScaffold extends StatefulWidget {
  final Widget body;
  final String screenName;
  final PreferredSizeWidget? appBar;

  const RoleScaffold({
    super.key,
    required this.body,
    required this.screenName,
    this.appBar,
  });

  @override
  State<RoleScaffold> createState() => _RoleScaffoldState();
}

class _RoleScaffoldState extends State<RoleScaffold> {
  final AuthService _authService = AuthService();

  int _getSelectedIndex() {
    final role = _authService.getCurrentUserRole();

    switch (role) {
      case UserRole.admin:
        if (widget.screenName.contains('dashboard')) return 0;
        if (widget.screenName.contains('inventory')) return 1;
        if (widget.screenName.contains('waste')) return 2;
        if (widget.screenName.contains('worker')) return 3;
        if (widget.screenName.contains('finance')) return 4;
        return 0;

      case UserRole.management:
        if (widget.screenName.contains('inventory')) return 0;
        if (widget.screenName.contains('waste')) return 1;
        if (widget.screenName.contains('worker')) return 2;
        return 0;

      case UserRole.accountant:
        if (widget.screenName.contains('finance')) return 0;
        if (widget.screenName.contains('worker')) return 1;
        return 0;

      case UserRole.user:
        return 0;

      default:
        return 0;
    }
  }

  void _handleNavigation(int index) {
    final role = _authService.getCurrentUserRole();

    switch (role) {
      case UserRole.admin:
        _adminNavigation(index);
        break;
      case UserRole.management:
        _managementNavigation(index);
        break;
      case UserRole.accountant:
        _accountantNavigation(index);
        break;
      case UserRole.user:
        _userNavigation(index);
        break;
      default:
        break;
    }
  }

  void _adminNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/admin/inventory');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/admin/waste_stock');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/admin/workers');
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed('/admin/finance');
        break;
    }
  }

  void _managementNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/management/inventory');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/management/waste_stock');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/management/workers');
        break;
    }
  }

  void _accountantNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/accountant/finance');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/accountant/workers');
        break;
    }
  }

  void _userNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/dashboard');
        break;
      case 1:
        // User services page
        break;
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _authService.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = _authService.getCurrentUserRole();
    final selectedIndex = _getSelectedIndex();

    return Scaffold(
      appBar: widget.appBar,
      body: widget.body,
      bottomNavigationBar: _buildBottomNavigationBar(role, selectedIndex),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          onPressed: _handleLogout,
          backgroundColor: Colors.red,
          tooltip: 'Logout',
          child: const Icon(Icons.logout),
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar(
      UserRole? role, int selectedIndex) {
    switch (role) {
      case UserRole.admin:
        return BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: _handleNavigation,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.inventory), label: 'Inventory'),
            BottomNavigationBarItem(
                icon: Icon(Icons.delete), label: 'Waste Stock'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Workers'),
            BottomNavigationBarItem(
                icon: Icon(Icons.trending_up), label: 'Finance'),
          ],
        );

      case UserRole.management:
        return BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: _handleNavigation,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.inventory), label: 'Inventory'),
            BottomNavigationBarItem(icon: Icon(Icons.delete), label: 'Waste'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Workers'),
          ],
        );

      case UserRole.accountant:
        return BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: _handleNavigation,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.trending_up), label: 'Finance'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Workers'),
          ],
        );

      case UserRole.user:
        return BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: _handleNavigation,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Services'),
          ],
        );

      default:
        return BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          ],
        );
    }
  }
}
