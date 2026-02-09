import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wastefreebd/supabase_client.dart';
import 'admin/screens/inventory_management_screen.dart';
import 'admin/screens/waste_stock_screen.dart';
import 'admin/screens/worker_management_screen.dart';
import 'providers/dashboard_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => DashboardProvider()),
    ],
    child: const AdminTestApp(),
  ));
}

class AdminTestApp extends StatefulWidget {
  const AdminTestApp({super.key});

  @override
  State<AdminTestApp> createState() => _AdminTestAppState();
}

class _AdminTestAppState extends State<AdminTestApp> {
  int _selectedIndex = 0;

  // List of your screens
  static const List<Widget> _screens = [
     // You'll create this
    InventoryManagementScreen(),
    WasteStockScreen(),
    WorkerManagementScreen(),
  ];

  static const List<String> _titles = [
    'Inventory',
    'Waste Stock',
    'Workers',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Management Test App',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
      ),
      themeMode: ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_selectedIndex]),
          backgroundColor: const Color(0xFF13EC5B),
          foregroundColor: Colors.black87,
        ),
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFF13EC5B),
          unselectedItemColor: Colors.grey,
          items: const [
           
        
            BottomNavigationBarItem(
                icon: Icon(Icons.inventory), label: 'Inventory'),
            BottomNavigationBarItem(
                icon: Icon(Icons.recycling), label: 'Waste Stock'),
            BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Workers'),
          ],
        ),
      ),
    );
  }
}
