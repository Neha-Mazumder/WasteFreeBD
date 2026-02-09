import 'package:flutter/material.dart';

class AllServicesPage extends StatelessWidget {
  final bool isDark;

  const AllServicesPage({
    Key? key,
    this.isDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Services'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildServiceTile(
            context,
            'Waste Pickup',
            'Schedule a pickup for your waste',
            Icons.local_shipping,
            Colors.orange,
          ),
          _buildServiceTile(
            context,
            'Donate Now',
            'Make a donation to help the environment',
            Icons.favorite,
            Colors.red,
          ),
          _buildServiceTile(
            context,
            'Recycling Info',
            'Learn about recycling tips',
            Icons.info,
            Colors.green,
          ),
          _buildServiceTile(
            context,
            'Track Van',
            'Track waste collection vans in real-time',
            Icons.my_location,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title selected')),
          );
        },
      ),
    );
  }
}
