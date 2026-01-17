import 'package:flutter/material.dart';
import '../services/payment_store.dart';
import 'dashboard.dart';

class PaymentPage extends StatefulWidget {
  final bool isDark;
  PaymentPage({required this.isDark});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedMethod = "bKash";
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Color bg = widget.isDark ? Color(0xFF121212) : Colors.white;
    Color txt = widget.isDark ? Colors.white : Colors.black;
    Color cardBg = widget.isDark ? Color(0xFF2A2A2A) : Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text("Pay Bills", style: TextStyle(color: txt)),
        backgroundColor: bg,
        foregroundColor: txt,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bill Summary Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFFFECB3),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Color(0xFFFF6F00).withOpacity(0.2), blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Current Bill", style: TextStyle(fontSize: 14, color: Color(0xFFFF6F00), fontWeight: FontWeight.w500)),
                    SizedBox(height: 10),
                    Text("৳ 2,500", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFFFF6F00))),
                    SizedBox(height: 10),
                    Text("Due Date: Jan 15, 2025", style: TextStyle(fontSize: 12, color: Color(0xFFFF6F00).withOpacity(0.8))),
                    SizedBox(height: 5),
                    Text("Status: Pending", style: TextStyle(fontSize: 12, color: Color(0xFFFF6F00).withOpacity(0.8))),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Payment Method Selection
              Text("Select Payment Method", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: txt)),
              SizedBox(height: 15),
              _buildPaymentMethodCard("bKash", "📱 bKash Mobile Wallet", Color(0xFFFF6F00), selectedMethod == "bKash"),
              SizedBox(height: 12),
              _buildPaymentMethodCard("Nagad", "💳 Nagad Mobile Banking", Color(0xFF7C3AED), selectedMethod == "Nagad"),
              SizedBox(height: 30),

              // Amount Input
              Text("Enter Amount", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: txt)),
              SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: txt),
                decoration: InputDecoration(
                  hintText: "Amount in Taka (৳)",
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixText: "৳ ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              SizedBox(height: 20),

              // Phone Number Input
              Text("Phone Number", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: txt)),
              SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: txt),
                decoration: InputDecoration(
                  hintText: "01XXXXXXXXX",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              SizedBox(height: 30),

              // Payment Summary
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Amount", style: TextStyle(color: Colors.grey)),
                        Text(_amountController.text.isEmpty ? "৳ 0" : "৳ ${_amountController.text}", style: TextStyle(color: txt, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Processing Fee", style: TextStyle(color: Colors.grey)),
                        Text("৳ 10", style: TextStyle(color: txt, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total", style: TextStyle(color: txt, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(_amountController.text.isEmpty ? "৳ 10" : "৳ ${(int.tryParse(_amountController.text) ?? 0) + 10}", style: TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Pay Now Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2ECC71),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _amountController.text.isEmpty || _phoneController.text.isEmpty
                      ? null
                      : () => _showPaymentConfirmation(context),
                  child: Text(
                    "Pay Now",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(String method, String title, Color color, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = method;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : (widget.isDark ? Color(0xFF2A2A2A) : Color(0xFFF5F5F5)),
          border: Border.all(color: isSelected ? color : Colors.grey.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: widget.isDark ? Colors.white : Colors.black)),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _checkNewBadgesAndGetInfo() {
    // Check each badge tier
    Map<String, dynamic> badgeInfo = {"found": false, "name": "", "emoji": "", "reward": ""};
    
    // Bronze badge
    if (totalDonationAmount >= 1000 && !unlockedBadges.contains("bronze")) {
      unlockedBadges.add("bronze");
      badgeInfo = {
        "found": true,
        "name": "Bronze Badge",
        "emoji": "🥉",
        "reward": "🎁 ৳500 Discount Voucher + Certificate"
      };
    }
    // Silver badge
    else if (totalDonationAmount >= 5000 && !unlockedBadges.contains("silver")) {
      unlockedBadges.add("silver");
      badgeInfo = {
        "found": true,
        "name": "Silver Badge",
        "emoji": "🥈",
        "reward": "🎁 ৳2,500 Discount Voucher"
      };
    }
    // Gold badge
    else if (totalDonationAmount >= 10000 && !unlockedBadges.contains("gold")) {
      unlockedBadges.add("gold");
      badgeInfo = {
        "found": true,
        "name": "Gold Badge",
        "emoji": "🏆",
        "reward": "🎁 ৳5,000 Discount Voucher + VIP Status"
      };
    }
    
    return badgeInfo;
  }

  void _showBadgeCelebration(BuildContext context) {
    final badges = _checkNewBadgesAndGetInfo();
    
    if (!badges["found"]) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDark ? Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Column(
            children: [
              Text(badges["emoji"], style: TextStyle(fontSize: 60)),
              SizedBox(height: 12),
              Text(
                "🎉 Badge Unlocked!",
                style: TextStyle(
                  color: Color(0xFF2ECC71),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              badges["name"],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF2ECC71).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Reward:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: widget.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    badges["reward"],
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2ECC71),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2ECC71)),
            onPressed: () => Navigator.pop(context),
            child: Text(
              "View Badge",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDark ? Color(0xFF2A2A2A) : Colors.white,
        title: Text("Confirm Payment", style: TextStyle(color: widget.isDark ? Colors.white : Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Amount: ৳ ${_amountController.text}", style: TextStyle(color: widget.isDark ? Colors.white70 : Colors.black87)),
            SizedBox(height: 8),
            Text("Method: $selectedMethod", style: TextStyle(color: widget.isDark ? Colors.white70 : Colors.black87)),
            SizedBox(height: 8),
            Text("Phone: ${_phoneController.text}", style: TextStyle(color: widget.isDark ? Colors.white70 : Colors.black87)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2ECC71)),
            onPressed: () {
              // Record the payment
              int amt = int.tryParse(_amountController.text) ?? 0;
              PaymentStore.addPayment(method: selectedMethod, phone: _phoneController.text, amount: amt);
              
              // Track donation amount for badges
              totalDonationAmount += amt;
              
              // Check if new badge unlocked
              final newBadgeInfo = _checkNewBadgesAndGetInfo();

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Payment processed successfully!"),
                  backgroundColor: Color(0xFF2ECC71),
                  duration: Duration(seconds: 2),
                ),
              );
              
              // Show badge celebration if unlocked
              if (newBadgeInfo["found"] as bool) {
                Future.delayed(Duration(milliseconds: 500), () {
                  _showBadgeCelebration(context);
                });
              }
              
              Navigator.pop(context);
            },
            child: Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
