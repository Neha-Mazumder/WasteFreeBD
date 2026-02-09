import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkerManagementScreen extends StatefulWidget {
  const WorkerManagementScreen({super.key});

  @override
  State<WorkerManagementScreen> createState() => _WorkerManagementScreenState();
}

class _WorkerManagementScreenState extends State<WorkerManagementScreen> {
  // Color scheme
  static const Color primary = Color(0xFF13EC5B);
  static const Color backgroundDark = Color(0xFF102216);
  static const Color surfaceHighlight = Color(0xFF23482F);
  static const Color textSecondary = Color(0xFF92C9A4);

  // State variables
  bool isLoading = true;
  List<Map<String, dynamic>> workers = [];
  String selectedFilter = 'ALL';

  // Status colors
  final Map<String, Color> statusColors = {
    'ACTIVE': const Color(0xFF13EC5B),
    'BREAK': Colors.orange,
    'OFFLINE': Colors.grey,
    'SICK': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  /// Load workers from Supabase
  Future<void> _loadWorkers() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await Supabase.instance.client
          .from('workers')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        workers = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading workers: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading workers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Add new worker
  Future<void> _addWorker({
    required String name,
    required String role,
    required String status,
    required String phone,
  }) async {
    try {
      await Supabase.instance.client.from('workers').insert({
        'name': name,
        'role': role,
        'status': status,
        'number': phone,
        'profile_url': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _loadWorkers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Worker added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error adding worker: $e');
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

  /// Update worker
  Future<void> _updateWorker({
    required int id,
    required String name,
    required String role,
    required String phone,
  }) async {
    try {
      await Supabase.instance.client.from('workers').update({
        'name': name,
        'role': role,
        'number': phone,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

      await _loadWorkers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Worker updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating worker: $e');
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

  /// Update worker status
  Future<void> _updateWorkerStatus({
    required int id,
    required String newStatus,
  }) async {
    try {
      await Supabase.instance.client.from('workers').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

      await _loadWorkers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating status: $e');
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

  /// Delete worker
  Future<void> _deleteWorker(int id) async {
    try {
      await Supabase.instance.client.from('workers').delete().eq('id', id);

      await _loadWorkers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Worker deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting worker: $e');
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

  /// Show add worker dialog
  void _showAddWorkerDialog() {
    final nameController = TextEditingController();
    final roleController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedStatus = 'ACTIVE';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceHighlight,
        title: const Text(
          'Add Worker',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
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
                  controller: roleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Role',
                    labelStyle: const TextStyle(color: textSecondary),
                    hintText: 'e.g., Driver, Manager',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
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
                  initialValue: selectedStatus,
                  dropdownColor: backgroundDark,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: const TextStyle(color: textSecondary),
                    filled: true,
                    fillColor: backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: ['ACTIVE', 'BREAK', 'OFFLINE', 'SICK']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedStatus = value ?? 'ACTIVE';
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final role = roleController.text.trim();
              final phone = phoneController.text.trim();

              if (name.isEmpty || role.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              _addWorker(
                name: name,
                role: role,
                status: selectedStatus,
                phone: phone,
              );

              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: primary)),
          ),
        ],
      ),
    );
  }

  /// Show edit worker dialog
  void _showEditWorkerDialog(Map<String, dynamic> worker) {
    final nameController = TextEditingController(
      text: worker['name'] ?? '',
    );
    final roleController = TextEditingController(
      text: worker['role'] ?? '',
    );
    final phoneController = TextEditingController(
      text: worker['number'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceHighlight,
        title: const Text(
          'Edit Worker',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Full Name',
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
                controller: roleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Role',
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
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
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
              _updateWorker(
                id: worker['id'],
                name: nameController.text.trim(),
                role: roleController.text.trim(),
                phone: phoneController.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Update', style: TextStyle(color: primary)),
          ),
        ],
      ),
    );
  }

  /// Get filtered workers
  List<Map<String, dynamic>> getFilteredWorkers() {
    if (selectedFilter == 'ALL') {
      return workers;
    }
    return workers
        .where((w) => (w['status'] ?? 'OFFLINE') == selectedFilter)
        .toList();
  }

  /// Build worker card
  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    final status = worker['status'] ?? 'OFFLINE';
    final statusColor = statusColors[status] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceHighlight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: statusColor.withOpacity(0.2),
                child: Icon(
                  Icons.person,
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker['name'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      worker['role'] ?? 'No role',
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
                    onTap: () => _showEditWorkerDialog(worker),
                  ),
                  PopupMenuItem<String>(
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () => _deleteWorker(worker['id']),
                  ),
                ],
                child: const Icon(Icons.more_vert, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phone: ${worker['number'] ?? 'N/A'}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: surfaceHighlight,
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    child: const Text(
                      'Active',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () => _updateWorkerStatus(
                      id: worker['id'],
                      newStatus: 'ACTIVE',
                    ),
                  ),
                  PopupMenuItem<String>(
                    child: const Text(
                      'Break',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () => _updateWorkerStatus(
                      id: worker['id'],
                      newStatus: 'BREAK',
                    ),
                  ),
                  PopupMenuItem<String>(
                    child: const Text(
                      'Offline',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () => _updateWorkerStatus(
                      id: worker['id'],
                      newStatus: 'OFFLINE',
                    ),
                  ),
                  PopupMenuItem<String>(
                    child: const Text(
                      'Sick',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () => _updateWorkerStatus(
                      id: worker['id'],
                      newStatus: 'SICK',
                    ),
                  ),
                ],
                child: Chip(
                  label: Text(
                    'Change Status',
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                  backgroundColor: statusColor.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build filter chip
  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Colors adapted for light and dark themes
    final Color unselectedBg = isLight ? Colors.white : Colors.transparent;
    final Color unselectedLabel = isLight ? Colors.black87 : Colors.white;
    final Color unselectedBorder =
        isLight ? Colors.grey.shade300 : Colors.white10;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedFilter = selected ? label : 'ALL';
        });
      },
      selectedColor: primary,
      backgroundColor: unselectedBg,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : unselectedLabel,
        fontWeight: FontWeight.bold,
      ),
      side: BorderSide(
        color: isSelected ? primary : unselectedBorder,
      ),
      showCheckmark: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredWorkers = getFilteredWorkers();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 254, 249),
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
                          'Worker Management',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _loadWorkers,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Worker count card
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
                            'Total Workers',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${workers.length}',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 17, 15, 15),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.people,
                        color: primary.withOpacity(0.5),
                        size: 40,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter by Status',
                      style: TextStyle(
                        color: Color.fromARGB(255, 21, 19, 19),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChip('ALL'),
                        _buildFilterChip('ACTIVE'),
                        _buildFilterChip('BREAK'),
                        _buildFilterChip('OFFLINE'),
                        _buildFilterChip('SICK'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Workers list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Workers',
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
                    else if (filteredWorkers.isEmpty)
                      Container(
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
                      )
                    else
                      Column(
                        children: filteredWorkers
                            .map((worker) => _buildWorkerCard(worker))
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
        onPressed: _showAddWorkerDialog,
        child: const Icon(Icons.add, color: backgroundDark),
      ),
    );
  }
}
