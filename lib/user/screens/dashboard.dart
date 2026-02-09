import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:wastefreebd/common/widgets/role_scaffold.dart';
import 'package:wastefreebd/services/notification_service.dart';
import 'donation.dart';
import '../../pages/payment.dart';
import '../../pages/payment_history_page.dart';
import '../../pages/all_services_page.dart';
import '../../pages/live_tracking_page.dart';
import '../../pages/badge_reward_page.dart';
import '../../pages/dustbin_alert_page.dart';

// --- GLOBAL STATE ---
List<Map<String, dynamic>> paymentHistory = [];
double totalDonationAmount = 0.0;
Set<String> unlockedBadges = {}; // Track unlocked badges

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true),
    home: EcoWasteDashboard(),
    routes: {
      '/login': (context) => Scaffold(
          appBar: AppBar(title: Text("Login")),
          body: Center(child: Text("Login Screen"))),
      '/signup': (context) => Scaffold(
          appBar: AppBar(title: Text("Sign Up")),
          body: Center(child: Text("Sign Up Screen"))),
    },
  ));
}

class EcoWasteDashboard extends StatefulWidget {
  final String userName;
  EcoWasteDashboard({this.userName = "Jennifer"});

  @override
  _EcoWasteDashboardState createState() => _EcoWasteDashboardState();
}

class _EcoWasteDashboardState extends State<EcoWasteDashboard> {
  bool isDarkMode = false;
  String displayDateTime = "May 16, 2024 • 10:00 AM";
  String pickupLocation = "Not set";
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<String> searchResults = [];
  bool isSearching = false;
  Uint8List? _scannedImageBytes;
  String? _detectedWasteType;
  bool _scanning = false;

  // Reusable Service Card
  Widget _serviceCard(String title, String sub, IconData icon, Color bg,
      Color contentColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: contentColor.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: contentColor, size: 28),
            Spacer(),
            Text(sub,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: contentColor.withOpacity(0.8))),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: contentColor)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = isDarkMode ? Color(0xFF121212) : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black;
    Color cardBgColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.grey[100]!;

    return RoleScaffold(
      screenName: 'user_dashboard',
      body: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: Icon(Icons.menu, color: textColor),
          title: Text("EcoWaste",
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: isDarkMode ? Colors.yellow : Colors.black),
              onPressed: () => setState(() => isDarkMode = !isDarkMode),
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text("Hi ${widget.userName}!",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              Text("Let's help people in need.",
                  style: TextStyle(color: Colors.blueGrey)),
              SizedBox(height: 25),
              _buildSearchBox(cardBgColor, textColor),
              SizedBox(height: 30),
              _buildDetectWasteBanner(isDarkMode),
              SizedBox(height: 35),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Services",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                AllServicesPage(isDark: isDarkMode))),
                    child: Text("View all",
                        style: TextStyle(
                            color: Color(0xFF2ECC71),
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.85,
                children: [
                  _serviceCard(
                      "Request Pickup",
                      "$displayDateTime\nLoc: $pickupLocation",
                      Icons.local_shipping,
                      Color(0xFFDCEDC8),
                      Color(0xFF33691E),
                      () => _selectPickupDateTime(context)),
                  _serviceCard(
                      "Donate Items",
                      "Dress, Food, etc",
                      Icons.volunteer_activism,
                      Color(0xFFBBDEFB),
                      Color(0xFF0D47A1),
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  DonationPage(isDark: isDarkMode)))),
                  _serviceCard(
                      "Van Tracking",
                      "Live: Tracking...",
                      Icons.my_location,
                      Color(0xFFF1F8E9),
                      Color(0xFF558B2F),
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  LiveTrackingPage(isDark: isDarkMode)))),
                  _serviceCard(
                      "Pay Bills",
                      "bKash / Nagad",
                      Icons.account_balance_wallet,
                      Color(0xFFFFECB3),
                      Color(0xFFFF6F00),
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  PaymentPage(isDark: isDarkMode)))),
                ],
              ),
              SizedBox(height: 100),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(isDarkMode),
      ),
    );
  }

  // --- Helper Widgets & Methods ---
  void _performSearch(String query) {
    List<String> allItems = [
      "Request Pickup",
      "Donate Items",
      "Van Tracking",
      "Pay Bills",
      "Detect Waste",
      "View History",
      "My Badges",
      "Dustbin Alert",
      "Live Tracking",
      "Payment History",
    ];

    setState(() {
      if (query.isEmpty) {
        searchResults = [];
        isSearching = false;
      } else {
        isSearching = true;
        searchResults = allItems
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectPickupDateTime(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Pickup'),
        content: const Text('Select a date and time for your waste pickup.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                displayDateTime = "May 16, 2024 • 10:00 AM";
              });

              // Send notification to admin
              try {
                await NotificationService().sendPickupRequestNotification(
                  userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
                  location: pickupLocation != "Not set"
                      ? pickupLocation
                      : "Location not set",
                  additionalInfo: 'Scheduled for $displayDateTime',
                );
              } catch (e) {
                print('Error sending notification: $e');
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('✓ Pickup scheduled and admin notified!')),
              );
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  void _navigateToService(String serviceName) {
    _searchController.clear();
    _performSearch("");

    switch (serviceName) {
      case "Request Pickup":
        _selectPickupDateTime(context);
        break;
      case "Donate Items":
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DonationPage(isDark: isDarkMode)));
        break;
      case "Van Tracking":
      case "Live Tracking":
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => LiveTrackingPage(isDark: isDarkMode)));
        break;
      case "Pay Bills":
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PaymentPage(isDark: isDarkMode)));
        break;
      case "Detect Waste":
        // Scan Now functionality
        break;
      case "View History":
      case "Payment History":
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PaymentHistoryPage(isDark: isDarkMode)));
        break;
      case "My Badges":
      case "Dustbin Alert":
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => BadgeRewardPage(isDark: isDarkMode)));
        break;
      default:
        break;
    }
  }

  Widget _buildSearchBox(Color bg, Color text) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
          child: TextField(
            controller: _searchController,
            onChanged: _performSearch,
            style: TextStyle(color: text),
            decoration: InputDecoration(
              icon: Icon(Icons.search, color: Colors.grey),
              hintText: "Search services...",
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _performSearch("");
                      },
                      child: Icon(Icons.clear, color: Colors.grey),
                    )
                  : null,
            ),
          ),
        ),
        if (isSearching && searchResults.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: searchResults.map((result) {
                return ListTile(
                  leading: Icon(Icons.search, color: Colors.grey, size: 18),
                  title: Text(result, style: TextStyle(color: text)),
                  onTap: () => _navigateToService(result),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Map<String, dynamic> _rgbToHsv(int r, int g, int b) {
    final rNorm = r / 255.0;
    final gNorm = g / 255.0;
    final bNorm = b / 255.0;
    final maxC = [rNorm, gNorm, bNorm].reduce((a, b) => a > b ? a : b);
    final minC = [rNorm, gNorm, bNorm].reduce((a, b) => a < b ? a : b);
    final delta = maxC - minC;

    double h = 0;
    if (delta != 0) {
      if (maxC == rNorm) {
        h = 60 * (((gNorm - bNorm) / delta) % 6);
      } else if (maxC == gNorm) {
        h = 60 * (((bNorm - rNorm) / delta) + 2);
      } else {
        h = 60 * (((rNorm - gNorm) / delta) + 4);
      }
      if (h < 0) h += 360;
    }

    final s = maxC == 0 ? 0 : (delta / maxC);
    final v = maxC;

    return {"h": h, "s": s, "v": v};
  }

  String _classifyWaste(
      List<Map<String, dynamic>> hsvSamples, double avgBrightness) {
    if (hsvSamples.isEmpty) return "❓ Unknown";

    // Calculate average HSV and count hue ranges
    double avgS = 0;
    int blueCount = 0,
        greenCount = 0,
        redCount = 0,
        brownCount = 0,
        grayCount = 0;

    for (final sample in hsvSamples) {
      avgS += sample["s"];

      final h = sample["h"];
      final s = sample["s"];
      if (s < 0.1) {
        grayCount++; // Nearly gray
      } else if ((h >= 0 && h < 30) || h >= 330) {
        redCount++;
      } else if (h >= 30 && h < 90) {
        greenCount++;
      } else if (h >= 90 && h < 150) {
        greenCount++;
      } else if (h >= 150 && h < 250) {
        blueCount++;
      } else if (h >= 250 && h < 330) {
        blueCount++;
      }
      if (h >= 20 && h < 40 && avgBrightness < 150) {
        brownCount++;
      }
    }

    avgS /= hsvSamples.length;

    // METAL/GRAY: Very low saturation, medium-high brightness
    if (grayCount > hsvSamples.length * 0.6 && avgBrightness > 120) {
      return "🔧 Metal";
    }

    // GLASS: Very high brightness, very low saturation
    if (avgBrightness > 200 && avgS < 0.15) {
      return "🥤 Glass";
    }

    // ORGANIC: Brown/dark green with some saturation
    if ((brownCount > hsvSamples.length * 0.4 ||
            greenCount > hsvSamples.length * 0.5) &&
        avgBrightness > 50 &&
        avgBrightness < 180 &&
        avgS > 0.15) {
      return "🍃 Organic";
    }

    // PAPER: Beige/cream/light brown, low saturation, high brightness
    if (avgBrightness > 180 && avgS < 0.2 && avgS > 0) {
      return "📄 Paper";
    }

    // RECYCLABLE: Pure bright blue or bright green (recycling colors)
    if ((blueCount > hsvSamples.length * 0.6 &&
            avgBrightness > 120 &&
            avgS > 0.3) ||
        (greenCount > hsvSamples.length * 0.6 &&
            avgBrightness > 140 &&
            avgS > 0.3)) {
      return "♻️ Recyclable";
    }

    // PLASTIC: Medium brightness, medium-high saturation, varied colors
    if (avgBrightness > 70 && avgBrightness < 200 && avgS > 0.2 && avgS < 0.8) {
      if (redCount > hsvSamples.length * 0.5) return "🔴 Plastic";
      if (blueCount > hsvSamples.length * 0.5) return "🔵 Plastic";
      if (greenCount > hsvSamples.length * 0.5) return "🟢 Plastic";
      return "🟡 Plastic";
    }

    // DARK PLASTIC: Low brightness, visible color
    if (avgBrightness < 120 && avgS > 0.15 && avgS < 0.7) {
      return "🟤 Plastic (Dark)";
    }

    return "❓ Unknown";
  }

  Future<String> _classifyImageBytes(Uint8List bytes) async {
    try {
      final decoded = img.decodeImage(bytes);
      String label = "Unknown";

      if (decoded != null) {
        int w = decoded.width;
        int h = decoded.height;

        // Sample multiple regions for robustness
        List<Map<String, dynamic>> allHsvSamples = [];
        double totalRGB = 0;
        int sampleCount = 0;

        // Analyze 4 regions: center and corners
        List<List<int>> regions = [
          [
            (w * 0.2).round(),
            (h * 0.2).round(),
            (w * 0.6).round(),
            (h * 0.6).round()
          ], // center
          [0, 0, (w * 0.4).round(), (h * 0.4).round()], // top-left
          [(w * 0.6).round(), 0, w, (h * 0.4).round()], // top-right
          [0, (h * 0.6).round(), (w * 0.4).round(), h], // bottom-left
        ];

        for (final region in regions) {
          int x1 = region[0], y1 = region[1], x2 = region[2], y2 = region[3];
          int step = 1;
          int pixelCount = ((x2 - x1) * (y2 - y1)) ~/ (step * step);
          if (pixelCount > 5000) step = (pow(pixelCount / 5000, 0.5)).round();

          for (int y = y1; y < y2; y += step) {
            for (int x = x1; x < x2; x += step) {
              final pixel = decoded.getPixelSafe(x, y);
              final pr = (pixel.r).toInt();
              final pg = (pixel.g).toInt();
              final pb = (pixel.b).toInt();

              // Skip very dark pixels (shadows)
              if (pr + pg + pb < 40) continue;

              final hsv = _rgbToHsv(pr, pg, pb);
              allHsvSamples.add(hsv);
              totalRGB += (pr + pg + pb).toDouble();
              sampleCount++;
            }
          }
        }

        if (allHsvSamples.isNotEmpty) {
          final avgBrightness = (totalRGB / (sampleCount * 3)).round();
          label = _classifyWaste(allHsvSamples, avgBrightness.toDouble());
        }
      }

      return label;
    } catch (e) {
      return "Error";
    }
  }

  Future<void> _scanWaste() async {
    try {
      setState(() => _scanning = true);
      final XFile? picked = await ImagePicker()
          .pickImage(source: ImageSource.camera, maxWidth: 1024);
      if (picked == null) {
        setState(() => _scanning = false);
        return;
      }

      final bytes = await picked.readAsBytes();
      final label = await _classifyImageBytes(bytes);

      setState(() {
        _scannedImageBytes = bytes;
        _detectedWasteType = label;
        _scanning = false;
      });
    } catch (e) {
      setState(() => _scanning = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Scan failed: $e')));
    }
  }

  Future<void> _startMultiScanFlow() async {
    // Ask user whether to single scan or multi-scan
    final choice = await showDialog<String?>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Choose Scan Mode'),
        children: [
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'single'),
              child: Text('Single Scan')),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'multi'),
              child: Text('Multi Scan (Plastic, Metal, Organic)')),
        ],
      ),
    );

    if (choice == null) return;
    if (choice == 'single') return _scanWaste();

    // Multi-scan flow
    final typesToCapture = ['Plastic', 'Metal', 'Organic'];
    List<Map<String, dynamic>> results = [];

    for (final t in typesToCapture) {
      // Prompt user
      final proceed = await showDialog<bool?>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Capture $t'),
          content: Text('Please take a photo of the item you think is $t.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Skip')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Open Camera')),
          ],
        ),
      );

      if (proceed != true) continue;

      setState(() => _scanning = true);
      final XFile? picked = await ImagePicker()
          .pickImage(source: ImageSource.camera, maxWidth: 1024);
      if (picked == null) {
        setState(() => _scanning = false);
        continue;
      }

      final bytes = await picked.readAsBytes();
      final detected = await _classifyImageBytes(bytes);
      results.add({'typeRequested': t, 'detected': detected, 'bytes': bytes});

      setState(() {
        _scannedImageBytes = bytes;
        _detectedWasteType = detected;
        _scanning = false;
      });
    }

    if (results.isEmpty) return;

    // Show summary
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Scan Results'),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: results.map((r) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(r['bytes'],
                              width: 72, height: 72, fit: BoxFit.cover)),
                      SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Requested: ${r['typeRequested']}'),
                            Text('Detected: ${r['detected']}',
                                style: TextStyle(fontWeight: FontWeight.bold))
                          ])),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Close'))
        ],
      ),
    );
  }

  Widget _buildDetectWasteBanner(bool dark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: dark ? Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text("Detect Waste",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: dark ? Colors.white : Colors.black)),
                  Text("Scan to recycle.",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ])),
            Icon(Icons.qr_code_scanner,
                size: 40, color: Color(0xFF2ECC71).withOpacity(0.6))
          ]),
          SizedBox(height: 12),
          Row(children: [
            ElevatedButton.icon(
              onPressed: _scanning ? null : () => _startMultiScanFlow(),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFF2ECC71)),
              icon: _scanning
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Icon(Icons.camera_alt, color: Colors.white),
              label: Text(_scanning ? 'Scanning...' : 'Scan Now',
                  style: TextStyle(color: Colors.white)),
            ),
            SizedBox(width: 12),
            if (_detectedWasteType != null)
              Chip(
                  label: Text(_detectedWasteType!,
                      style:
                          TextStyle(color: dark ? Colors.white : Colors.black)),
                  backgroundColor: dark ? Colors.grey[800] : Colors.grey[200])
          ]),
          if (_scannedImageBytes != null) ...[
            SizedBox(height: 12),
            ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_scannedImageBytes!,
                    height: 160, width: double.infinity, fit: BoxFit.cover)),
            SizedBox(height: 8),
            Text('Detected: ${_detectedWasteType ?? "Unknown"}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: dark ? Colors.white : Colors.black)),
          ]
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool dark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, "Home", Color(0xFF2ECC71), () {}),
          _buildNavItem(
              Icons.apps,
              "Services",
              Colors.blue,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AllServicesPage(isDark: dark)))),
          _buildNavItem(Icons.local_shipping, "Pickup", Colors.orange,
              () => _selectPickupDateTime(context)),
          _buildNavItem(
              Icons.emoji_events,
              "Badges",
              Colors.purple,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BadgeRewardPage(isDark: dark)))),
          _buildNavItem(
              Icons.notifications,
              "Alert",
              Colors.red,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DustbinAlertPage(isDark: dark)))),
          _buildNavItem(
              Icons.history,
              "History",
              Colors.teal,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PaymentHistoryPage(isDark: dark)))),
          _buildNavItem(Icons.person_outline, "Profile", Colors.indigo,
              () => _showProfileDialog()),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: const Text('Profile options will be available here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
