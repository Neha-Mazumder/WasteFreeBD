import 'package:flutter/material.dart';
import 'dashboard.dart';

class SignUpScreen extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(30),
        child: Column(
          children: [
            SizedBox(height: 50),
            Text("Join Us Today!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Icon(Icons.eco, color: Colors.green, size: 60),
            Text("Waste-Free Bangladesh", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            SizedBox(height: 40),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(hintText: "Full Name", prefixIcon: Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
            ),
            SizedBox(height: 15),
            TextField(decoration: InputDecoration(hintText: "Email", prefixIcon: Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            SizedBox(height: 15),
            TextField(obscureText: true, decoration: InputDecoration(hintText: "Password", prefixIcon: Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => EcoWasteDashboard(userName: _nameController.text)));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2ECC71), minimumSize: Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: Text("CREATE ACCOUNT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}