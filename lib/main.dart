import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

// Admin screens
import 'admin/screens/admin_dashboard_screen.dart';
import 'admin/screens/financial_overview_screen.dart';
import 'admin/screens/inventory_management_screen.dart';
import 'admin/screens/waste_stock_screen.dart';
import 'admin/screens/worker_management_screen.dart';

// Pages (User-facing screens)
import 'pages/dashboard.dart';
import 'pages/login_screen.dart';
import 'pages/sign.dart' as pages;

// Test screens
import 'user/screens/pickup_request_example_screen.dart';

// Providers
import 'providers/dashboard_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';

// Models
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bqsptmtajnovcbvxpxyf.supabase.co',
    anonKey: 'sb_publishable_RIC0U_qqNRr6eeELY7GdlQ_R-iotjqC',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Waste Free Bangladesh',
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
          primarySwatch: Colors.green,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // If authenticated, route based on role
            if (authProvider.isAuthenticated) {
              final userRole = authProvider.userRole;
              switch (userRole) {
                case UserRole.admin:
                  return const AdminDashboard();
                case UserRole.management:
                  return const ManagementDashboard();
                case UserRole.accountant:
                  return const AccountantDashboard();
                case UserRole.user:
                default:
                  return const UserDashboard();
              }
            }
            // Show login page if not authenticated
            return const LoginScreen();
          },
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => pages.SignUpScreen(),
          '/dashboard': (context) => const UserDashboard(),
          '/admin_dashboard': (context) => const AdminDashboard(),
          '/management_dashboard': (context) => const ManagementDashboard(),
          '/accountant_dashboard': (context) => const AccountantDashboard(),
          '/pickup_request_test': (context) =>
              const PickupRequestExampleScreen(),
        },
      ),
    );
  }
}

// ====== ADMIN DASHBOARD ======
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    FinancialOverviewScreen(),
    InventoryManagementScreen(),
    WasteStockScreen(),
    WorkerManagementScreen(),
  ];

  static const List<String> _titles = [
    'Dashboard',
    'Financial Overview',
    'Inventory',
    'Waste Stock',
    'Workers',
  ];

  static const List<IconData> _icons = [
    Icons.dashboard,
    Icons.money,
    Icons.inventory,
    Icons.delete,
    Icons.people,
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
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
              Provider.of<AuthProvider>(context, listen: false).clearUser();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_titles[_selectedIndex]),
                Text(
                  'Admin - ${authProvider.currentUser?.fullName}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            elevation: 1,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
              ),
            ],
          ),
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            items: List.generate(
              _icons.length,
              (index) => BottomNavigationBarItem(
                icon: Icon(_icons[index]),
                label: _titles[index],
              ),
            ),
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }
}

// ====== MANAGEMENT DASHBOARD ======
class ManagementDashboard extends StatefulWidget {
  const ManagementDashboard({super.key});

  @override
  State<ManagementDashboard> createState() => _ManagementDashboardState();
}

class _ManagementDashboardState extends State<ManagementDashboard> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    InventoryManagementScreen(),
    WasteStockScreen(),
    WorkerManagementScreen(),
  ];

  static const List<String> _titles = [
    'Inventory',
    'Waste Stock',
    'Workers',
  ];

  static const List<IconData> _icons = [
    Icons.inventory,
    Icons.delete,
    Icons.people,
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
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
              Provider.of<AuthProvider>(context, listen: false).clearUser();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_titles[_selectedIndex]),
                Text(
                  'Manager - ${authProvider.currentUser?.fullName}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            elevation: 1,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
              ),
            ],
          ),
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            items: List.generate(
              _icons.length,
              (index) => BottomNavigationBarItem(
                icon: Icon(_icons[index]),
                label: _titles[index],
              ),
            ),
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }
}

// ====== ACCOUNTANT DASHBOARD ======
class AccountantDashboard extends StatefulWidget {
  const AccountantDashboard({super.key});

  @override
  State<AccountantDashboard> createState() => _AccountantDashboardState();
}

class _AccountantDashboardState extends State<AccountantDashboard> {
  void _logout() {
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
              Provider.of<AuthProvider>(context, listen: false).clearUser();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Financial Overview'),
                Text(
                  'Accountant - ${authProvider.currentUser?.fullName}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            elevation: 1,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
              ),
            ],
          ),
          body: const FinancialOverviewScreen(),
        );
      },
    );
  }
}

// ====== USER DASHBOARD ======
class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  void _logout() {
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
              Provider.of<AuthProvider>(context, listen: false).clearUser();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dashboard'),
                Text(
                  'User - ${authProvider.currentUser?.fullName}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            elevation: 1,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
              ),
            ],
          ),
          body: EcoWasteDashboard(),
        );
      },
    );
  }
}

// Get global instance
SupabaseClient get supabase => Supabase.instance.client;
