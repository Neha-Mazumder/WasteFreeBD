import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EcoWasteDashboard extends StatefulWidget {
  final String userName;
  EcoWasteDashboard({this.userName = "Jennifer"});

  @override
  _EcoWasteDashboardState createState() => _EcoWasteDashboardState();
}

class _EcoWasteDashboardState extends State<EcoWasteDashboard> {
  bool isDarkMode = false;
  String displayDateTime = "May 16, 2024 • 10:00 AM";
  String pickupStatus = "Scheduling...";

  Future<void> _selectPickupDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          String datePart = DateFormat('MMM dd, yyyy').format(pickedDate);
          String timePart = pickedTime.format(context);
          displayDateTime = "$datePart • $timePart";
          pickupStatus = "Requested";
        });
      }
    }
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
        leading: Icon(Icons.menu, color: textColor),
        title: Text("EcoWaste",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: GestureDetector(
              onTap: () => setState(() => isDarkMode = !isDarkMode),
              child: CircleAvatar(
                backgroundColor: isDarkMode ? Colors.yellow : Colors.grey[400],
                child: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    size: 20, color: isDarkMode ? Colors.black : Colors.white),
              ),
            ),
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
            Text("Let's make the world cleaner today.",
                style: TextStyle(color: Colors.blueGrey)),
            SizedBox(height: 25),
            _buildSearchBox(cardBgColor, textColor),
            SizedBox(height: 30),
            _buildDetectWasteBanner(isDarkMode),
            SizedBox(height: 35),

            // --- View all Logic Update ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Services",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              AllServicesPage(isDark: isDarkMode)),
                    );
                  },
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
                GestureDetector(
                  onTap: () => _selectPickupDateTime(context),
                  child: _serviceCard("Request Pickup", displayDateTime,
                      Icons.local_shipping, Color(0xFF2ECC71), true,
                      status: pickupStatus),
                ),
                _serviceCard(
                    "Donate Items",
                    "Always open",
                    Icons.volunteer_activism,
                    isDarkMode ? cardBgColor : Colors.white,
                    false,
                    txtColor: textColor),
                _serviceCard("Pay Bills", "Bills", Icons.account_balance_wallet,
                    isDarkMode ? cardBgColor : Colors.white, false,
                    txtColor: textColor),
                _serviceCard("Review Past", "Review", Icons.history,
                    isDarkMode ? cardBgColor : Colors.white, false,
                    txtColor: textColor),
              ],
            ),
            SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Color(0xFF2ECC71),
        child: Icon(Icons.add, color: Colors.white, size: 30),
        shape: CircleBorder(),
      ),
      bottomNavigationBar: _buildBottomBar(context, isDarkMode),
    );
  }

  Widget _serviceCard(
      String title, String sub, IconData icon, Color bg, bool isFullGreen,
      {Color txtColor = Colors.black, String status = ""}) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(25),
        border: isFullGreen ? null : Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isFullGreen ? Colors.white : Color(0xFF2ECC71)),
          Spacer(),
          Text(sub,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isFullGreen ? Colors.white : Colors.grey[800])),
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color:
                      isFullGreen ? Colors.white.withOpacity(0.9) : txtColor)),
          if (status.isNotEmpty)
            Text(status,
                style: TextStyle(
                    fontSize: 10,
                    color: isFullGreen ? Colors.white70 : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSearchBox(Color bg, Color text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: TextField(
        style: TextStyle(color: text),
        decoration: InputDecoration(
            icon: Icon(Icons.search, color: Colors.grey),
            hintText: "Search for pickups...",
            border: InputBorder.none),
      ),
    );
  }

  Widget _buildDetectWasteBanner(bool dark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: dark ? Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)
          ]),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Detect Waste",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.white : Colors.black)),
          Text("Unsure if it's recyclable?",
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          SizedBox(height: 15),
          ElevatedButton(
              onPressed: () {},
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFF2ECC71)),
              child: Text("Scan Now", style: TextStyle(color: Colors.white)))
        ])),
        Icon(Icons.qr_code_scanner,
            size: 60, color: Color(0xFF2ECC71).withOpacity(0.3))
      ]),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool dark) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      notchMargin: 8,
      color: dark ? Color(0xFF1E1E1E) : Colors.white,
      child: Container(
          height: 60,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            Icon(Icons.home, color: Color(0xFF2ECC71)),
            Icon(Icons.wallet, color: Colors.grey),
            SizedBox(width: 40),
            Icon(Icons.history, color: Colors.grey),
            IconButton(
                icon: Icon(Icons.person_outline, color: Colors.grey),
                onPressed: () => _showLoginOptions(context))
          ])),
    );
  }

  void _showLoginOptions(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  leading: Icon(Icons.login),
                  title: Text("Login"),
                  onTap: () => Navigator.pushNamed(context, '/login')),
              ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text("Sign Up"),
                  onTap: () => Navigator.pushNamed(context, '/signup'))
            ]));
  }
}

// --- Notun Screen: View All er jonno (Live Location shoho) ---
class AllServicesPage extends StatelessWidget {
  final bool isDark;
  AllServicesPage({required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color bg = isDark ? Color(0xFF121212) : Colors.white;
    Color txt = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: txt),
        title: Text("Additional Services", style: TextStyle(color: txt)),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          _buildListTile(
              "Live Van Tracking",
              "Track the waste collection van live",
              Icons.map,
              Colors.orange,
              isDark),
          _buildListTile("Recycling Centers", "Find nearby drop-off points",
              Icons.business, Colors.blue, isDark),
          _buildListTile("Waste Reports", "Check your monthly waste stats",
              Icons.bar_chart, Colors.purple, isDark),
        ],
      ),
    );
  }

  Widget _buildListTile(String t, String s, IconData i, Color c, bool dark) {
    return Card(
      color: dark ? Color(0xFF1E1E1E) : Colors.white,
      margin: EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: c.withOpacity(0.2), child: Icon(i, color: c)),
        title: Text(t,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: dark ? Colors.white : Colors.black)),
        subtitle: Text(s, style: TextStyle(color: Colors.grey)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}
