import 'package:flutter/material.dart';
import 'package:wastefreebd/services/notification_service.dart';

/// Example User Screen demonstrating how to send notifications
class PickupRequestExampleScreen extends StatefulWidget {
  const PickupRequestExampleScreen({super.key});

  @override
  State<PickupRequestExampleScreen> createState() =>
      _PickupRequestExampleScreenState();
}

class _PickupRequestExampleScreenState
    extends State<PickupRequestExampleScreen> {
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _locationController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _sendPickupRequest() async {
    if (_locationController.text.isEmpty) {
      _showError('Please enter your location');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _notificationService.sendPickupRequestNotification(
        userId: 'user_123', // Replace with actual user ID
        location: _locationController.text,
        additionalInfo:
            _detailsController.text.isNotEmpty ? _detailsController.text : null,
      );

      if (mounted) {
        _locationController.clear();
        _detailsController.clear();
        _showSuccess('✓ Pickup request sent to admin!');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to send request: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _sendDustbinAlert() async {
    if (_locationController.text.isEmpty) {
      _showError('Please enter location of dustbin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _notificationService.sendDustbinFullAlert(
        dustbinId: 'db_${DateTime.now().millisecondsSinceEpoch}',
        location: _locationController.text,
        fillPercentage: 95.0, // You can make this dynamic
      );

      if (mounted) {
        _locationController.clear();
        _detailsController.clear();
        _showSuccess('✓ Dustbin full alert sent to admin!');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to send alert: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF13EC5B),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF13EC5B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Pickup / Report Alert'),
        backgroundColor: const Color(0xFF102216),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF6F8F6),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pickup Request Section
            _buildSectionHeader('🚚 Request Pickup', primary),
            const SizedBox(height: 16),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Enter your location',
                      prefixIcon: const Icon(Icons.location_on, color: primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _detailsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Additional details (optional)',
                      prefixIcon: const Icon(Icons.description, color: primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _sendPickupRequest,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(primary),
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                          _isLoading ? 'Sending...' : 'Send Pickup Request'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Dustbin Alert Section
            _buildSectionHeader('🗑️ Report Dustbin Full', primary),
            const SizedBox(height: 16),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Dustbin location',
                      prefixIcon: const Icon(Icons.location_on, color: primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primary),
                      ),
                    ),
                    onChanged: (value) {
                      _locationController.text = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primary),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Fill percentage: ~95% (detected by IoT sensor)',
                            style: TextStyle(
                              color: primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _sendDustbinAlert,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(primary),
                              ),
                            )
                          : const Icon(Icons.warning),
                      label: Text(_isLoading ? 'Sending...' : 'Send Alert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Info Section
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: const Color(0xFF13EC5B).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFF13EC5B),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info, color: Color(0xFF13EC5B), size: 20),
                SizedBox(width: 8),
                Text(
                  'How it works',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF13EC5B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoBullet('Your request is sent to the admin in real-time'),
            _buildInfoBullet(
                'Admin receives instant notification on dashboard'),
            _buildInfoBullet(
                'Admin marks as complete → Pickup count increases'),
            _buildInfoBullet('You receive confirmation once pickup is done'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: SizedBox(
              width: 6,
              height: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF13EC5B),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
