import 'package:flutter/material.dart';
import "package:wastefreebd/common/services/supabase_service.dart";
import 'package:provider/provider.dart';
import 'package:wastefreebd/providers/notification_provider.dart';
import 'package:wastefreebd/admin/widgets/notification_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseService _service = SupabaseService();

  late Future<Map<String, dynamic>> _statsFuture;
  late Future<List<Map<String, dynamic>>> _workersFuture;
  late Future<List<Map<String, dynamic>>> _wasteStocksFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Initialize notification listener
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Provider.of<NotificationProvider>(context, listen: false)
            .initializeNotificationListener();
      }
    });
  }

  void _loadData() {
    setState(() {
      _statsFuture = _service.getDashboardStats();
      _workersFuture = _service.getWorkers();
      _wasteStocksFuture = _service.getWasteStocks();
    });
  }

  Future<Map<String, double>> _calculateNetProfit() async {
    try {
      // Fetch inventory items to calculate total value (same as financial_overview_screen)
      final inventoryResponse =
          await Supabase.instance.client.from('inventory').select();
      final inventoryItems = List<Map<String, dynamic>>.from(inventoryResponse);

      // Calculate inventory total value (stock * unit_price for all items)
      double inventoryTotalValue = 0.0;
      for (var item in inventoryItems) {
        final stock = (item['stock_tons'] as num?)?.toDouble() ?? 0;
        final price = (item['unit_price'] as num?)?.toDouble() ?? 0;
        inventoryTotalValue += (stock * price);
      }

      // Fetch financial records to get revenue from database
      final financialResponse =
          await Supabase.instance.client.from('financial_records').select();
      final financialRecords =
          List<Map<String, dynamic>>.from(financialResponse);

      // Calculate sum of all revenue values from financial_records
      double financialRecordsRevenue = financialRecords.fold(
          0.0,
          (sum, record) =>
              sum + ((record['revenue'] as num?)?.toDouble() ?? 0.0));

      // Total Revenue = Inventory Total Value + Sum of all revenue from database
      final totalRevenue = inventoryTotalValue + financialRecordsRevenue;

      // Fetch workers (for salaries)
      final workers = await _service.getWorkers();
      final workerSalaries = workers.fold(
          0.0,
          (sum, worker) =>
              sum + ((worker['salary'] as num?)?.toDouble() ?? 0.0));

      // Fetch business expenses (utilities and vehicles)
      final businessExpensesResponse =
          await Supabase.instance.client.from('business_expenses').select();
      final businessExpenses =
          List<Map<String, dynamic>>.from(businessExpensesResponse);
      final totalBusinessExpenses = businessExpenses.fold(
          0.0,
          (sum, expense) =>
              sum + ((expense['amount'] as num?)?.toDouble() ?? 0.0));

      // Calculate total costs and net profit (same as financial_overview_screen)
      final totalCosts = workerSalaries + totalBusinessExpenses;
      final netProfit = totalRevenue - totalCosts;

      return {
        'totalRevenue': totalRevenue,
        'totalCosts': totalCosts,
        'netProfit': netProfit,
      };
    } catch (e) {
      print('Error calculating net profit: $e');
      return {
        'totalRevenue': 0.0,
        'totalCosts': 0.0,
        'netProfit': 0.0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primary = Color(0xFF13EC5B);
    const Color backgroundDark = Color(0xFF102216);
    const Color backgroundLight = Color(0xFFF6F8F6);
    const Color cardDark = Color(0xFF23482F);
    const Color textSecondary = Color(0xFF92C9A4);

    return Container(
      color:
          isDark ? const Color.fromARGB(255, 228, 244, 233) : backgroundLight,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER =====
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: BoxDecoration(
                  color: (isDark ? backgroundDark : backgroundLight)
                      .withOpacity(0.95),
                  border:
                      const Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey,
                                  child: const Icon(Icons.person),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: primary,
                                      shape: BoxShape.circle,
                                      border: Border.fromBorderSide(BorderSide(
                                          color: backgroundDark, width: 2)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Welcome back,',
                                    style: TextStyle(
                                        color: textSecondary, fontSize: 12)),
                                Text('Admin User',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              size: 28, color: Colors.white),
                          onPressed: () => _loadData(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Dashboard',
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Refresh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cardDark,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ===== NOTIFICATIONS PANEL =====
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  final pendingNotifications = notificationProvider
                      .notifications
                      .where((n) => n.status == 'pending')
                      .toList();

                  if (pendingNotifications.isNotEmpty) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF13EC5B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: const Border.fromBorderSide(
                                BorderSide(
                                  color: Color(0xFF13EC5B),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.notifications_active,
                                    color: Color(0xFF13EC5B), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${pendingNotifications.length} pending request${pendingNotifications.length > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      color: Color(0xFF13EC5B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF13EC5B),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${pendingNotifications.length}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...pendingNotifications.map((notification) {
                          return NotificationCard(
                            notification: notification,
                            onComplete: () async {
                              await notificationProvider.completeNotification(
                                notificationId: notification.id,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('✓ Pickup completed successfully'),
                                    backgroundColor: Color(0xFF13EC5B),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),

              // ===== QUICK STATS =====
              FutureBuilder<Map<String, dynamic>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final stats = snapshot.data ?? {};
                  return Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      return SizedBox(
                        height: 140,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _buildStatCard(
                              icon: Icons.local_shipping,
                              color: primary,
                              title: 'Pickups Today',
                              value: '${stats['pickups_today'] ?? 0}',
                              trend: '+5%',
                              hasTrend: true,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              icon: Icons.rv_hookup,
                              color: Colors.blue,
                              title: 'Active Trucks',
                              value:
                                  '${stats['active_trucks'] ?? 0}/${stats['total_trucks'] ?? 10}',
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              icon: Icons.warning_amber_outlined,
                              color: Colors.orange,
                              title: 'Pending Issues',
                              value: '${notificationProvider.pendingCount}',
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // ===== REAL-TIME PROFIT GRAPH =====
              FutureBuilder<Map<String, double>>(
                future: _calculateNetProfit(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final data = snapshot.data ?? {};
                  final netProfit = data['netProfit'] ?? 0.0;

                  // Generate profit data points for the last 7 periods
                  final List<FlSpot> profitSpots = [
                    FlSpot(0, netProfit * 0.6),
                    FlSpot(1, netProfit * 0.7),
                    FlSpot(2, netProfit * 0.65),
                    FlSpot(3, netProfit * 0.8),
                    FlSpot(4, netProfit * 0.85),
                    FlSpot(5, netProfit * 0.9),
                    FlSpot(6, netProfit),
                  ];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: const Border.fromBorderSide(
                            BorderSide(color: Color(0xFF326744))),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Profit Trend',
                                    style: TextStyle(
                                        color: Color(0xFF92C9A4), fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '৳${netProfit.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF13EC5B).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.trending_up,
                                        color: Color(0xFF13EC5B), size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      '+12%',
                                      style: TextStyle(
                                        color: Color(0xFF13EC5B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 150,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                minX: 0,
                                maxX: 6,
                                minY: netProfit * 0.5,
                                maxY: netProfit * 1.1,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: profitSpots,
                                    isCurved: true,
                                    color: const Color(0xFF13EC5B),
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: const Color(0xFF13EC5B)
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ===== ACTIVE WORKFORCE =====
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _workersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final workers = snapshot.data ?? [];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Active Workforce',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 16, 13, 13))),
                            TextButton(
                                onPressed: () => ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                        content: Text('See all workforce'))),
                                child: const Text('See All',
                                    style: TextStyle(color: primary))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (var worker in workers.take(2))
                          Column(
                            children: [
                              _buildWorkerCard(
                                profile: worker['profile_url'] ?? '',
                                name: worker['name'] ?? 'Unknown',
                                route: '${worker['role'] ?? 'No role'}',
                                status: worker['status'] ?? 'ACTIVE',
                                statusColor: _getStatusColor(
                                    worker['status'] ?? 'ACTIVE'),
                                progress: 0.85,
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ===== WASTE STOCK LEVELS =====
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _wasteStocksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final wasteStocks = snapshot.data ?? [];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 3,
                          children: wasteStocks
                              .map((stock) => _buildStockItem(
                                    icon: _getWasteIcon(stock['type'] ?? ''),
                                    color: _getWasteColor(stock['type'] ?? ''),
                                    label: stock['type'] ?? 'Unknown',
                                    percent:
                                        (stock['percent'] as num?)?.toInt() ??
                                            0,
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 100),
            ], // End children
          ), // End Column
        ), // End SingleChildScrollView
      ), // End SafeArea
    ); // End Container
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF13EC5B);
      case 'BREAK':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getWasteIcon(String type) {
    switch (type.toLowerCase()) {
      case 'plastic':
        return Icons.recycling;
      case 'organic':
        return Icons.compost;
      case 'glass':
        return Icons.wine_bar;
      default:
        return Icons.inventory;
    }
  }

  Color _getWasteColor(String type) {
    switch (type.toLowerCase()) {
      case 'plastic':
        return const Color(0xFF13EC5B);
      case 'organic':
        return Colors.orange;
      case 'glass':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    String? trend,
    bool hasTrend = false,
  }) {
    return Container(
      width: 160,
      height: 116,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF23482F),
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 24),
              ),
              if (hasTrend)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(trend!,
                      style: const TextStyle(
                          color: Color(0xFF13EC5B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(color: Color(0xFF92C9A4), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Unused method - kept for future use
  // ignore: unused_element
  Widget _buildProfitGraphCard(double netProfit) {
    // Generate sample profit data points for the last 7 periods
    final List<FlSpot> profitSpots = [
      FlSpot(0, netProfit * 0.6),
      FlSpot(1, netProfit * 0.7),
      FlSpot(2, netProfit * 0.65),
      FlSpot(3, netProfit * 0.8),
      FlSpot(4, netProfit * 0.85),
      FlSpot(5, netProfit * 0.9),
      FlSpot(6, netProfit),
    ];

    return Container(
      width: 280,
      height: 116,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF23482F),
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profit Trend',
                    style: TextStyle(color: Color(0xFF92C9A4), fontSize: 11),
                  ),
                  Text(
                    '৳${netProfit.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF13EC5B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, color: Color(0xFF13EC5B), size: 12),
                    SizedBox(width: 2),
                    Text(
                      '+12%',
                      style: TextStyle(
                        color: Color(0xFF13EC5B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: netProfit * 0.5,
                maxY: netProfit * 1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: profitSpots,
                    isCurved: true,
                    color: const Color(0xFF13EC5B),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF13EC5B).withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard({
    required String profile,
    required String name,
    required String route,
    required String status,
    required Color statusColor,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF23482F),
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey,
            backgroundImage: profile.isNotEmpty ? NetworkImage(profile) : null,
            child: profile.isEmpty ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: statusColor, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(status.toUpperCase(),
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(route,
                    style: const TextStyle(
                        color: Color(0xFF92C9A4), fontSize: 12)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.black45,
                  color: statusColor,
                  minHeight: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockItem({
    required IconData icon,
    required Color color,
    required String label,
    required int percent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF23482F),
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.white)),
                    Text('$percent%',
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: percent / 100,
                  backgroundColor: Colors.black45,
                  color: color,
                  minHeight: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Keep existing ProfitChartPainter from original code
class ProfitChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF13EC5B).withOpacity(0.2), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final Paint strokePaint = Paint()
      ..color = const Color(0xFF13EC5B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path fillPath = Path();
    final Path strokePath = Path();

    fillPath.moveTo(0, size.height * 0.73);
    fillPath.cubicTo(size.width * 0.1, size.height * 0.73, size.width * 0.15,
        size.height * 0.53, size.width * 0.25, size.height * 0.53);
    fillPath.cubicTo(size.width * 0.35, size.height * 0.53, size.width * 0.4,
        size.height * 0.67, size.width * 0.5, size.height * 0.4);
    fillPath.cubicTo(size.width * 0.6, size.height * 0.13, size.width * 0.65,
        size.height * 0.27, size.width * 0.75, size.height * 0.27);
    fillPath.cubicTo(size.width * 0.85, size.height * 0.27, size.width * 0.9,
        size.height * 0.07, size.width, size.height * 0.13);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    strokePath.moveTo(0, size.height * 0.73);
    strokePath.cubicTo(size.width * 0.1, size.height * 0.73, size.width * 0.15,
        size.height * 0.53, size.width * 0.25, size.height * 0.53);
    strokePath.cubicTo(size.width * 0.35, size.height * 0.53, size.width * 0.4,
        size.height * 0.67, size.width * 0.5, size.height * 0.4);
    strokePath.cubicTo(size.width * 0.6, size.height * 0.13, size.width * 0.65,
        size.height * 0.27, size.width * 0.75, size.height * 0.27);
    strokePath.cubicTo(size.width * 0.85, size.height * 0.27, size.width * 0.9,
        size.height * 0.07, size.width, size.height * 0.13);

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
