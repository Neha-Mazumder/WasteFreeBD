import 'package:flutter/material.dart';

class DustbinAlertPage extends StatefulWidget {
  final bool isDark;

  const DustbinAlertPage({
    Key? key,
    this.isDark = false,
  }) : super(key: key);

  @override
  _DustbinAlertPageState createState() => _DustbinAlertPageState();
}

class _DustbinAlertPageState extends State<DustbinAlertPage> {
  final List<Map<String, dynamic>> alerts = [
    {
      'title': 'Dustbin Full Alert',
      'location': '123 Main Street',
      'time': '2 hours ago',
      'severity': 'high',
    },
    {
      'title': 'Maintenance Required',
      'location': '456 Oak Avenue',
      'time': '4 hours ago',
      'severity': 'medium',
    },
    {
      'title': 'Scheduled Pickup',
      'location': '789 Pine Road',
      'time': '6 hours ago',
      'severity': 'low',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dustbin Alerts'),
        backgroundColor: widget.isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          final color = _getSeverityColor(alert['severity']);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning, color: color),
              ),
              title: Text(
                alert['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(alert['location']),
                  Text(
                    alert['time'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: Icon(
                Icons.arrow_forward,
                color: color,
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Alert: ${alert['title']}')),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
