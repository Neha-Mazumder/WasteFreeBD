import 'package:flutter/material.dart';
import 'dashboard.dart'; // totalDonationAmount এক্সেস করার জন্য

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

              // সরাসরি টাকা ডোনেট করার কার্ড
              _buildDonationCard(
                  "💰 Money Donation",
                  "50, 100, 500 or 1000 Taka",
                  Color(0xFFE8F5E9),
                  Color(0xFF2E7D32),
                  context),
              SizedBox(height: 15),

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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(text: "1");
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categoryController.text = widget.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get isMoneyDonation => widget.category == "💰 Money Donation";

  double _calculateDonationAmount() {
    if (isMoneyDonation) {
      return double.tryParse(_amountController.text) ?? 0;
    } else {
      int quantity = int.tryParse(_quantityController.text) ?? 0;
      // Simple price estimation for items (you can adjust this)
      return quantity * 100.0; // Base value per item
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg = widget.isDark ? Color(0xFF121212) : Colors.white;
    Color txt = widget.isDark ? Colors.white : Colors.black;
    Color cardBg = widget.isDark ? Color(0xFF2A2A2A) : Color(0xFFF5F5F5);

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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Fill the donation form",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: txt)),
                SizedBox(height: 25),

                // Name Field
                Text("Your Name",
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: txt)),
                SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: txt),
                  decoration: InputDecoration(
                    hintText: "Enter your full name",
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.person, color: Color(0xFF2ECC71)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Category Field (Read-only)
                Text("Category",
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: txt)),
                SizedBox(height: 8),
                TextFormField(
                  controller: _categoryController,
                  readOnly: true,
                  style: TextStyle(color: txt, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF2ECC71).withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF2ECC71)),
                    ),
                    prefixIcon: Icon(Icons.category, color: Color(0xFF2ECC71)),
                  ),
                ),
                SizedBox(height: 20),

                // Conditional Field: Amount OR Item Name + Quantity
                if (isMoneyDonation) ...[
                  // Amount Field for Money Donation
                  Text("Amount (৳)",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: txt)),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                        color: txt, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "Enter amount in Taka",
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon:
                          Icon(Icons.monetization_on, color: Color(0xFF2ECC71)),
                      prefixText: "৳ ",
                      prefixStyle: TextStyle(
                          color: Color(0xFF2ECC71),
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter donation amount';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  // Item Name Field
                  Text("Item Name",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: txt)),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _itemNameController,
                    style: TextStyle(color: txt),
                    decoration: InputDecoration(
                      hintText: "e.g., T-shirt, Rice, Novel",
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon:
                          Icon(Icons.inventory_2, color: Color(0xFF2ECC71)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter item name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),

                  // Quantity Field
                  Text("Quantity",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: txt)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      // Decrease Button
                      GestureDetector(
                        onTap: () {
                          int currentQty =
                              int.tryParse(_quantityController.text) ?? 1;
                          if (currentQty > 1) {
                            setState(() {
                              _quantityController.text =
                                  (currentQty - 1).toString();
                            });
                          }
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(0xFF2ECC71),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(Icons.remove,
                                color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      // Quantity Input
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: txt,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: cardBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null ||
                                int.parse(value) <= 0) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 15),
                      // Increase Button
                      GestureDetector(
                        onTap: () {
                          int currentQty =
                              int.tryParse(_quantityController.text) ?? 1;
                          setState(() {
                            _quantityController.text =
                                (currentQty + 1).toString();
                          });
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(0xFF2ECC71),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child:
                                Icon(Icons.add, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 20),

                // Note Field
                Text("Note (Optional)",
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: txt)),
                SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  style: TextStyle(color: txt),
                  decoration: InputDecoration(
                    hintText: "Add any additional information...",
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 50),
                      child: Icon(Icons.note_alt, color: Color(0xFF2ECC71)),
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // Donation Value Display
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF2ECC71).withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                
                ),
                SizedBox(height: 25),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2ECC71),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        double donationAmount = _calculateDonationAmount();
                        totalDonationAmount += donationAmount;

                        // Create donation record
                        Map<String, dynamic> donationRecord = {
                          'name': _nameController.text,
                          'category': _categoryController.text,
                          'amount': donationAmount,
                          'note': _noteController.text,
                          'timestamp': DateTime.now().toString(),
                        };

                        if (isMoneyDonation) {
                          donationRecord['donationType'] = 'Money';
                          donationRecord['donatedAmount'] =
                              _amountController.text;
                        } else {
                          donationRecord['donationType'] = 'Items';
                          donationRecord['itemName'] = _itemNameController.text;
                          donationRecord['quantity'] = _quantityController.text;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Donation Successful!",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "Thank you ${_nameController.text}! +৳${donationAmount.toStringAsFixed(0)}",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Color(0xFF2ECC71),
                            duration: Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );

                        Navigator.pop(context);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          "Submit Donation",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
