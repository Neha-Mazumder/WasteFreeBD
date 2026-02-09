import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/payment_store.dart';

class PaymentHistoryPage extends StatelessWidget {
  final bool isDark;
  PaymentHistoryPage({required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color bg = isDark ? Color(0xFF121212) : Colors.white;
    Color txt = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text("Payment History", style: TextStyle(color: txt)),
        backgroundColor: bg,
        foregroundColor: txt,
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: PaymentStore.payments,
        builder: (context, payments, _) {
          final int count = payments.length;
          final int total = payments.fold<int>(0, (sum, p) {
            final v = p['amount'];
            if (v is int) return sum + v;
            return sum + (int.tryParse(v?.toString() ?? '') ?? 0);
          });

          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("No payments yet", style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 12),
                  Text("Payments: 0   •   Total: ৳0", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF2A2A2A) : Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Payments", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          SizedBox(height: 4),
                          Text("$count", style: TextStyle(color: txt, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Total", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          SizedBox(height: 4),
                          Text("৳ $total", style: TextStyle(color: Color(0xFF2ECC71), fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = payments[index];
                      final dt = DateTime.tryParse(p['timestamp'] ?? '') ?? DateTime.now();
                      final formatted = DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
                      return Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xFF2A2A2A) : Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("৳ ${p['amount']}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: txt)),
                                SizedBox(height: 6),
                                Text(p['method'] ?? '', style: TextStyle(color: Colors.grey)),
                                SizedBox(height: 4),
                                Text(p['phone'] ?? '', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatted, style: TextStyle(color: Colors.grey, fontSize: 12)),
                                SizedBox(height: 6),
                                Icon(Icons.check_circle, color: Color(0xFF2ECC71)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}