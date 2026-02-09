import 'package:flutter/material.dart';
import '../supabase_client.dart';

class DashboardProvider extends ChangeNotifier {
  int pickupsToday = 0;
  int activeTrucks = 0;
  int totalTrucks = 0;
  int pendingIssues = 0;
  double totalProfit = 0.0;

  Future<void> fetchStats() async {
    try {
      final response = await supabase.from('dashboard_stats').select().single();
      pickupsToday = response['pickups_today'] ?? 0;
      activeTrucks = response['active_trucks'] ?? 0;
      totalTrucks = response['total_trucks'] ?? 0;
      pendingIssues = response['pending_issues'] ?? 0;
      totalProfit = (response['total_profit'] ?? 0).toDouble();
      notifyListeners();
    } catch (e) {
      // ignore errors for now; callers can handle
    }
  }
}
