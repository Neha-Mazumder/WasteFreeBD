import 'package:flutter/material.dart';
import 'pages/dashboard.dart'; 
import 'pages/login.dart';
import 'pages/sign.dart';

void main() => runApp(WasteFreeApp());

class WasteFreeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Waste-Free Bangladesh',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      // App shuru hobe Dashboard diye
      initialRoute: '/dashboard', 
      routes: {
        '/dashboard': (context) => EcoWasteDashboard(userName: "Guest"),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
      },
    );
  }
}