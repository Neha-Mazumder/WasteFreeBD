import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Waste-Free Bangladesh Logo Style
            Icon(Icons.recycling, color: Colors.green, size: 80),
            Text("Waste-Free Bangladesh",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800])),
            SizedBox(height: 40),
            TextField(
                decoration: InputDecoration(
                    hintText: "Email", border: OutlineInputBorder())),
            SizedBox(height: 15),
            TextField(
                obscureText: true,
                decoration: InputDecoration(
                    hintText: "Password", border: OutlineInputBorder())),
            SizedBox(height: 25),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(
                  context, '/dashboard'), // Login seshe dashboard-e back
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(double.infinity, 50)),
              child: Text("LOG IN", style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 15),
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black, fontSize: 14),
                children: [
                  TextSpan(text: "Don't have an account? "),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/signup'),
                      child: Text(
                        "signup",
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  TextSpan(text: " now."),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
