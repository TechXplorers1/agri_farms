import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'edit_registered_item_screen.dart';
import '../config/api_config.dart';
import '../utils/ui_utils.dart';

class ManageItemsScreen extends StatefulWidget {
  const ManageItemsScreen({super.key});

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
        final results = await Future.wait([
          _apiService.getVehicles(ownerId: _userId),
          _apiService.getEquipment(ownerId: _userId),
          _apiService.getServices(ownerId: _userId),
          _apiService.getWorkerGroups(ownerId: _userId),
        ]);

        if (mounted) {
          setState(() {
            _vehicles = results[0] as List<dynamic>? ?? [];
            _equipment = results[1] as List<dynamic>? ?? [];
            _services = results[2] as List<dynamic>? ?? [];
            _workerGroups = results[3] as List<dynamic>? ?? [];
          });
        }
      }
    } catch (e) {
      if (mounted) UiUtils.showCustomAlert(context, 'Failed to load items: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(String category, String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this item? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red, elevation: 0),
            child: const Text('Delete'),
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

      if (mounted) UiUtils.showCenteredToast(context, '$category deleted successfully');
      _fetchItems();
    } catch (e) {
      if (mounted) UiUtils.showCustomAlert(context, 'Failed to delete: $e', isError: true);
    }
  }

  void _navigateToEdit(String category, Map<String, dynamic> itemData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditRegisteredItemScreen(category: category, itemData: itemData)),
    );
    if (result == true) _fetchItems();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FBF9),
        appBar: AppBar(
          title: const Text('Manage My Assets', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFF2E7D32),
            indicatorColor: Color(0xFF2E7D32),
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: 'Vehicles'),
              Tab(text: 'Equipment'),
              Tab(text: 'Services'),
              Tab(text: 'Workers'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00AA55)))
            : TabBarView(
                children: [
                  _buildList(_vehicles, 'Vehicle', 'vehicleId', (item) => '${item["vehicleType"]}', (item) => 'Num: ${item["vehicleNumber"] ?? "N/A"} • ₹${item["pricePerKmOrTrip"]}'),
                  _buildList(_equipment, 'Equipment', 'equipmentId', (item) => '${item["brandModel"]}', (item) => '${item["category"]} • ₹${item["pricePerHour"]}/hr'),
                  _buildList(_services, 'Service', 'serviceId', (item) => '${item["businessName"]}', (item) => '${item["serviceType"]} • ₹${item["priceRate"]}'),
                  _buildList(_workerGroups, 'WorkerGroup', 'groupId', (item) => '${item["groupName"]}', (item) => '${item["maleCount"]} Men, ${item["femaleCount"]} Women'),
                ],
              ),
      ),
    );
  }

  Widget _buildList(List<dynamic> items, String category, String idKey, String Function(Map<String, dynamic>) titleGetter, String Function(Map<String, dynamic>) subtitleGetter) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No $category registered yet.', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index] as Map<String, dynamic>;
        String? imgPath = item['imageUrl'];

        return Container(
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                ApiConfig.getFullImageUrl(imgPath),
                width: 60, height: 60, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: const Color(0xFFF1F8F1), child: const Icon(Icons.image_outlined, color: Colors.grey)),
              ),
            ),
            title: Text(titleGetter(item), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF2C3E50))),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(subtitleGetter(item), style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF1565C0)),
                  onPressed: () => _navigateToEdit(category, item),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC62828)),
                  onPressed: () => _deleteItem(category, item[idKey]),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
