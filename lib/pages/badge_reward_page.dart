import 'package:flutter/material.dart';

class BadgeRewardPage extends StatelessWidget {
  final bool isDark;

  const BadgeRewardPage({
    Key? key,
    this.isDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges & Rewards'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Badges',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBadgeTile(
              'Gold Badge',
              '৳10,000 donated',
              Icons.star,
              Colors.amber,
              true,
            ),
            _buildBadgeTile(
              'Silver Badge',
              '৳5,000 donated',
              Icons.star,
              Colors.grey,
              true,
            ),
            _buildBadgeTile(
              'Bronze Badge',
              '৳1,000 donated',
              Icons.star,
              Colors.brown,
              true,
            ),
            const SizedBox(height: 32),
            const Text(
              'Rewards',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRewardTile(
              '🎁 ৳5,000 Discount Voucher',
              'Gold members only',
            ),
            _buildRewardTile(
              '🎁 ৳2,500 Discount Voucher',
              'Silver members and above',
            ),
            _buildRewardTile(
              '🎁 ৳500 Discount Voucher',
              'Bronze members and above',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool unlocked,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: unlocked ? color.withOpacity(0.2) : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                unlocked ? Icons.check : Icons.lock,
                color: unlocked ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardTile(String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
