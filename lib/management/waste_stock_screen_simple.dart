import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WasteStockScreen extends StatefulWidget {
  const WasteStockScreen({super.key});

  @override
  State<WasteStockScreen> createState() => _WasteStockScreenState();
}

class _WasteStockScreenState extends State<WasteStockScreen> {
  static const Color primary = Color(0xFF13EC5B);
  static const Color backgroundDark = Color(0xFF102216);
  static const Color surfaceHighlight = Color(0xFF23482F);
  static const Color textSecondary = Color(0xFF92C9A4);

  bool isLoading = true;
  List<Map<String, dynamic>> wasteStocks = [];
  double totalTonnage = 0.0;

  @override
  void initState() {
    super.initState();
    _loadWasteStocks();
  }

  Future<void> _loadWasteStocks() async {
    try {
      setState(() => isLoading = true);

      final response =
          await Supabase.instance.client.from('inventory').select();
      final inventory = List<Map<String, dynamic>>.from(response);

      double total = 0.0;
      for (var item in inventory) {
        total += (item['stock_tons'] as num?)?.toDouble() ?? 0.0;
      }

      setState(() {
        wasteStocks = inventory;
        totalTonnage = total;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading waste stocks: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Stock Management'),
        backgroundColor: backgroundDark,
      ),
      backgroundColor: backgroundDark,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primary),
            )
          : RefreshIndicator(
              onRefresh: _loadWasteStocks,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceHighlight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Tonnage',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${totalTonnage.toStringAsFixed(2)} tons',
                              style: const TextStyle(
                                color: primary,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = wasteStocks[index];
                        return Card(
                          color: surfaceHighlight,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(
                              item['title'] ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${(item['stock_tons'] as num?)?.toDouble() ?? 0.0} tons',
                              style: const TextStyle(
                                color: textSecondary,
                              ),
                            ),
                            trailing: Text(
                              '৳${(item['unit_price'] as num?)?.toDouble() ?? 0.0}',
                              style: const TextStyle(
                                color: primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: wasteStocks.length,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
