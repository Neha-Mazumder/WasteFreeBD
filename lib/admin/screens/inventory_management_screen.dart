import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  // Color scheme
  static const Color primary = Color.fromARGB(255, 30, 89, 50);
  static const Color backgroundDark = Color.fromARGB(255, 166, 180, 170);
  static const Color surfaceHighlight = Color(0xFF23482F);
  static const Color textSecondary = Color(0xFF92C9A4);

  // State variables
  bool isLoading = true;
  List<Map<String, dynamic>> inventoryItems = [];

  // Summary data
  double totalStock = 0.0;
  double totalValue = 0.0;
  double storagePercentage = 0.0;
  int maxCapacity = 250; // Assuming 25 tons per item * 10 items

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  /// Load inventory items from Supabase
  Future<void> _loadInventory() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await Supabase.instance.client
          .from('inventory')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        inventoryItems = List<Map<String, dynamic>>.from(response);

        // Calculate totals
        totalStock = 0;
        totalValue = 0;

        for (var item in inventoryItems) {
          final stock = (item['stock_tons'] as num?)?.toDouble() ?? 0;
          final price = (item['unit_price'] as num?)?.toDouble() ?? 0;

          totalStock += stock;
          totalValue += (stock * price);
        }

        // Calculate storage percentage
        storagePercentage = (totalStock / maxCapacity) * 100;

        isLoading = false;
      });
    } catch (e) {
      print('Error loading inventory: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading inventory: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Add new inventory item
  Future<void> _addInventoryItem({
    required String title,
    required String subtitle,
    required double stockTons,
    required double unitPrice,
    String? imageUrl,
  }) async {
    try {
      await Supabase.instance.client.from('inventory').insert({
        'title': title,
        'subtitle': subtitle,
        'image_url': imageUrl,
        'stock_tons': stockTons,
        'unit_price': unitPrice,
        'max_capacity_tons': 25.0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _loadInventory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error adding inventory item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Update inventory stock
  Future<void> _updateInventoryStock({
    required int itemId,
    required double newStock,
  }) async {
    try {
      await Supabase.instance.client.from('inventory').update({
        'stock_tons': newStock,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', itemId);

      await _loadInventory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating stock: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Update inventory item (title, subtitle/category, image, price, stock)
  Future<void> _updateInventoryItem({
    required int itemId,
    required String title,
    required String subtitle,
    required String? imageUrl,
    required double stockTons,
    required double unitPrice,
  }) async {
    try {
      await Supabase.instance.client.from('inventory').update({
        'title': title,
        'subtitle': subtitle,
        'image_url': imageUrl,
        'stock_tons': stockTons,
        'unit_price': unitPrice,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', itemId);

      await _loadInventory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Delete inventory item
  Future<void> _deleteInventoryItem(int itemId) async {
    try {
      await Supabase.instance.client
          .from('inventory')
          .delete()
          .eq('id', itemId);

      await _loadInventory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show add item dialog
  void _showAddItemDialog() {
    final titleController = TextEditingController();
    final imageController = TextEditingController();
    final stockController = TextEditingController();
    final priceController = TextEditingController();
    String selectedCategory = 'Recyclable';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceHighlight,
        title: const Text(
          'Add Inventory Item',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Item Title',
                  labelStyle: const TextStyle(color: textSecondary),
                  filled: true,
                  fillColor: backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Image URL (optional)',
                  labelStyle: const TextStyle(color: textSecondary),
                  filled: true,
                  fillColor: backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                dropdownColor: backgroundDark,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: const TextStyle(color: textSecondary),
                  filled: true,
                  fillColor: backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                items: ['Recyclable', 'Organic', 'General']
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c,
                              style: const TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (val) {
                  selectedCategory = val ?? 'Recyclable';
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Stock (tons)',
                  labelStyle: const TextStyle(color: textSecondary),
                  filled: true,
                  fillColor: backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Unit Price (\$)',
                  labelStyle: const TextStyle(color: textSecondary),
                  filled: true,
                  fillColor: backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              final title = titleController.text.trim();
              final subtitle =
                  selectedCategory; // save selected category as subtitle
              final imageUrl = imageController.text.trim();
              final stock = double.tryParse(stockController.text) ?? 0;
              final price = double.tryParse(priceController.text) ?? 0;

              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Title is required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              _addInventoryItem(
                title: title,
                subtitle: subtitle,
                stockTons: stock,
                unitPrice: price,
                imageUrl: imageUrl.isEmpty ? null : imageUrl,
              );

              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: primary)),
          ),
        ],
      ),
    );
  }

  /// Show edit dialog for entire item (title, category/subtitle, image url, stock, price)
  void _showEditItemDialog(Map<String, dynamic> item) {
    final titleController = TextEditingController(text: item['title'] ?? '');
    final imageController =
        TextEditingController(text: (item['image_url'] as String?) ?? '');
    String selectedCategory = item['subtitle'] ?? 'Recyclable';
    final stockController = TextEditingController(
      text: ((item['stock_tons'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
    );
    final priceController = TextEditingController(
      text: ((item['unit_price'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        void changeStockBy(double delta) {
          final curr = double.tryParse(stockController.text) ?? 0.0;
          final next = (curr + delta) < 0 ? 0.0 : (curr + delta);
          stockController.text = next.toStringAsFixed(2);
          setState(() {});
        }

        return AlertDialog(
          backgroundColor: surfaceHighlight,
          title: Text(
            'Edit Item - ${item['title']}',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Item Title',
                    labelStyle: const TextStyle(color: textSecondary),
                    filled: true,
                    fillColor: backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Image URL (optional)',
                    labelStyle: const TextStyle(color: textSecondary),
                    filled: true,
                    fillColor: backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  dropdownColor: backgroundDark,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: const TextStyle(color: textSecondary),
                    filled: true,
                    fillColor: backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: ['Recyclable', 'Organic', 'General']
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => selectedCategory = val ?? 'Recyclable'),
                ),
                const SizedBox(height: 12),
                // Stock with +/- buttons
                Row(
                  children: [
                    IconButton(
                      onPressed: () => changeStockBy(-1.0),
                      icon: const Icon(Icons.remove, color: Colors.white),
                    ),
                    Expanded(
                      child: TextField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Stock (tons)',
                          labelStyle: const TextStyle(color: textSecondary),
                          filled: true,
                          fillColor: backgroundDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => changeStockBy(1.0),
                      icon: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Unit Price (৳)',
                    labelStyle: const TextStyle(color: textSecondary),
                    filled: true,
                    fillColor: backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                final title = titleController.text.trim();
                final subtitle = selectedCategory;
                final imageUrl = imageController.text.trim();
                final stock = double.tryParse(stockController.text) ?? 0;
                final price = double.tryParse(priceController.text) ?? 0;

                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Title is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                _updateInventoryItem(
                  itemId: item['id'],
                  title: title,
                  subtitle: subtitle,
                  imageUrl: imageUrl.isEmpty ? null : imageUrl,
                  stockTons: stock,
                  unitPrice: price,
                );

                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: primary)),
            ),
          ],
        );
      }),
    );
  }

  /// Build summary card
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceHighlight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build inventory item card
  Widget _buildInventoryItemCard(Map<String, dynamic> item) {
    final stock = (item['stock_tons'] as num?)?.toDouble() ?? 0;
    final price = (item['unit_price'] as num?)?.toDouble() ?? 0;
    final value = stock * price;
    final capacity = (item['max_capacity_tons'] as num?)?.toDouble() ?? 25;
    final utilizationPercent = (stock / capacity) * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceHighlight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // small round image sector on top-left
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Builder(builder: (_) {
                    final imageUrl = (item['image_url'] as String?)?.trim();
                    if (imageUrl == null || imageUrl.isEmpty) {
                      return Container(
                        color: Colors.black12,
                        child: const Icon(Icons.image, color: Colors.white70),
                      );
                    }
                    return Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: Colors.black12,
                        child: const Icon(Icons.broken_image,
                            color: Colors.white70),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? 'Unknown Item',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['subtitle'] ?? '',
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: surfaceHighlight,
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    child: const Text(
                      'Edit',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () => _showEditItemDialog(item),
                  ),
                  PopupMenuItem<String>(
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () => _deleteInventoryItem(item['id']),
                  ),
                ],
                child: const Icon(Icons.more_vert, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock: ${stock.toStringAsFixed(2)} tons',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Price: ৳${price.toStringAsFixed(2)}/ton',
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Value: ৳${value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 181, 184, 182),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${utilizationPercent.toStringAsFixed(0)}% utilized',
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: utilizationPercent / 100,
              backgroundColor: Colors.black26,
              valueColor: AlwaysStoppedAnimation<Color>(
                utilizationPercent > 80 ? Colors.red : primary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          // +/- buttons at bottom-right for quick stock adjustments
          Row(
            children: [
              const Spacer(),
              IconButton(
                onPressed: () => _showAdjustStockDialog(item, false),
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.white),
                tooltip: 'Decrease stock',
              ),
              IconButton(
                onPressed: () => _showAdjustStockDialog(item, true),
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                tooltip: 'Increase stock',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show dialog to adjust stock by value and unit (Gram, Kg, Ton)
  void _showAdjustStockDialog(Map<String, dynamic> item, bool isAdding) {
    final amountController = TextEditingController();
    String unit = 'Kg';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceHighlight,
        title: Text(
          '${isAdding ? 'Add' : 'Remove'} Stock - ${item['title']}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: const TextStyle(color: textSecondary),
                filled: true,
                fillColor: backgroundDark,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: unit,
              dropdownColor: backgroundDark,
              decoration: InputDecoration(
                labelText: 'Unit',
                labelStyle: const TextStyle(color: textSecondary),
                filled: true,
                fillColor: backgroundDark,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: ['Gram', 'Kg', 'Ton']
                  .map((u) => DropdownMenuItem(
                      value: u,
                      child:
                          Text(u, style: const TextStyle(color: Colors.white))))
                  .toList(),
              onChanged: (v) => unit = v ?? 'Kg',
            ),
            const SizedBox(height: 8),
            const Text(
              'Conversions: 1 kg = 1000 gram; 1 ton = 907.185 kg; 1 ton = 1000000 gram',
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white))),
          TextButton(
            onPressed: () {
              final input = double.tryParse(amountController.text) ?? 0.0;
              if (input <= 0) {
                Navigator.pop(context);
                return;
              }

              // Convert input to tons using provided logic: 1 kg = 1000 g, 1 ton = 1000000 g
              double tonsToAdjust = 0.0;
              if (unit == 'Gram') {
                tonsToAdjust = input / 1000000.0; // grams -> tons
              } else if (unit == 'Kg') {
                final grams = input * 1000.0;
                tonsToAdjust = grams / 1000000.0; // kg -> grams -> tons
              } else {
                // Ton selected
                tonsToAdjust = input; // assume input already in tons
              }

              final currentStock =
                  (item['stock_tons'] as num?)?.toDouble() ?? 0.0;
              double newStock = isAdding
                  ? (currentStock + tonsToAdjust)
                  : (currentStock - tonsToAdjust);
              if (newStock < 0) newStock = 0.0;

              _updateInventoryStock(itemId: item['id'], newStock: newStock);
              Navigator.pop(context);
            },
            child: const Text('Apply', style: TextStyle(color: primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: BoxDecoration(
                  color: backgroundDark.withOpacity(0.95),
                  border: Border(
                    bottom: BorderSide(color: surfaceHighlight),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        color: primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Inventory Management',
                          style: TextStyle(
                            color: Color.fromARGB(255, 15, 13, 13),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _loadInventory,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Summary cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Total Stock',
                            value: '${totalStock.toStringAsFixed(2)} tons',
                            icon: Icons.inventory,
                            color: primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Storage',
                            value: '${storagePercentage.toStringAsFixed(0)}%',
                            icon: Icons.storage,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(
                      title: 'Total Value',
                      value: '৳${totalValue.toStringAsFixed(2)}',
                      icon: Icons.attach_money,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Inventory items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inventory Items',
                      style: TextStyle(
                        color: Color.fromARGB(255, 8, 7, 7),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isLoading)
                      const Center(
                        child: CircularProgressIndicator(color: primary),
                      )
                    else if (inventoryItems.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: surfaceHighlight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'No inventory items yet',
                            style: TextStyle(color: textSecondary),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: inventoryItems
                            .map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildInventoryItemCard(item),
                                ))
                            .toList(),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add, color: backgroundDark),
      ),
    );
  }
}
