import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
// If your models are located somewhere, import them too. Or we can just use maps for now.
import 'edit_registered_item_screen.dart';

class ManageItemsScreen extends StatefulWidget {
  const ManageItemsScreen({Key? key}) : super(key: key);

  @override
  State<ManageItemsScreen> createState() => _ManageItemsScreenState();
}

class _ManageItemsScreenState extends State<ManageItemsScreen> {
  final ApiService _apiService = ApiService();
  String? _userId;
  bool _isLoading = true;

  List<dynamic> _vehicles = [];
  List<dynamic> _equipment = [];
  List<dynamic> _services = [];
  List<dynamic> _workerGroups = [];

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');

      if (_userId != null) {
        // Fetch all 4 categories in parallel
        final results = await Future.wait([
          _apiService.getVehicles(ownerId: _userId),
          _apiService.getEquipment(ownerId: _userId),
          _apiService.getServices(ownerId: _userId),
          _apiService.getWorkerGroups(ownerId: _userId),
        ]);

        setState(() {
          _vehicles = results[0] as List<dynamic>? ?? [];
          _equipment = results[1] as List<dynamic>? ?? [];
          _services = results[2] as List<dynamic>? ?? [];
          _workerGroups = results[3] as List<dynamic>? ?? [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load items: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(String category, String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      if (category == 'Vehicle') await _apiService.deleteVehicle(id);
      else if (category == 'Equipment') await _apiService.deleteEquipment(id);
      else if (category == 'Service') await _apiService.deleteService(id);
      else if (category == 'WorkerGroup') await _apiService.deleteWorkerGroup(id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$category deleted successfully'), backgroundColor: Colors.green),
      );
      _fetchItems(); // Refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _navigateToEdit(String category, Map<String, dynamic> itemData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRegisteredItemScreen(
          category: category,
          itemData: itemData,
        ),
      ),
    );
    if (result == true) {
      _fetchItems(); // Refresh if updated
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Registered Items'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Vehicles'),
              Tab(text: 'Equipment'),
              Tab(text: 'Services'),
              Tab(text: 'Farm Workers'),
            ],
            labelColor: Color(0xFF00AA55),
            indicatorColor: Color(0xFF00AA55),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildList(_vehicles, 'Vehicle', 'vehicleId', (item) => '${item["vehicleType"]} - ${item["vehicleNumber"] ?? "N/A"}', (item) => 'Price: ₹${item["pricePerKmOrTrip"]}'),
                  _buildList(_equipment, 'Equipment', 'equipmentId', (item) => '${item["brandModel"]}', (item) => 'Category: ${item["category"]} | ₹${item["pricePerHour"]}/hr'),
                  _buildList(_services, 'Service', 'serviceId', (item) => '${item["businessName"]}', (item) => '${item["serviceType"]} | ₹${item["priceRate"]}'),
                  _buildList(_workerGroups, 'WorkerGroup', 'groupId', (item) => '${item["groupName"]}', (item) => '${item["maleCount"]} Men, ${item["femaleCount"]} Women'),
                ],
              ),
      ),
    );
  }

  Widget _buildList(List<dynamic> items, String category, String idKey, String Function(Map<String, dynamic>) titleGetter, String Function(Map<String, dynamic>) subtitleGetter) {
    if (items.isEmpty) {
      return Center(child: Text('No $category found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index] as Map<String, dynamic>;
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(titleGetter(item), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(subtitleGetter(item)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _navigateToEdit(category, item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteItem(category, item[idKey]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
