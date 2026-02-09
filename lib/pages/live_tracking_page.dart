import 'package:flutter/material.dart';

class LiveTrackingPage extends StatefulWidget {
  final bool isDark;

  const LiveTrackingPage({
    Key? key,
    this.isDark = false,
  }) : super(key: key);

  @override
  _LiveTrackingPageState createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: widget.isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.my_location,
              size: 64,
              color: Colors.blue[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Live Tracking',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your waste collection van in real-time',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('No active pickups at the moment')),
                );
              },
              child: const Text('Start Tracking'),
            ),
          ],
        ),
      ),
    );
  }
}
