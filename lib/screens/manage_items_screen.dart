import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'edit_registered_item_screen.dart';
import '../config/api_config.dart';
import '../utils/ui_utils.dart';

/// Mode controls which tabs are shown:
/// 'rentals'  → Vehicles + Equipment
/// 'services' → Services + Workers
/// null / unset → all 4 tabs (used by My Registered Items menu entry)
class ManageItemsScreen extends StatefulWidget {
  final int initialTabIndex;
  final String? mode; // 'rentals' | 'services' | null (all)
  const ManageItemsScreen({super.key, this.initialTabIndex = 0, this.mode});

  @override
  State<ManageItemsScreen> createState() => _ManageItemsScreenState();
}

class _ManageItemsScreenState extends State<ManageItemsScreen> {
  final ApiService _apiService = ApiService();
  String? _userId;
  bool _isLoading = true;
  bool _isInitialLoading = true;
  bool _showSpinner = false;

  List<dynamic> _vehicles = [];
  List<dynamic> _equipment = [];
  List<dynamic> _services = [];
  List<dynamic> _workerGroups = [];

  bool get _isRentalsMode => widget.mode == 'rentals';
  bool get _isServicesMode => widget.mode == 'services';

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _isLoading && _isInitialLoading) {
        setState(() => _showSpinner = true);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');

      if (_userId != null) {
        if (_isRentalsMode) {
          // Only fetch vehicles + equipment for Rentals screen
          final results = await Future.wait([
            _apiService.getVehicles(ownerId: _userId).catchError((_) => <dynamic>[]),
            _apiService.getEquipment(ownerId: _userId).catchError((_) => <dynamic>[]),
          ]);
          if (mounted) {
            setState(() {
              _vehicles = results[0] as List<dynamic>? ?? [];
              _equipment = results[1] as List<dynamic>? ?? [];
            });
          }
        } else if (_isServicesMode) {
          // Only fetch services + workers for Services screen
          final results = await Future.wait([
            _apiService.getServices(ownerId: _userId).catchError((_) => <dynamic>[]),
            _apiService.getWorkerGroups(ownerId: _userId).catchError((_) => <dynamic>[]),
          ]);
          if (mounted) {
            setState(() {
              _services = results[0] as List<dynamic>? ?? [];
              _workerGroups = results[1] as List<dynamic>? ?? [];
            });
          }
        } else {
          // All mode — fetch everything (used by My Registered Items)
          final results = await Future.wait([
            _apiService.getVehicles(ownerId: _userId).catchError((_) => <dynamic>[]),
            _apiService.getEquipment(ownerId: _userId).catchError((_) => <dynamic>[]),
            _apiService.getServices(ownerId: _userId).catchError((_) => <dynamic>[]),
            _apiService.getWorkerGroups(ownerId: _userId).catchError((_) => <dynamic>[]),
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
      }
    } catch (e) {
      debugPrint('Failed to load items: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoading = false;
          _showSpinner = false;
        });
      }
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

  List<Tab> get _tabs {
    if (_isRentalsMode) return const [Tab(text: 'Vehicles'), Tab(text: 'Equipment')];
    if (_isServicesMode) return const [Tab(text: 'Services'), Tab(text: 'Workers')];
    return const [Tab(text: 'Vehicles'), Tab(text: 'Equipment'), Tab(text: 'Services'), Tab(text: 'Workers')];
  }

  List<Widget> get _tabViews {
    if (_isRentalsMode) {
      return [
        _buildList(_vehicles, 'Vehicle', 'vehicleId', (item) => '${item["vehicleType"]}', (item) {
          final business = item["ownerBusinessName"] ?? item["ownerName"] ?? '';
          final num = item["vehicleNumber"] ?? "N/A";
          final price = item["pricePerKmOrTrip"];
          return '${business.isNotEmpty ? "$business • " : ""}Num: $num • ₹$price';
        }),
        _buildList(_equipment, 'Equipment', 'equipmentId', (item) => '${item["brandModel"]}', (item) {
          final unit = item["category"] == 'Sprayers' ? '/litre' : '/hr';
          return '${item["ownerBusinessName"] ?? item["ownerName"] ?? "Provider"} • ${item["category"]} • ₹${item["pricePerHour"]}$unit';
        }),
      ];
    }
    if (_isServicesMode) {
      return [
        _buildList(_services, 'Service', 'serviceId', (item) => '${item["serviceType"]}', (item) => '${item["businessName"]} • ₹${item["priceRate"]}'),
        _buildList(_workerGroups, 'WorkerGroup', 'groupId', (item) => 'Farm Workers', (item) => '${item["groupName"]} • ${item["maleCount"]}M, ${item["femaleCount"]}F'),
      ];
    }
    return [
      _buildList(_vehicles, 'Vehicle', 'vehicleId', (item) => '${item["vehicleType"]}', (item) {
        final business = item["ownerBusinessName"] ?? item["ownerName"] ?? '';
        final num = item["vehicleNumber"] ?? "N/A";
        final price = item["pricePerKmOrTrip"];
        return '${business.isNotEmpty ? "$business • " : ""}Num: $num • ₹$price';
      }),
      _buildList(_equipment, 'Equipment', 'equipmentId', (item) => '${item["brandModel"]}', (item) {
        final unit = item["category"] == 'Sprayers' ? '/litre' : '/hr';
        return '${item["ownerBusinessName"] ?? item["ownerName"] ?? "Provider"} • ${item["category"]} • ₹${item["pricePerHour"]}$unit';
      }),
      _buildList(_services, 'Service', 'serviceId', (item) => '${item["serviceType"]}', (item) => '${item["businessName"]} • ₹${item["priceRate"]}'),
      _buildList(_workerGroups, 'WorkerGroup', 'groupId', (item) => 'Farm Workers', (item) => '${item["groupName"]} • ${item["maleCount"]}M, ${item["femaleCount"]}F'),
    ];
  }

  String get _screenTitle {
    if (_isRentalsMode) return 'My Rentals';
    if (_isServicesMode) return 'My Services';
    return 'Manage Assets';
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    return DefaultTabController(
      length: tabs.length,
      initialIndex: widget.initialTabIndex.clamp(0, tabs.length - 1),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F2),
        appBar: AppBar(
          title: Text(_screenTitle, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1B5E20))),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00AA55)),
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchItems();
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
              ),
              child: TabBar(
                isScrollable: tabs.length > 2,
                labelColor: const Color(0xFF00AA55),
                indicatorColor: const Color(0xFF00AA55),
                indicatorWeight: 3,
                unselectedLabelColor: const Color(0xFF90A4AE),
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.3),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                indicatorSize: TabBarIndicatorSize.label,
                tabs: tabs,
              ),
            ),
          ),
        ),
        body: _isLoading && _isInitialLoading
            ? (_showSpinner ? const Center(child: CircularProgressIndicator(color: Color(0xFF00AA55))) : const SizedBox.shrink())
            : RefreshIndicator(
                onRefresh: _fetchItems,
                color: const Color(0xFF00AA55),
                child: TabBarView(
                  children: _tabViews,
                ),
              ),
      ),
    );
  }

  Widget _buildList(List<dynamic> items, String category, String idKey, String Function(Map<String, dynamic>) titleGetter, String Function(Map<String, dynamic>) subtitleGetter) {
    if (items.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
                ),
                child: Icon(Icons.inventory_2_rounded, size: 64, color: Colors.grey[300]),
              ),
              const SizedBox(height: 24),
              Text(
                'No $category registered yet', 
                style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your assets to start earning', 
                style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index] as Map<String, dynamic>;
        String? imgPath = item['imageUrl'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05), 
                blurRadius: 20, 
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    ApiConfig.getFullImageUrl(imgPath),
                    width: 75, height: 75, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 75, height: 75, 
                      color: const Color(0xFFF1F8F1), 
                      child: const Icon(Icons.image_outlined, color: Color(0xFF00AA55)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleGetter(item), 
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1B5E20), letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitleGetter(item), 
                        style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      _buildStatusBadge(item['isAvailable'] ?? true),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Color(0xFF00AA55), size: 22),
                      onPressed: () => _navigateToEdit(category, item),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE57373), size: 22),
                      onPressed: () => _deleteItem(category, item[idKey]),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(bool isAvailable) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String text;

    if (isAvailable) {
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
      icon = Icons.check_circle_outline_rounded;
      text = 'ACTIVATED';
    } else {
      bgColor = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFC62828);
      icon = Icons.cancel_outlined;
      text = 'DEACTIVATED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor, 
              fontSize: 10, 
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
