import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import "package:supabase_flutter/supabase_flutter.dart";
import 'package:wastefreebd/common/widgets/role_scaffold.dart';

class FinancialOverviewScreen extends StatefulWidget {
  const FinancialOverviewScreen({super.key});

  @override
  State<FinancialOverviewScreen> createState() =>
      _FinancialOverviewScreenState();
}

class _FinancialOverviewScreenState extends State<FinancialOverviewScreen> {
  static const Color primary = Color(0xFF13EC5B);
  static const Color backgroundDark = Color(0xFF102216);
  static const Color surfaceDark = Color(0xFF1C2E22);
  static const Color surfaceHighlight = Color(0xFF23482F);
  static const Color costAlert = Color(0xFFFF6B6B);
  static const Color textSecondary = Color(0xFF92C9A4);

  String _selectedMetric = 'Profit';
  String _selectedCostCategory = 'Worker Salary';
  bool isLoading = true;

  double totalProfit = 0.0;
  double totalRevenue = 0.0;
  double totalCosts = 0.0;
  double profitMargin = 0.0;
  double totalInventoryWeight = 0.0;
  double averageUnitPrice = 0.0;

  List<Map<String, dynamic>> financialRecords = [];
  List<Map<String, dynamic>> workers = [];
  List<Map<String, dynamic>> utilityBills = [];
  List<Map<String, dynamic>> vehicleExpenses = [];

  @override
  void initState() {
    super.initState();
    _refreshAllData();
  }

  Future<void> _refreshAllData() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([
        _loadFinancialData(),
        _loadInventoryStats(),
        _loadWorkers(),
        _loadUtilityBills(),
        _loadVehicleExpenses(),
      ]);
      _calculateTotals();
    } catch (e) {
      print('Error refreshing data: $e');
      _showErrorSnackBar('Error loading data:  $e');
    }
    setState(() => isLoading = false);
  }

  void _calculateTotals() {
    double workerSum = workers.fold(0.0,
        (sum, worker) => sum + ((worker['salary'] as num?)?.toDouble() ?? 0.0));
    double utilitySum = utilityBills.fold(0.0,
        (sum, bill) => sum + ((bill['amount'] as num?)?.toDouble() ?? 0.0));
    double vehicleSum = vehicleExpenses.fold(
        0.0,
        (sum, expense) =>
            sum + ((expense['amount'] as num?)?.toDouble() ?? 0.0));

    setState(() {
      totalCosts = workerSum + utilitySum + vehicleSum;
      totalProfit = totalRevenue - totalCosts;
      profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue * 100) : 0;
    });
  }

  Future<void> _loadWorkers() async {
    try {
      final response = await Supabase.instance.client
          .from('workers')
          .select()
          .order('name', ascending: true);
      setState(() {
        workers = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading workers: $e');
    }
  }

  Future<void> _loadUtilityBills() async {
    try {
      final response = await Supabase.instance.client
          .from('business_expenses')
          .select()
          .eq('category', 'Utility')
          .order('item_name');
      setState(() {
        utilityBills = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading utility bills: $e');
    }
  }

  Future<void> _loadVehicleExpenses() async {
    try {
      final response = await Supabase.instance.client
          .from('business_expenses')
          .select()
          .eq('category', 'Vehicle')
          .order('item_name');
      setState(() {
        vehicleExpenses = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading vehicle expenses: $e');
    }
  }

  Future<void> _loadFinancialData() async {
    try {
      final response = await Supabase.instance.client
          .from('financial_records')
          .select()
          .order('date', ascending: false)
          .limit(30);
      setState(() {
        financialRecords = List<Map<String, dynamic>>.from(response);
        totalRevenue = financialRecords.fold(
            0.0,
            (sum, record) =>
                sum + ((record['revenue'] as num?)?.toDouble() ?? 0.0));
      });
    } catch (e) {
      print('Error loading financial data: $e');
    }
  }

  Future<void> _loadInventoryStats() async {
    try {
      final response =
          await Supabase.instance.client.from('inventory').select().limit(50);
      final inventory = List<Map<String, dynamic>>.from(response);

      double weight = 0.0;
      double priceSum = 0.0;

      for (var item in inventory) {
        weight += (item['stock_tons'] as num?)?.toDouble() ?? 0.0;
        priceSum += (item['unit_price'] as num?)?.toDouble() ?? 0.0;
      }

      setState(() {
        totalInventoryWeight = weight;
        averageUnitPrice =
            inventory.isNotEmpty ? priceSum / inventory.length : 0.0;
      });
    } catch (e) {
      print('Error loading inventory stats: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: costAlert,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: primary,
        ),
      );
    }
  }

  Widget _buildCostsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cost Breakdown',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '\$${totalCosts.toStringAsFixed(0)}',
              style: const TextStyle(
                color: primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCostCategoryChip('Worker Salary'),
              _buildCostCategoryChip('Utility Bills'),
              _buildCostCategoryChip('Vehicle'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_selectedCostCategory == 'Worker Salary')
          _buildWorkerSalaryCards()
        else if (_selectedCostCategory == 'Utility Bills')
          _buildUtilityBillCards()
        else if (_selectedCostCategory == 'Vehicle')
          _buildVehicleExpenseCards(),
      ],
    );
  }

  Widget _buildCostCategoryChip(String category) {
    bool isSelected = _selectedCostCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCostCategory = category),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary : surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primary : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? backgroundDark : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerSalaryCards() {
    if (workers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surfaceHighlight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No workers found',
            style: TextStyle(color: textSecondary),
          ),
        ),
      );
    }
    return Column(
      children: workers
          .map((worker) => _buildEditableExpenseCard(
                title: worker['name'] ?? 'Unknown Worker',
                subtitle: worker['role'] ?? 'Staff',
                amount: (worker['salary'] as num?)?.toDouble() ?? 0.0,
                id: worker['id'],
                table: 'workers',
                field: 'salary',
                icon: Icons.person,
                iconColor: Colors.blue,
              ))
          .toList(),
    );
  }

  Widget _buildUtilityBillCards() {
    if (utilityBills.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surfaceHighlight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No utility bills found',
            style: TextStyle(color: textSecondary),
          ),
        ),
      );
    }
    return Column(
      children: utilityBills
          .map((bill) => _buildEditableExpenseCard(
                title: bill['item_name'] ?? 'Unknown Bill',
                subtitle: 'Utility Bill',
                amount: (bill['amount'] as num?)?.toDouble() ?? 0.0,
                id: bill['id'],
                table: 'business_expenses',
                field: 'amount',
                icon: Icons.lightbulb,
                iconColor: Colors.yellow,
              ))
          .toList(),
    );
  }

  Widget _buildVehicleExpenseCards() {
    if (vehicleExpenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surfaceHighlight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No vehicle expenses found',
            style: TextStyle(color: textSecondary),
          ),
        ),
      );
    }
    return Column(
      children: vehicleExpenses
          .map((expense) => _buildEditableExpenseCard(
                title: expense['item_name'] ?? 'Unknown Expense',
                subtitle: 'Vehicle Expense',
                amount: (expense['amount'] as num?)?.toDouble() ?? 0.0,
                id: expense['id'],
                table: 'business_expenses',
                field: 'amount',
                icon: Icons.directions_car,
                iconColor: Colors.red,
              ))
          .toList(),
    );
  }

  Widget _buildEditableExpenseCard({
    required String title,
    required String subtitle,
    required double amount,
    required int id,
    required String table,
    required String field,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceHighlight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '৳${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () =>
                    _showEditAmountDialog(id, table, field, amount, title),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditAmountDialog(int id, String table, String field,
      double currentAmount, String itemName) {
    final controller =
        TextEditingController(text: currentAmount.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.edit, color: primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Edit:  $itemName',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount (৳)',
                labelStyle: const TextStyle(color: textSecondary),
                prefixIcon:
                    const Icon(Icons.attach_money, color: textSecondary),
                filled: true,
                fillColor: surfaceHighlight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Current:  ৳${currentAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final newAmount = double.tryParse(controller.text) ?? 0.0;
              if (newAmount < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Amount cannot be negative'),
                    backgroundColor: costAlert,
                  ),
                );
                return;
              }

              try {
                await Supabase.instance.client.from(table).update({
                  field: newAmount,
                  'updated_at': DateTime.now().toIso8601String(),
                }).eq('id', id);

                Navigator.pop(context);
                await _refreshAllData();
                _showSuccessSnackBar('Updated successfully! ');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating:  $e'),
                    backgroundColor: costAlert,
                  ),
                );
              }
            },
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: backgroundDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    List<FlSpot> profitSpots = [];
    List<FlSpot> revenueSpots = [];
    List<FlSpot> costSpots = [];
    double maxValue = 100;

    if (financialRecords.isNotEmpty) {
      final sorted = List<Map<String, dynamic>>.from(financialRecords);
      sorted.sort((a, b) {
        final dateA = DateTime.parse(a['date'].toString());
        final dateB = DateTime.parse(b['date'].toString());
        return dateA.compareTo(dateB);
      });

      final last7 =
          sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;

      for (int i = 0; i < last7.length; i++) {
        double revenue = (last7[i]['revenue'] as num?)?.toDouble() ?? 0.0;
        double profit = (last7[i]['profit'] as num?)?.toDouble() ?? 0.0;

        revenueSpots.add(FlSpot(i.toDouble(), revenue));
        profitSpots.add(FlSpot(i.toDouble(), profit));
        costSpots.add(FlSpot(i.toDouble(), revenue - profit));

        if (revenue > maxValue) maxValue = revenue;
        if (profit > maxValue) maxValue = profit;
      }
    }

    if (profitSpots.isEmpty) {
      profitSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
      revenueSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
      costSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
      maxValue = 100;
    }

    List<FlSpot> selectedSpots;
    Color lineColor;
    String lineLabel;

    if (_selectedMetric == 'Revenue') {
      selectedSpots = revenueSpots;
      lineColor = const Color(0xFF6C63FF);
      lineLabel = 'Revenue Trend';
    } else if (_selectedMetric == 'Costs') {
      selectedSpots = costSpots;
      lineColor = costAlert;
      lineLabel = 'Cost Trend';
    } else {
      selectedSpots = profitSpots;
      lineColor = primary;
      lineLabel = 'Profit Trend';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceHighlight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lineLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: maxValue / 5,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxValue / 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '৳${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                minX: 0,
                maxX: selectedSpots.isNotEmpty ? selectedSpots.length - 1.0 : 1,
                minY: 0,
                maxY: maxValue * 1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: selectedSpots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: lineColor,
                          strokeColor: lineColor,
                          strokeWidth: 2,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withOpacity(0.2),
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

  Widget _buildCostBreakdownPieChart() {
    double workerSum = workers.fold(0.0,
        (sum, worker) => sum + ((worker['salary'] as num?)?.toDouble() ?? 0.0));
    double utilitySum = utilityBills.fold(0.0,
        (sum, bill) => sum + ((bill['amount'] as num?)?.toDouble() ?? 0.0));
    double vehicleSum = vehicleExpenses.fold(
        0.0,
        (sum, expense) =>
            sum + ((expense['amount'] as num?)?.toDouble() ?? 0.0));

    List<PieChartSectionData> sections = [];

    if (workerSum > 0) {
      sections.add(
        PieChartSectionData(
          value: workerSum,
          title:
              'Workers\n${totalCosts > 0 ? (workerSum / totalCosts * 100).toStringAsFixed(1) : '0'}%',
          color: Colors.blue,
          radius: 60,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );
    }

    if (utilitySum > 0) {
      sections.add(
        PieChartSectionData(
          value: utilitySum,
          title:
              'Utilities\n${totalCosts > 0 ? (utilitySum / totalCosts * 100).toStringAsFixed(1) : '0'}%',
          color: Colors.yellow,
          radius: 60,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );
    }

    if (vehicleSum > 0) {
      sections.add(
        PieChartSectionData(
          value: vehicleSum,
          title:
              'Vehicles\n${totalCosts > 0 ? (vehicleSum / totalCosts * 100).toStringAsFixed(1) : '0'}%',
          color: Colors.red,
          radius: 60,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );
    }

    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          value: 1,
          title: 'No Data',
          color: Colors.grey,
          radius: 60,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceHighlight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cost Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Workers', Colors.blue, workerSum),
              _buildLegendItem('Utilities', Colors.yellow, utilitySum),
              _buildLegendItem('Vehicles', Colors.red, vehicleSum),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double value) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: textSecondary,
            fontSize: 11,
          ),
        ),
        Text(
          '৳${value.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentButton(String label) {
    bool isSelected = _selectedMetric == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMetric = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? backgroundDark : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceHighlight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
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

  Widget _buildChartCard() {
    double displayValue = _selectedMetric == 'Revenue'
        ? totalRevenue
        : (_selectedMetric == 'Costs' ? totalCosts : totalProfit);

    String metricText = _selectedMetric == 'Revenue'
        ? 'Total Revenue'
        : _selectedMetric == 'Costs'
            ? 'Total Costs'
            : 'Net Profit';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [surfaceDark, surfaceHighlight],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metricText,
            style: const TextStyle(color: textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '৳${displayValue.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildLineChart(),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> record) {
    final profit = (record['profit'] as num?)?.toDouble() ?? 0.0;
    final dateStr = record['date']?.toString().split('T')[0] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceHighlight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateStr,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          Text(
            '৳${profit.toStringAsFixed(2)}',
            style: TextStyle(
              color: profit >= 0 ? primary : costAlert,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleScaffold(
      screenName: 'financial_overview',
      body: Scaffold(
        backgroundColor: backgroundDark,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshAllData,
            color: primary,
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primary),
                  )
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.analytics,
                                        color: primary, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Financial Overview',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Real-time cost tracking & profit analysis',
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: surfaceDark,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    _buildSegmentButton('Profit'),
                                    _buildSegmentButton('Revenue'),
                                    _buildSegmentButton('Costs'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildChartCard(),
                              const SizedBox(height: 32),
                              if (_selectedMetric != 'Costs')
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 20,
                                  crossAxisSpacing: 20,
                                  childAspectRatio: 1.4,
                                  children: [
                                    _buildStatCard(
                                      icon: '♻️',
                                      iconColor: Colors.blue,
                                      title: 'In Inventory',
                                      value:
                                          '${totalInventoryWeight.toStringAsFixed(2)} tons',
                                    ),
                                    _buildStatCard(
                                      icon: '💰',
                                      iconColor: Colors.yellow,
                                      title: 'Avg.  Market Price',
                                      value:
                                          '৳${averageUnitPrice.toStringAsFixed(2)}/t',
                                    ),
                                    _buildStatCard(
                                      icon: '🚛',
                                      iconColor: Colors.red,
                                      title: 'Total Expenses',
                                      value:
                                          '৳${totalCosts.toStringAsFixed(0)}',
                                    ),
                                    _buildStatCard(
                                      icon: '📊',
                                      iconColor: primary,
                                      title: 'Net Margin',
                                      value:
                                          '${profitMargin.toStringAsFixed(1)}%',
                                    ),
                                  ],
                                ),
                              if (_selectedMetric == 'Costs')
                                Column(
                                  children: [
                                    const SizedBox(height: 32),
                                    _buildCostBreakdownPieChart(),
                                    const SizedBox(height: 32),
                                    _buildCostsSection(),
                                  ],
                                ),
                              if (_selectedMetric != 'Costs')
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 32),
                                    const Text(
                                      'Recent Transactions',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...financialRecords.take(5).map((record) =>
                                        _buildTransactionTile(record)),
                                  ],
                                ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
