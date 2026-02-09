import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WasteStockScreen extends StatefulWidget {
  const WasteStockScreen({super.key});

  @override
  State<WasteStockScreen> createState() => _WasteStockScreenState();
}

class _WasteStockScreenState extends State<WasteStockScreen> {
  // Color scheme
  static const Color primary = Color(0xFF13EC5B);
  static const Color backgroundDark = Color(0xFF102216);
  static const Color surfaceHighlight = Color(0xFF23482F);
  static const Color textSecondary = Color(0xFF92C9A4);

  // State variables
  bool isLoading = true;
  List<Map<String, dynamic>> wasteStocks = [];
  double totalTonnage = 0.0;

  // Waste type colors
  final Map<String, Color> wasteTypeColors = {
    'Recyclable': Colors.blue,
    'Organic': Colors.green,
    'General': Colors.red,
  };

  // Waste type icons (used for photo-style cards)
  final Map<String, IconData> wasteTypeIcons = {
    'Recyclable': Icons.recycling,
    'Organic': Icons.grass,
    'General': Icons.delete,
  };

  @override
  void initState() {
    super.initState();
    _loadWasteStocks();
  }

  /// Load waste stocks from Supabase inventory, aggregated by category
  Future<void> _loadWasteStocks() async {
    try {
      setState(() => isLoading = true);

      // Fetch inventory items
      final invResp = await Supabase.instance.client
          .from('inventory')
          .select();

      final invList = List<Map<String, dynamic>>.from(invResp);

      // Aggregate by category (subtitle)
      Map<String, double> categories = {
        'Recyclable': 0.0,
        'Organic': 0.0,
        'General': 0.0,
      };
      double total = 0.0;

      for (var item in invList) {
        String cat = item['subtitle'] ?? 'General';
        if (categories.containsKey(cat)) {
          double stock = (item['stock_tons'] as num?)?.toDouble() ?? 0.0;
          categories[cat] = categories[cat]! + stock;
          total += stock;
        }
      }

      // Build wasteStocks list for the 3 categories
      List<Map<String, dynamic>> stocks = [];
      categories.forEach((cat, ton) {
        stocks.add({
          'type': cat,
          'tonnage': ton,
          'percent': total > 0 ? (ton / total * 100).round() : 0,
        });
      });

      setState(() {
        wasteStocks = stocks;
        totalTonnage = total;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading waste stocks: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading data: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Build waste breakdown card
  Widget _buildBreakdownCard(Map<String, dynamic> waste) {
    final tonnage = (waste['tonnage'] as num?)?.toDouble() ?? 0;
    final percent = (waste['percent'] as num?)?.toInt() ?? 0;
    final type = waste['type'] ?? 'Unknown';
    final color = wasteTypeColors[type] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                type,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${tonnage.toStringAsFixed(2)} tonnes',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.black26,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  /// Build waste type photo-style card
  Widget _buildTypePhotoCard(Map<String, dynamic> waste) {
    final type = waste['type'] ?? 'Unknown';
    final tonnage = (waste['tonnage'] as num?)?.toDouble() ?? 0;
    final percent = (waste['percent'] as num?)?.toInt() ?? 0;
    final color = wasteTypeColors[type] ?? Colors.grey;
    final icon = wasteTypeIcons[type] ?? Icons.recycling;

    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceHighlight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            type,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '${tonnage.toStringAsFixed(2)} t',
            style: const TextStyle(color: textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '$percent%',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
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
                          'Waste Stock Management',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _loadWasteStocks,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Total tonnage card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primary.withOpacity(0.2),
                        primary.withOpacity(0.05)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Waste Collected',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${totalTonnage.toStringAsFixed(2)} tonnes',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.delete_outline,
                        color: primary.withOpacity(0.5),
                        size: 40,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Waste type photo-style cards (horizontal)
              if (!isLoading && wasteStocks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 170,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: wasteStocks.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) =>
                          _buildTypePhotoCard(wasteStocks[index]),
                    ),
                  ),
                ),
              // Waste breakdown (3 cards)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Waste Distribution',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isLoading)
                      const Center(
                        child: CircularProgressIndicator(color: primary),
                      )
                    else if (wasteStocks.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: surfaceHighlight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'No waste stocks recorded yet',
                            style: TextStyle(color: textSecondary),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: wasteStocks
                            .map((waste) => _buildBreakdownCard(waste))
                            .toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Pie chart section
              if (wasteStocks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Waste Distribution Pie Chart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: wasteStocks.map((waste) {
                              final percent = (waste['percent'] as int?) ?? 0;
                              final color = wasteTypeColors[waste['type']] ?? Colors.grey;
                              return PieChartSectionData(
                                value: percent.toDouble(),
                                color: color,
                                title: '${waste['type']}\n$percent%',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}