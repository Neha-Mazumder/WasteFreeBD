import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard.dart'; // Import to access totalDonationAmount

class DonationPage extends StatefulWidget {
  final bool isDark;
  DonationPage({required this.isDark});

  @override
  _DonationPageState createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  @override
  Widget build(BuildContext context) {
    Color bg = widget.isDark ? Color(0xFF121212) : Colors.white;
    Color txt = widget.isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text("Donate Items", style: TextStyle(color: txt)),
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
              Text("What would you like to donate?",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: txt)),
              SizedBox(height: 20),
              _buildDonationCard(
                  "👕 Clothing & Fashion",
                  "Dress, T-shirts, Shoes, Bags",
                  Color(0xFFBBDEFB),
                  Color(0xFF0D47A1),
                  context),
              SizedBox(height: 15),
              _buildDonationCard(
                  "🍎 Food & Groceries",
                  "Fresh foods, Canned goods, Pantry items",
                  Color(0xFFFFECB3),
                  Color(0xFFFF6F00),
                  context),
              SizedBox(height: 15),
              _buildDonationCard(
                  "📚 Books & Education",
                  "Textbooks, Novels, Educational materials",
                  Color(0xFFE1BEE7),
                  Color(0xFF6A1B9A),
                  context),
              SizedBox(height: 15),
              _buildDonationCard(
                  "🏠 Household Items",
                  "Furniture, Kitchenware, Bedding",
                  Color(0xFFC8E6C9),
                  Color(0xFF2E7D32),
                  context),
              SizedBox(height: 15),
              _buildDonationCard("👶 Baby & Kids", "Toys, Clothes, Strollers",
                  Color(0xFFFFCCBC), Color(0xFFBF360C), context),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonationCard(String title, String description, Color bgColor,
      Color contentColor, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ItemDonationPage(category: title, isDark: widget.isDark)),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: contentColor.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: contentColor)),
            SizedBox(height: 8),
            Text(description,
                style: TextStyle(
                    fontSize: 12, color: contentColor.withOpacity(0.7))),
            SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.arrow_forward, color: contentColor),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ITEM DONATION PAGE ---
class ItemDonationPage extends StatefulWidget {
  final String category;
  final bool isDark;
  ItemDonationPage({required this.category, required this.isDark});

  @override
  _ItemDonationPageState createState() => _ItemDonationPageState();
}

class _ItemDonationPageState extends State<ItemDonationPage> {
  List<Map<String, dynamic>> selectedItems = [];
  final TextEditingController _descriptionController = TextEditingController();

  // Item prices in Taka (৳)
  Map<String, double> itemPrices = {
    "T-shirts": 100,
    "Jeans": 200,
    "Dresses": 250,
    "Shoes": 150,
    "Jackets": 300,
    "Bags": 200,
    "Scarves": 80,
    "Rice": 50,
    "Wheat": 40,
    "Lentils": 60,
    "Vegetables": 30,
    "Fruits": 50,
    "Canned goods": 70,
    "Milk": 40,
    "Novels": 150,
    "Textbooks": 200,
    "Comic books": 80,
    "Magazines": 50,
    "Educational CDs": 100,
    "Furniture": 500,
    "Dishes": 80,
    "Bedding": 200,
    "Towels": 60,
    "Cooking utensils": 100,
    "Light bulbs": 50,
    "Toys": 120,
    "Baby clothes": 100,
    "Baby bottles": 80,
    "Strollers": 1000,
    "Books": 100,
  };

  Map<String, List<String>> categoryItems = {
    "👕 Clothing & Fashion": [
      "T-shirts",
      "Jeans",
      "Dresses",
      "Shoes",
      "Jackets",
      "Bags",
      "Scarves"
    ],
    "🍎 Food & Groceries": [
      "Rice",
      "Wheat",
      "Lentils",
      "Vegetables",
      "Fruits",
      "Canned goods",
      "Milk"
    ],
    "📚 Books & Education": [
      "Novels",
      "Textbooks",
      "Comic books",
      "Magazines",
      "Educational CDs"
    ],
    "🏠 Household Items": [
      "Furniture",
      "Dishes",
      "Bedding",
      "Towels",
      "Cooking utensils",
      "Light bulbs"
    ],
    "👶 Baby & Kids": [
      "Toys",
      "Baby clothes",
      "Baby bottles",
      "Strollers",
      "Books"
    ],
  };

  double _calculateTotalDonation() {
    double total = 0;
    for (var item in selectedItems) {
      double price = itemPrices[item['name']] ?? 0;
      int quantity = item['quantity'] ?? 1;
      total += price * quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    Color bg = widget.isDark ? Color(0xFF121212) : Colors.white;
    Color txt = widget.isDark ? Colors.white : Colors.black;
    Color cardBg = widget.isDark ? Color(0xFF2A2A2A) : Color(0xFFF5F5F5);
    List<String> items = categoryItems[widget.category] ?? [];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(widget.category, style: TextStyle(color: txt)),
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
              Text("Select items to donate",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: txt)),
              SizedBox(height: 15),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: items.map((item) {
                  bool isSelected = selectedItems.any((i) => i['name'] == item);
                  return FilterChip(
                    label: Text(item),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          selectedItems.add({'name': item, 'quantity': 1});
                        } else {
                          selectedItems.removeWhere((i) => i['name'] == item);
                        }
                      });
                    },
                    backgroundColor: cardBg,
                    selectedColor: Color(0xFF2ECC71),
                    labelStyle:
                        TextStyle(color: isSelected ? Colors.white : txt),
                  );
                }).toList(),
              ),
              SizedBox(height: 30),
              if (selectedItems.isNotEmpty) ...[
                Text("Donation Details",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: txt)),
                SizedBox(height: 15),
                ...selectedItems.map((item) {
                  double price = itemPrices[item['name']] ?? 0;
                  int quantity = item['quantity'] ?? 1;
                  double itemTotal = price * quantity;

                  return Padding(
                    padding: EdgeInsets.only(bottom: 15),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Color(0xFF2ECC71), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item['name'],
                                  style: TextStyle(
                                      color: txt,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              Text("৳${price.toStringAsFixed(0)}/item",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Text("Qty:", style: TextStyle(color: txt)),
                              SizedBox(width: 10),
                              // Decrease button
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (item['quantity'] > 1) {
                                      item['quantity']--;
                                    }
                                  });
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF2ECC71),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                      child: Text("-",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold))),
                                ),
                              ),
                              SizedBox(width: 10),
                              // Quantity display
                              Container(
                                width: 50,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: widget.isDark
                                      ? Color(0xFF1E1E1E)
                                      : Colors.white,
                                  border: Border.all(
                                      color: Color(0xFF2ECC71), width: 1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: TextField(
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                      color: txt, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  controller: TextEditingController(
                                      text: quantity.toString()),
                                  onChanged: (value) {
                                    int newQty = int.tryParse(value) ?? 1;
                                    if (newQty > 0) {
                                      item['quantity'] = newQty;
                                    }
                                  },
                                ),
                              ),
                              SizedBox(width: 10),
                              // Increase button
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    item['quantity']++;
                                  });
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF2ECC71),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                      child: Text("+",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold))),
                                ),
                              ),
                              Spacer(),
                              Text("Total: ৳${itemTotal.toStringAsFixed(0)}",
                                  style: TextStyle(
                                      color: Color(0xFF2ECC71),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                SizedBox(height: 20),
                // Total donation amount
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF2ECC71).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF2ECC71), width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total Donation Value:",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: txt)),
                      Text("৳${_calculateTotalDonation().toStringAsFixed(0)}",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2ECC71))),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: TextStyle(color: txt),
                  decoration: InputDecoration(
                    hintText: "Add notes (condition, size, etc.)",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: cardBg,
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2ECC71),
                        padding: EdgeInsets.symmetric(vertical: 15)),
                    onPressed: () async {
                      double donationAmount = _calculateTotalDonation();

                      try {
                        // Save donation to database
                        await Supabase.instance.client.from('payments').insert({
                          'amount': donationAmount,
                          'description':
                              'Donation: ${widget.category} - ${selectedItems.map((i) => "${i['name']} x${i['quantity']}").join(", ")}',
                          'status': 'completed',
                          'created_at': DateTime.now().toIso8601String(),
                        });

                        // Update global donation amount for badge system
                        totalDonationAmount += donationAmount;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Donation submitted! +৳${donationAmount.toStringAsFixed(0)} toward badges"),
                            backgroundColor: Color(0xFF2ECC71),
                            duration: Duration(seconds: 3),
                          ),
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error: ${e.toString()}"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text("Submit Donation",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                Center(
                  child: Text("Select items to continue",
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ),
              ],
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
