import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ==================== DASHBOARD STATS ====================
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _client
          .from('dashboard_stats')
          .select()
          .order('updated_at', ascending: false)
          .limit(1)
          .single();
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return {};
    }
  }

  Future<void> updateDashboardStats({
    required int pickupsToday,
    required int activeTrucks,
    required int totalTrucks,
    required int pendingIssues,
    required double totalProfit,
  }) async {
    try {
      await _client.from('dashboard_stats').upsert(
        {
          'id': 1, // Single row
          'pickups_today': pickupsToday,
          'active_trucks': activeTrucks,
          'total_trucks': totalTrucks,
          'pending_issues': pendingIssues,
          'total_profit': totalProfit,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'id',
      );
    } catch (e) {
      print('Error updating dashboard stats: $e');
      rethrow;
    }
  }

  // ==================== WORKERS ====================
  Future<List<Map<String, dynamic>>> getWorkers() async {
    try {
      final response = await _client
          .from('workers')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching workers: $e');
      return [];
    }
  }

  Future<void> addWorker({
    required String name,
    required String role,
    required String status,
    String? profileUrl,
    String? number,
  }) async {
    try {
      await _client.from('workers').insert({
        'name': name,
        'role': role,
        'status': status,
        'profile_url': profileUrl,
        'number': number,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding worker: $e');
      rethrow;
    }
  }

  Future<void> updateWorker({
    required int id,
    required String name,
    required String role,
    String? number,
  }) async {
    try {
      await _client.from('workers').update({
        'name': name,
        'role': role,
        'number': number,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      print('Error updating worker: $e');
      rethrow;
    }
  }

  Future<void> updateWorkerStatus(int id, String newStatus) async {
    try {
      await _client.from('workers').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      print('Error updating worker status: $e');
      rethrow;
    }
  }

  Future<void> deleteWorker(int id) async {
    try {
      await _client.from('workers').delete().eq('id', id);
    } catch (e) {
      print('Error deleting worker: $e');
      rethrow;
    }
  }

  // ==================== INVENTORY ====================
  Future<List<Map<String, dynamic>>> getInventoryItems() async {
    try {
      final response = await _client
          .from('inventory')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching inventory: $e');
      return [];
    }
  }

  Future<void> addInventoryItem({
    required String title,
    required String subtitle,
    String? imageUrl,
    required double stockTons,
    required double unitPrice,
    required double maxCapacityTons,
  }) async {
    try {
      await _client.from('inventory').insert({
        'title': title,
        'subtitle': subtitle,
        'image_url': imageUrl ?? '',
        'stock_tons': stockTons,
        'unit_price': unitPrice,
        'max_capacity_tons': maxCapacityTons,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding inventory item: $e');
      rethrow;
    }
  }

  Future<void> updateInventoryStock(int id, double newStockTons) async {
    try {
      await _client.from('inventory').update({
        'stock_tons': newStockTons,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      print('Error updating inventory stock: $e');
      rethrow;
    }
  }

  Future<void> deleteInventoryItem(int id) async {
    try {
      await _client.from('inventory').delete().eq('id', id);
    } catch (e) {
      print('Error deleting inventory item: $e');
      rethrow;
    }
  }

  // ==================== FINANCIAL RECORDS ====================
  Future<List<Map<String, dynamic>>> getFinancialRecords({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _client.from('financial_records').select();

      if (fromDate != null) {
        query = query.gte('date', fromDate.toIso8601String().split('T'));
      }
      if (toDate != null) {
        query = query.lte('date', toDate.toIso8601String().split('T'));
      }

      final response = await query.order('date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching financial records: $e');
      return [];
    }
  }

  Future<void> addFinancialRecord({
    required DateTime date,
    required double profit,
    required double revenue,
    required double costs,
  }) async {
    try {
      await _client.from('financial_records').insert({
        'date': date.toIso8601String().split('T'),
        'profit': profit,
        'revenue': revenue,
        'costs': costs,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding financial record: $e');
      rethrow;
    }
  }

  // ==================== WASTE STOCKS ====================
  Future<List<Map<String, dynamic>>> getWasteStocks() async {
    try {
      final response = await _client
          .from('waste_stocks')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching waste stocks: $e');
      return [];
    }
  }

  Future<void> updateWasteStock({
    required int id,
    required double tonnage,
    required int percent,
  }) async {
    try {
      await _client.from('waste_stocks').update({
        'tonnage': tonnage,
        'percent': percent,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      print('Error updating waste stock: $e');
      rethrow;
    }
  }

  // ==================== AGGREGATION HELPERS ====================
  Future<double> getTotalProfit() async {
    try {
      final response = await _client
          .from('financial_records')
          .select('profit')
          .order('date', ascending: false);

      double total = 0;
      for (var record in response) {
        total += (record['profit'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (e) {
      print('Error calculating total profit: $e');
      return 0;
    }
  }

  Future<double> getTotalRevenue() async {
    try {
      final response = await _client
          .from('financial_records')
          .select('revenue')
          .order('date', ascending: false);

      double total = 0;
      for (var record in response) {
        total += (record['revenue'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (e) {
      print('Error calculating total revenue: $e');
      return 0;
    }
  }

  Future<double> getTotalStockTons() async {
    try {
      final response = await _client.from('inventory').select('stock_tons');

      double total = 0;
      for (var item in response) {
        total += (item['stock_tons'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (e) {
      print('Error calculating total stock: $e');
      return 0;
    }
  }

  // ==================== PAYMENTS ====================
  Future<void> recordPayment({
    required double amount,
    String? description,
    String status = 'completed',
  }) async {
    try {
      await _client.from('payments').insert({
        'amount': amount,
        'description': description ?? 'Payment received',
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error recording payment: $e');
      rethrow;
    }
  }

  Future<double> getTotalPayments() async {
    try {
      final response =
          await _client.from('payments').select().eq('status', 'completed');
      double total = 0;
      for (var payment in response) {
        total += (payment['amount'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (e) {
      print('Error fetching total payments: $e');
      return 0;
    }
  }

  // ==================== NOTIFICATIONS ====================
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> createNotification({
    required String title,
    required String type,
  }) async {
    try {
      await _client.from('notifications').insert({
        'title': title,
        'type': type,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  Future<void> completeNotification({
    required String notificationId,
  }) async {
    try {
      await _client
          .from('notifications')
          .update({'status': 'completed'}).eq('id', notificationId);
    } catch (e) {
      print('Error completing notification: $e');
      rethrow;
    }
  }

  Future<int> getPendingNotificationsCount() async {
    try {
      final response =
          await _client.from('notifications').select().eq('status', 'pending');
      return response.length;
    } catch (e) {
      print('Error getting pending notifications count: $e');
      return 0;
    }
  }
}
