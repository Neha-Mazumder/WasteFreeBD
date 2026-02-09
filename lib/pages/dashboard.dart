import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// using flutter_map + latlong2 instead of google_maps_flutter to avoid Google JS key requirement on web
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart'; // এর জন্য Geolocator এরর চলে যাবে
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:wastefreebd/services/notification_service.dart';
import 'dart:typed_data';
import 'donation.dart';
import 'payment.dart';
import 'payment_history.dart';
import 'user_profile_page.dart';

// --- GLOBAL STATE ---
List<Map<String, dynamic>> paymentHistory = [];
double totalDonationAmount = 0.0;
Set<String> unlockedBadges = {}; // Track unlocked badges

Map<String, dynamic> _getDonationBadges() {
  return {
    "gold": {
      "threshold": 10000,
      "earned": totalDonationAmount >= 10000,
      "color": Color(0xFFFFD700),
      "reward": "🎁 ৳5,000 Discount Voucher + VIP Status"
    },
    "silver": {
      "threshold": 5000,
      "earned": totalDonationAmount >= 5000,
      "color": Color(0xFFC0C0C0),
      "reward": "🎁 ৳2,500 Discount Voucher"
    },
    "bronze": {
      "threshold": 1000,
      "earned": totalDonationAmount >= 1000,
      "color": Color(0xFFCD7F32),
      "reward": "🎁 ৳500 Discount Voucher + Certificate"
    },
  };
}

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
  EcoWasteDashboard({this.userName = "User"});

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon on the left
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: contentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: contentColor, size: 40),
            ),
            SizedBox(width: 15),
            // Text content
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: contentColor)),
                  SizedBox(height: 3),
                  Text(sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          color: contentColor.withOpacity(0.8))),
                ],
              ),
            ),
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text("Waste-Free BD",
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
            Text("Turn Trash into Treasure",
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
              childAspectRatio: 2,
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
        int totalRGB = 0, sampleCount = 0;

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
              totalRGB += (pr + pg + pb);
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
    List<Map<String, dynamic>> navItems = [
      {
        "icon": Icons.home,
        "label": "Home",
        "color": Color(0xFF2ECC71),
        "action": () {}
      },
      {
        "icon": Icons.apps,
        "label": "Services",
        "color": Colors.blue,
        "action": () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AllServicesPage(isDark: dark)))
      },
      {
        "icon": Icons.local_shipping,
        "label": "Pickup",
        "color": Colors.orange,
        "action": () => _selectPickupDateTime(context)
      },
      {
        "icon": Icons.emoji_events,
        "label": "Badges",
        "color": Colors.purple,
        "action": () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => BadgeRewardPage(isDark: dark)))
      },
      {
        "icon": Icons.notifications,
        "label": "Alert",
        "color": Colors.red,
        "action": () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DustbinAlertPage(isDark: dark)))
      },
      {
        "icon": Icons.history,
        "label": "History",
        "color": Colors.teal,
        "action": () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PaymentHistoryPage(isDark: dark)))
      },
      {
        "icon": Icons.person_outline,
        "label": "Profile",
        "color": Colors.indigo,
        "action": () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => UserProfilePage(isDark: dark)))
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: dark ? Color(0xFF1E1E1E) : Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2))
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(navItems.length, (index) {
            final item = navItems[index];
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: item["action"],
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: index == 0
                        ? item["color"].withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: index == 0 ? item["color"] : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item["icon"],
                        color: index == 0 ? item["color"] : Colors.grey,
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Text(
                        item["label"],
                        style: TextStyle(
                          color: index == 0 ? item["color"] : Colors.grey,
                          fontSize: 12,
                          fontWeight:
                              index == 0 ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // Unused method - kept for future use
  // ignore: unused_element
  void _showLoginOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10),
          Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10))),
          ListTile(
              leading: Icon(Icons.login, color: Color(0xFF2ECC71)),
              title: Text("Login"),
              onTap: () => Navigator.pushNamed(context, '/login')),
          ListTile(
              leading: Icon(Icons.person_add, color: Color(0xFF2ECC71)),
              title: Text("Sign Up"),
              onTap: () => Navigator.pushNamed(context, '/signup')),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _selectPickupDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2030));
    if (pickedDate != null) {
      final TimeOfDay? pickedTime =
          await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (pickedTime != null)
        _showLocationDialog(context, pickedDate, pickedTime);
    }
  }

  void _showLocationDialog(
      BuildContext context, DateTime date, TimeOfDay time) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
        title: Text("Add Pickup Location"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: "Enter address",
                prefixIcon: Icon(Icons.location_on, color: Color(0xFF2ECC71)),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final selectedLocation = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        LocationPickerPage(isDark: isDarkMode),
                  ),
                );
                if (selectedLocation != null) {
                  _locationController.text =
                      selectedLocation['address'] ?? 'Selected Location';
                  _showLocationDialog(context, date, time);
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFF2ECC71)),
              icon: Icon(Icons.map, color: Colors.white),
              label:
                  Text("Pick from Map", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2ECC71)),
            onPressed: () {
              setState(() {
                displayDateTime =
                    "${DateFormat('MMM dd, yyyy').format(date)} • ${time.format(context)}";
                pickupLocation = _locationController.text.isNotEmpty
                    ? _locationController.text
                    : "Current Location";
              });
              Navigator.pop(context);
            },
            child: Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// --- LIVE TRACKING PAGE ---
class LiveTrackingPage extends StatefulWidget {
  final bool isDark;
  LiveTrackingPage({required this.isDark});

  @override
  _LiveTrackingPageState createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  ll.LatLng _currentPosition = ll.LatLng(23.8103, 90.4125);
  bool _loading = true;
  String? _errorMessage;
  bool _permissionDenied = false;
  StreamSubscription<Position>? _positionStream;
  // FlutterMap controller (used on all platforms now)
  final MapController _fmController = MapController();

  @override
  void initState() {
    super.initState();
    _checkPermissionAndStartTracking();
  }

  Future<void> _checkPermissionAndStartTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled.';
          _loading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _permissionDenied = true;
            _errorMessage =
                'Location permission denied. Please allow location access.';
            _loading = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _permissionDenied = true;
          _errorMessage =
              'Location permission permanently denied. Enable it from settings.';
          _loading = false;
        });
        return;
      }

      // get current position as a starting point
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentPosition = ll.LatLng(pos.latitude, pos.longitude);
          _loading = false;
        });
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 5),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = ll.LatLng(position.latitude, position.longitude);
          });
          _moveCamera(position);
        }
      }, onError: (err) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error receiving location updates: $err';
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not get location: $e';
        _loading = false;
      });
    }
  }

  Future<void> _moveCamera(Position position) async {
    try {
      _fmController.move(
          ll.LatLng(position.latitude, position.longitude), 16.0);
    } catch (_) {}
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyWidget;
    if (_loading) {
      bodyWidget =
          Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
    } else if (_errorMessage != null) {
      bodyWidget = Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _errorMessage = null;
                  });
                  _checkPermissionAndStartTracking();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2ECC71)),
                child:
                    Text(_permissionDenied ? 'Open Settings / Retry' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    } else {
      // Always render FlutterMap (OpenStreetMap) to avoid needing Google Maps JS API
      bodyWidget = Stack(
        children: [
          FlutterMap(
            mapController: _fmController,
            options: MapOptions(
              initialCenter: ll.LatLng(
                  _currentPosition.latitude, _currentPosition.longitude),
              initialZoom: 15.0,
              maxZoom: 18.0,
              minZoom: 1.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.waste_free',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: ll.LatLng(_currentPosition.latitude + 0.001,
                        _currentPosition.longitude + 0.001),
                    width: 40,
                    height: 40,
                    child: Icon(Icons.local_shipping,
                        color: Colors.blueAccent, size: 30),
                  ),
                  Marker(
                    point: ll.LatLng(
                        _currentPosition.latitude, _currentPosition.longitude),
                    width: 36,
                    height: 36,
                    child: Icon(Icons.person_pin_circle,
                        color: Colors.redAccent, size: 36),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                _fmController.move(
                  ll.LatLng(
                      _currentPosition.latitude, _currentPosition.longitude),
                  15.0,
                );
              },
              backgroundColor: Color(0xFF2ECC71),
              child: Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Live Van Tracking"),
        backgroundColor: widget.isDark ? Color(0xFF121212) : Colors.white,
        foregroundColor: widget.isDark ? Colors.white : Colors.black,
      ),
      body: bodyWidget,
    );
  }
}

// --- ALL SERVICES PAGE ---
class AllServicesPage extends StatefulWidget {
  final bool isDark;
  AllServicesPage({required this.isDark});

  @override
  _AllServicesPageState createState() => _AllServicesPageState();
}

class _AllServicesPageState extends State<AllServicesPage> {
  @override
  Widget build(BuildContext context) {
    Color bg = widget.isDark ? Color(0xFF121212) : Colors.white;
    Color txt = widget.isDark ? Colors.white : Colors.black;

    List<Map<String, dynamic>> services = [
      {
        "title": "Request Pickup",
        "sub": "Schedule timing",
        "icon": Icons.local_shipping,
        "bg": Color(0xFFDCEDC8),
        "color": Color(0xFF33691E),
        "action": () => Navigator.pop(context),
      },
      {
        "title": "Donate Items",
        "sub": "Dress, Food, etc",
        "icon": Icons.volunteer_activism,
        "bg": Color(0xFFBBDEFB),
        "color": Color(0xFF0D47A1),
        "action": () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DonationPage(isDark: widget.isDark))),
      },
      {
        "title": "Van Tracking",
        "sub": "Live Location",
        "icon": Icons.my_location,
        "bg": Color(0xFFF1F8E9),
        "color": Color(0xFF558B2F),
        "action": () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => LiveTrackingPage(isDark: widget.isDark))),
      },
      {
        "title": "Payment",
        "sub": "bKash / Nagad",
        "icon": Icons.account_balance_wallet,
        "bg": Color(0xFFFFECB3),
        "color": Color(0xFFFF6F00),
        "action": () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PaymentPage(isDark: widget.isDark))),
      },
      {
        "title": "Dustbin Alert",
        "sub": "When full!",
        "icon": Icons.warning_amber_rounded,
        "bg": Color(0xFFFFE0B2),
        "color": Color(0xFFE65100),
        "action": () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DustbinAlertPage(isDark: widget.isDark))),
      },
      {
        "title": "Earn Badges",
        "sub": "Rewards & Points",
        "icon": Icons.emoji_events,
        "bg": Color(0xFFE8D7F1),
        "color": Color(0xFF6A1B9A),
        "action": () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => BadgeRewardPage(isDark: widget.isDark))),
      },
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text("All Services", style: TextStyle(color: txt)),
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: txt),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 2,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return _buildGridCard(
              service["title"],
              service["sub"],
              service["icon"],
              service["bg"],
              service["color"],
              service["action"],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGridCard(String title, String sub, IconData icon, Color bg,
      Color contentColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(25)),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: contentColor, size: 28),
                Spacer(),
                Text(sub,
                    style: TextStyle(
                        fontSize: 10, color: contentColor.withOpacity(0.8))),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: contentColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- LOCATION PICKER PAGE ---
class LocationPickerPage extends StatefulWidget {
  final bool isDark;
  LocationPickerPage({required this.isDark});

  @override
  _LocationPickerPageState createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late ll.LatLng _selectedLocation;
  final MapController _mapController = MapController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _selectedLocation = ll.LatLng(23.8103, 90.4125); // Dhaka default
        setState(() => _loading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _selectedLocation = ll.LatLng(23.8103, 90.4125); // Dhaka default
      } else {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        _selectedLocation = ll.LatLng(pos.latitude, pos.longitude);
      }

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      _selectedLocation = ll.LatLng(23.8103, 90.4125); // Dhaka default
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Pickup Location"),
        backgroundColor: widget.isDark ? Color(0xFF121212) : Colors.white,
        foregroundColor: widget.isDark ? Colors.white : Colors.black,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 15.0,
                    maxZoom: 18.0,
                    minZoom: 1.0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.waste_free',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
                          width: 40,
                          height: 40,
                          child: Icon(Icons.location_on,
                              color: Color(0xFF2ECC71), size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1), blurRadius: 8)
                      ],
                    ),
                    child: Text(
                      "Tap on map to select location",
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: () {
                      _mapController.move(_selectedLocation, 15.0);
                    },
                    backgroundColor: Color(0xFF2ECC71),
                    child: Icon(Icons.my_location, color: Colors.white),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, {
                        'latitude': _selectedLocation.latitude,
                        'longitude': _selectedLocation.longitude,
                        'address':
                            '${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}',
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2ECC71),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: Icon(Icons.check, color: Colors.white),
                    label: Text("Confirm Location",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
    );
  }
}

// --- DUSTBIN ALERT PAGE ---
class DustbinAlertPage extends StatefulWidget {
  final bool isDark;
  DustbinAlertPage({required this.isDark});

  @override
  _DustbinAlertPageState createState() => _DustbinAlertPageState();
}

class _DustbinAlertPageState extends State<DustbinAlertPage> {
  bool _isFull = false;
  String _alertMessage = "Your dustbin is not full yet";
  int _fillPercentage = 40;

  Future<void> _sendAlert() async {
    if (_isFull) {
      try {
        // Send notification to admin
        await NotificationService().sendDustbinFullAlert(
          dustbinId: 'db_${DateTime.now().millisecondsSinceEpoch}',
          location: 'User Location',
          fillPercentage: _fillPercentage.toDouble(),
        );

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: widget.isDark ? Color(0xFF1E1E1E) : Colors.white,
            icon: Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 60),
            title: Text("Alert Sent!",
                style: TextStyle(
                    color: Color(0xFF2ECC71), fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Dustbin full alert sent to EcoWaste",
                    textAlign: TextAlign.center),
                SizedBox(height: 12),
                Text("Our van will pick up soon!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2ECC71)),
                onPressed: () => Navigator.pop(context),
                child: Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send alert: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Dustbin is not full yet!"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dustbin Full Alert"),
        backgroundColor: widget.isDark ? Color(0xFF121212) : Colors.white,
        foregroundColor: widget.isDark ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dustbin Status Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.isDark ? Color(0xFF1E1E1E) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1), blurRadius: 8)
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 80, color: _isFull ? Colors.orange : Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      _alertMessage,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    // Capacity Indicator
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Capacity",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("$_fillPercentage%",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2ECC71))),
                          ],
                        ),
                        SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _fillPercentage / 100,
                            minHeight: 12,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation(
                                _isFull ? Colors.orange : Color(0xFF2ECC71)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Fill Level Slider
              Text("Adjust Fill Level",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Slider(
                value: _fillPercentage.toDouble(),
                min: 0,
                max: 100,
                divisions: 10,
                activeColor:
                    _fillPercentage >= 80 ? Colors.orange : Color(0xFF2ECC71),
                label: "$_fillPercentage%",
                onChanged: (value) {
                  setState(() {
                    _fillPercentage = value.toInt();
                    _isFull = _fillPercentage >= 80;
                    _alertMessage = _isFull
                        ? "Your dustbin is FULL! Send alert to pickup."
                        : "Your dustbin is at $_fillPercentage% capacity";
                  });
                },
              ),
              SizedBox(height: 40),

              // Send Alert Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendAlert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFull ? Colors.orange : Colors.grey,
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(Icons.warning_amber_rounded, color: Colors.white),
                  label: Text(
                    _isFull ? "SEND DUSTBIN FULL ALERT" : "Dustbin Not Full",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Info Card
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Color(0xFFFFE0B2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFE65100), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Color(0xFFE65100)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Slide to 80%+ to enable alert button",
                        style: TextStyle(
                            color: Color(0xFFE65100),
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- BADGE REWARD PAGE ---
class BadgeRewardPage extends StatefulWidget {
  final bool isDark;
  BadgeRewardPage({required this.isDark});

  @override
  _BadgeRewardPageState createState() => _BadgeRewardPageState();
}

class _BadgeRewardPageState extends State<BadgeRewardPage> {
  @override
  Widget build(BuildContext context) {
    final donationBadges = _getDonationBadges();
    final goldEarned = donationBadges["gold"]["earned"];
    final silverEarned = donationBadges["silver"]["earned"];
    final bronzeEarned = donationBadges["bronze"]["earned"];

    int totalEarned =
        (goldEarned ? 1 : 0) + (silverEarned ? 1 : 0) + (bronzeEarned ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: Text("Donation Badges & Rewards"),
        backgroundColor: widget.isDark ? Color(0xFF121212) : Colors.white,
        foregroundColor: widget.isDark ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          "$totalEarned",
                          style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        Text("Badges Earned",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          "৳${totalDonationAmount.toStringAsFixed(0)}",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        Text("Total Donated",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              Text("Donation Badges",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.white : Colors.black)),
              SizedBox(height: 20),

              // Gold Badge
              _buildDonationBadgeCard(
                emoji: "🏆",
                name: "Gold Badge",
                target:
                    "৳${donationBadges['gold']['threshold'].toStringAsFixed(0)} Donated",
                current: totalDonationAmount,
                earned: goldEarned,
                reward: donationBadges["gold"]["reward"],
                color: donationBadges["gold"]["color"],
                isDark: widget.isDark,
              ),
              SizedBox(height: 15),

              // Silver Badge
              _buildDonationBadgeCard(
                emoji: "🥈",
                name: "Silver Badge",
                target:
                    "৳${donationBadges['silver']['threshold'].toStringAsFixed(0)} Donated",
                current: totalDonationAmount,
                earned: silverEarned,
                reward: donationBadges["silver"]["reward"],
                color: donationBadges["silver"]["color"],
                isDark: widget.isDark,
              ),
              SizedBox(height: 15),

              // Bronze Badge
              _buildDonationBadgeCard(
                emoji: "🥉",
                name: "Bronze Badge",
                target:
                    "৳${donationBadges['bronze']['threshold'].toStringAsFixed(0)} Donated",
                current: totalDonationAmount,
                earned: bronzeEarned,
                reward: donationBadges["bronze"]["reward"],
                color: donationBadges["bronze"]["color"],
                isDark: widget.isDark,
              ),
              SizedBox(height: 30),

              // Progress Info
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: widget.isDark ? Color(0xFF1E1E1E) : Color(0xFFE8D7F1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF6A1B9A), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🎁 How to Earn Badges",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A1B9A),
                          fontSize: 14),
                    ),
                    SizedBox(height: 12),
                    _rewardInfo(
                        "✓ Donate ৳1,000 to earn Bronze Badge", widget.isDark),
                    _rewardInfo(
                        "✓ Donate ৳5,000 to earn Silver Badge", widget.isDark),
                    _rewardInfo(
                        "✓ Donate ৳10,000 to earn Gold Badge", widget.isDark),
                    _rewardInfo(
                        "✓ Badges unlock exclusive rewards & recognition!",
                        widget.isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonationBadgeCard({
    required String emoji,
    required String name,
    required String target,
    required double current,
    required bool earned,
    required String reward,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: earned
            ? color.withOpacity(0.2)
            : (isDark ? Color(0xFF1E1E1E) : Colors.grey[100]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: earned ? color : Colors.grey[400]!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 48)),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: earned
                            ? color
                            : (isDark ? Colors.grey : Colors.grey[600]),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      target,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: (current /
                                (name.contains("Gold")
                                    ? 10000
                                    : name.contains("Silver")
                                        ? 5000
                                        : 1000))
                            .clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              if (earned)
                Container(
                  padding: EdgeInsets.all(8),
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(Icons.check, color: Colors.white, size: 20),
                ),
            ],
          ),
          if (earned) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.card_giftcard, size: 18, color: color),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reward,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rewardInfo(String text, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey[300] : Colors.grey[700],
        ),
      ),
    );
  }
}

// --- REST OF YOUR CLASSES (DonationPage, ItemDonationPage, FoodDonationPage, PaymentPage, PaymentHistoryPage) ---
// Note: Please keep your existing Donation, Item, Food, and Payment classes below this line as you wrote them.


// --- REST OF YOUR CLASSES (DonationPage, ItemDonationPage, FoodDonationPage, PaymentPage, PaymentHistoryPage) ---
// Note: Please keep your existing Donation, Item, Food, and Payment classes below this line as you wrote them.