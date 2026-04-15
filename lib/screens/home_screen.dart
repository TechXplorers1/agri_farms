import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'agri_services_screen.dart';
import 'book_transport_screen.dart';
import 'equipment_rentals_screen.dart';
import 'service_providers_screen.dart';
import 'tools/farming_calculator_screen.dart';
import 'tools/crop_advisory_screen.dart';
import 'provider/provider_requests_screen.dart';
import 'upload_item_screen.dart';
import 'generic_history_screen.dart';
import '../utils/booking_manager.dart';

import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/ui_utils.dart';

class HomeServiceItem {
  final String title;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final String category;
  final Widget navigationTarget;
  final String? imagePath;
  final String? subtitle;
  final bool isComingSoon;

  HomeServiceItem(this.title, this.icon, this.bgColor, this.iconColor,
      this.category, this.navigationTarget,
      {this.imagePath, this.subtitle, this.isComingSoon = false});
}

class HomeScreen extends StatefulWidget {
  final String? userRole;
  final int? initialIndex;

  const HomeScreen({super.key, this.userRole, this.initialIndex});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _userName = 'User';
  String _userLocation = 'Your Village, District';
  String _userRole = 'User';
  int _unreadNotificationCount = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 0;
    _loadUserData();
    _fetchUnreadCount();
    _fetchCurrentLocation();
    _verifyApiConnection();
    NotificationService().updateFCMToken();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _accentGold = Color(0xFFF9A825);
  static const Color _bgColor = Color(0xFFF5F7F2);

  List<HomeServiceItem> _getAllItems(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    return [
      HomeServiceItem(l10n.tractors, Icons.agriculture, Colors.green[50]!, Colors.green, 'Rentals',
          ServiceProvidersScreen(serviceKey: 'Tractors', title: l10n.tractors, userRole: widget.userRole),
          imagePath: 'assets/images/tractor_card.webp', subtitle: 'Plough & Cultivate'),
      HomeServiceItem(l10n.harvesters, Icons.grass, Colors.yellow[50]!, Colors.orange, 'Rentals',
          ServiceProvidersScreen(serviceKey: 'Harvesters', title: l10n.harvesters, userRole: widget.userRole),
          imagePath: 'assets/images/harvester_card.webp', subtitle: 'Wheat & Paddy Harvest'),
      HomeServiceItem(l10n.sprayers, Icons.water_drop, Colors.blue[50]!, Colors.blue, 'Rentals',
          ServiceProvidersScreen(serviceKey: 'Sprayers', title: l10n.sprayers, userRole: widget.userRole),
          imagePath: 'assets/images/sprayer_card.webp', subtitle: 'Pest Control'),
      HomeServiceItem(l10n.trolleys, Icons.shopping_cart_outlined, Colors.grey[100]!, Colors.grey, 'Rentals',
          ServiceProvidersScreen(serviceKey: 'Trolleys', title: l10n.trolleys, userRole: widget.userRole),
          imagePath: 'assets/images/trolley_card.webp', subtitle: 'Load & Carry'),
      HomeServiceItem(l10n.jcb, Icons.construction, Colors.orange[50]!, Colors.orange, 'Rentals',
          ServiceProvidersScreen(serviceKey: 'JCB', title: l10n.jcb, userRole: widget.userRole),
          imagePath: 'assets/images/jcb_card.webp', subtitle: 'Digging & Leveling'),
      HomeServiceItem(l10n.ploughing, Icons.agriculture, const Color(0xFFE3F2FD), Colors.blue, 'Services',
          ServiceProvidersScreen(serviceKey: 'Ploughing', title: l10n.ploughing, userRole: widget.userRole),
          imagePath: 'assets/images/agri_services_card.webp', subtitle: 'Field Preparation'),
      HomeServiceItem(l10n.harvesting, Icons.grass, const Color(0xFFFFF9C4), Colors.orange, 'Services',
          ServiceProvidersScreen(serviceKey: 'Harvesting', title: l10n.harvesting, userRole: widget.userRole),
          imagePath: 'assets/images/harvester_card.webp', subtitle: 'Crop Collection'),
      HomeServiceItem(l10n.farmWorkers, Icons.groups, const Color(0xFFF3E5F5), Colors.purple, 'Services',
          ServiceProvidersScreen(serviceKey: 'Farm Workers', title: l10n.farmWorkers, userRole: widget.userRole),
          imagePath: 'assets/images/farm_workers_card.webp', subtitle: 'Skilled Labour'),
      HomeServiceItem('Electricians', Icons.electrical_services, const Color(0xFFE8F5E9), Colors.green, 'Services',
          ServiceProvidersScreen(serviceKey: 'Electricians', title: 'Electricians', userRole: widget.userRole),
          imagePath: 'assets/images/electrician_card.webp', subtitle: 'Expert Repairs'),
      HomeServiceItem(l10n.droneSpraying, Icons.airplanemode_active, const Color(0xFFE8F5E9), Colors.green, 'Services',
          ServiceProvidersScreen(serviceKey: 'Drone Spraying', title: l10n.droneSpraying, userRole: widget.userRole),
          imagePath: 'assets/images/drone_spraying_card.webp', subtitle: 'Modern Spraying'),
      HomeServiceItem(l10n.soilTesting, Icons.science, const Color(0xFFE8F5E9), Colors.green, 'Services',
          ServiceProvidersScreen(serviceKey: 'Soil Testing', title: l10n.soilTesting, userRole: widget.userRole),
          imagePath: 'assets/images/soil_testing_card.webp', subtitle: 'Know Your Soil', isComingSoon: true),
      HomeServiceItem(l10n.irrigation, Icons.water_drop, const Color(0xFFE1F5FE), Colors.cyan, 'Services',
          ServiceProvidersScreen(serviceKey: 'Irrigation', title: l10n.irrigation, userRole: widget.userRole),
          imagePath: 'assets/images/irrigation_card.webp', subtitle: 'Water Management', isComingSoon: true),
      HomeServiceItem(l10n.vetCare, Icons.pets, const Color(0xFFFCE4EC), Colors.pink, 'Services',
          ServiceProvidersScreen(serviceKey: 'Vet Care', title: l10n.vetCare, userRole: widget.userRole),
          imagePath: 'assets/images/vet_care_card.webp', subtitle: 'Animal Health'),
      HomeServiceItem(l10n.miniTruck, Icons.local_shipping, const Color(0xFFE3F2FD), Colors.blue, 'Transport',
          ServiceProvidersScreen(serviceKey: 'Mini Truck', title: l10n.miniTruck, userRole: widget.userRole),
          imagePath: 'assets/images/transport_truck_card.webp', subtitle: 'Fast Delivery'),
      HomeServiceItem(l10n.tractorTrolley, Icons.agriculture, const Color(0xFFE8F5E9), Colors.green, 'Transport',
          ServiceProvidersScreen(serviceKey: 'Tractor Trolley', title: l10n.tractorTrolley, userRole: widget.userRole),
          imagePath: 'assets/images/tractor_trolley_card.webp', subtitle: 'Bulk Carry'),
      HomeServiceItem(l10n.fullTruck, Icons.local_shipping_outlined, const Color(0xFFFFF3E0), Colors.orange, 'Transport',
          ServiceProvidersScreen(serviceKey: 'Full Truck', title: l10n.fullTruck, userRole: widget.userRole),
          imagePath: 'assets/images/full_truck_card.webp', subtitle: 'Long Distance'),
      HomeServiceItem(l10n.tempo, Icons.airport_shuttle, const Color(0xFFFFF9C4), Colors.amber[800]!, 'Transport',
          ServiceProvidersScreen(serviceKey: 'Tempo', title: l10n.tempo, userRole: widget.userRole),
          imagePath: 'assets/images/tractor_trolley_card.webp', subtitle: 'City & Village'),
      HomeServiceItem(l10n.pickupVan, Icons.fire_truck, const Color(0xFFF3E5F5), Colors.purple, 'Transport',
          ServiceProvidersScreen(serviceKey: 'Pickup Van', title: l10n.pickupVan, userRole: widget.userRole),
          imagePath: 'assets/images/pickup_van_card.webp', subtitle: 'Quick Pickup'),
      HomeServiceItem(l10n.container, Icons.inventory, const Color(0xFFEFEBE9), Colors.brown, 'Transport',
          ServiceProvidersScreen(serviceKey: 'Container', title: l10n.container, userRole: widget.userRole),
          imagePath: 'assets/images/full_truck_card.webp', subtitle: 'Large Cargo'),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _verifyApiConnection() async {
    try {
      final apiService = ApiService();
      await apiService.getEquipment();
    } catch (e) {
      debugPrint('API Error: $e');
    }
  }

  Future<void> _fetchUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null) {
      try {
        final apiService = ApiService();
        final notifications = await apiService.getUserNotifications(userId);
        int count = 0;
        for (var n in notifications) {
          if (n['read'] == false) count++;
        }
        if (mounted) {
          setState(() {
            _unreadNotificationCount = count;
          });
        }
      } catch (e) {
        debugPrint('Error fetching notifications count: $e');
      }
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
      String village = prefs.getString('user_village') ?? 'Your Village';
      String district = prefs.getString('user_district') ?? 'District';
      _userLocation = '$village, $district';
      _userRole = prefs.getString('user_role') ?? 'User';
    });
    _fetchUnreadCount();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      _loadUserData();
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        UiUtils.showCenteredToast(context, 'Location services are disabled.');
        setState(() => _isFetchingLocation = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          UiUtils.showCenteredToast(context, 'Location permissions are denied');
          setState(() => _isFetchingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        UiUtils.showCenteredToast(context, 'Location permissions are permanently denied');
        setState(() => _isFetchingLocation = false);
        return;
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        String village = place.subLocality ?? place.locality ?? 'Unknown Village';
        String district = place.subAdministrativeArea ?? place.administrativeArea ?? 'Unknown District';
        setState(() => _userLocation = '$village, $district');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_village', village);
        await prefs.setString('user_district', district);
        UiUtils.showCenteredToast(context, 'Location detected: $village, $district');
      }
    } catch (e) {
      UiUtils.showCenteredToast(context, 'Error fetching location: $e');
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  void _showLocationSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                const Text('Choose Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _locationOption(Icons.my_location, Colors.blue, 'Auto Detect', 'Use GPS to find your location', !_isFetchingLocation, () async {
                  setModalState(() {});
                  await _fetchCurrentLocation();
                  if (context.mounted) Navigator.pop(context);
                }),
                const SizedBox(height: 12),
                _locationOption(Icons.location_city, Colors.orange, 'Enter Manually', 'Type your village/district', true, () {
                  Navigator.pop(context);
                  _showManualLocationDialog();
                }),
                const SizedBox(height: 16),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _locationOption(IconData icon, Color color, String title, String subtitle, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ])),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showManualLocationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempVillage = '';
        String tempDistrict = '';
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Enter Location', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              decoration: InputDecoration(labelText: 'Village', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              controller: TextEditingController(text: _userLocation.split(',')[0].trim()),
              onChanged: (val) => tempVillage = val,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(labelText: 'District', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              controller: TextEditingController(text: _userLocation.contains(',') ? _userLocation.split(',')[1].trim() : ''),
              onChanged: (val) => tempDistrict = val,
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                String finalVillage = tempVillage.isNotEmpty ? tempVillage : _userLocation.split(',')[0].trim();
                String finalDistrict = tempDistrict.isNotEmpty ? tempDistrict : (_userLocation.contains(',') ? _userLocation.split(',')[1].trim() : '');
                if (finalVillage.isNotEmpty && finalDistrict.isNotEmpty) {
                  setState(() => _userLocation = '$finalVillage, $finalDistrict');
                  Navigator.pop(context);
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      _buildHomeTab(),
      const GenericHistoryScreen(
        title: 'Activity Bookings',
        categories: [BookingCategory.services, BookingCategory.farmWorkers, BookingCategory.transport, BookingCategory.rentals],
        showBackButton: false,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: _bgColor,
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _primaryGreen,
          unselectedItemColor: Colors.grey[500],
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: AppLocalizations.of(context)!.navHome),
            BottomNavigationBarItem(icon: const Icon(Icons.history_outlined), activeIcon: const Icon(Icons.history), label: AppLocalizations.of(context)!.activity),
            BottomNavigationBarItem(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person), label: AppLocalizations.of(context)!.navProfile),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: _buildSearchBar(),
          ),
        ),
        if (_searchQuery.isNotEmpty)
          SliverToBoxAdapter(child: _buildSearchResults())
        else ...[
          SliverToBoxAdapter(child: _buildBannerSection()),
          SliverToBoxAdapter(child: _buildEquipmentSection()),
          SliverToBoxAdapter(child: _buildServicesSection()),
          SliverToBoxAdapter(child: _buildTransportSection()),
          if (['Owner', 'Provider'].contains(_userRole))
            SliverToBoxAdapter(child: _buildListYourAssetsSection()),
          SliverToBoxAdapter(child: _buildToolsSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 52, left: 20, right: 20, bottom: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 26),
                ),
                const SizedBox(width: 10),
                const Text('Agri Farms', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
              ]),
              Row(children: [
                if (['Owner', 'Provider'].contains(_userRole))
                  _headerIconBtn(Icons.assignment_outlined, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProviderRequestsScreen()))),
                _headerIconBtn(Icons.location_on_outlined, () => _showLocationSelector(context)),
                Stack(children: [
                  _headerIconBtn(Icons.notifications_outlined, () async {
                    if (_unreadNotificationCount > 0) {
                      setState(() => _unreadNotificationCount = 0);
                      final prefs = await SharedPreferences.getInstance();
                      final userId = prefs.getString('user_id');
                      if (userId != null) {
                        try { await ApiService().markAllNotificationsAsRead(userId); } catch (_) {}
                      }
                    }
                    if (mounted) {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())).then((_) => _fetchUnreadCount());
                    }
                  }),
                  if (_unreadNotificationCount > 0)
                    Positioned(right: 6, top: 6, child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Color(0xFFFF5722), shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text('$_unreadNotificationCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    )),
                ]),
              ]),
            ],
          ),
          const SizedBox(height: 20),
          Text('Namaste, $_userName! 👋', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _showLocationSelector(context),
            child: Row(children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 15),
              const SizedBox(width: 4),
              Flexible(child: Text(_userLocation, style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis)),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 16),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _headerIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchHint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(onTap: () { _searchController.clear(); }, child: Icon(Icons.close, color: Colors.grey[400], size: 20))
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      height: 160,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(fit: StackFit.expand, children: [
          Image.asset('assets/images/home_banner.webp', fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)])))),
          Container(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.centerRight, end: Alignment.centerLeft,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)]))),
          Positioned(left: 20, bottom: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Season Offer', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1)),
            const SizedBox(height: 4),
            const Text('Book Farm\nServices Today!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: _accentGold, borderRadius: BorderRadius.circular(20)),
              child: const Text('Explore Now', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ])),
        ]),
      ),
    );
  }

  Widget _buildEquipmentSection() {
    final items = _getAllItems(context).where((i) => i.category == 'Rentals').take(4).toList();
    return _buildSectionWrapper(
      title: AppLocalizations.of(context)!.rentEquipment,
      emoji: '🚜',
      accentColor: _primaryGreen,
      onViewMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EquipmentRentalsScreen(userRole: widget.userRole))),
      onAdd: ['Owner', 'Provider'].contains(_userRole) ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadItemScreen(category: 'Equipment'))) : null,
      child: GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14,
        childAspectRatio: 1.2,
        children: items.map((item) => _buildVisualCard(item)).toList(),
      ),
    );
  }

  Widget _buildServicesSection() {
    final items = _getAllItems(context).where((i) => i.category == 'Services').take(4).toList();
    return _buildSectionWrapper(
      title: AppLocalizations.of(context)!.bookServices,
      emoji: '🧑‍🌾',
      accentColor: const Color(0xFF1565C0),
      onViewMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgriServicesScreen(userRole: widget.userRole))),
      onAdd: ['Owner', 'Provider'].contains(_userRole) ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadItemScreen(category: 'Services'))) : null,
      child: GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14,
        childAspectRatio: 1.2,
        children: items.map((item) => _buildVisualCard(item)).toList(),
      ),
    );
  }

  Widget _buildTransportSection() {
    final items = _getAllItems(context).where((i) => i.category == 'Transport').take(4).toList();
    return _buildSectionWrapper(
      title: AppLocalizations.of(context)!.bookTransport,
      emoji: '🚛',
      accentColor: const Color(0xFFE65100),
      onViewMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookTransportScreen(userRole: widget.userRole))),
      onAdd: ['Owner', 'Provider'].contains(_userRole) ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadItemScreen(category: 'Transport'))) : null,
      child: SizedBox(
        height: 160,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, i) => _buildTransportCard(items[i]),
        ),
      ),
    );
  }

  Widget _buildListYourAssetsSection() {
    return _buildSectionWrapper(
      title: AppLocalizations.of(context)!.listYourAssets,
      accentColor: const Color(0xFF6A1B9A),
      showViewMore: false,
      child: Row(children: [
        Expanded(child: _buildUploadCard('List\nEquipment', Icons.agriculture, const Color(0xFFE8F5E9), const Color(0xFF2E7D32), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadItemScreen(category: 'Equipment'))))),
        const SizedBox(width: 14),
        Expanded(child: _buildUploadCard('List\nVehicle', Icons.local_shipping_outlined, const Color(0xFFFFF3E0), const Color(0xFFE65100), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadItemScreen(category: 'Transport'))))),
        const SizedBox(width: 14),
        Expanded(child: _buildUploadCard('List\nService', Icons.handyman_outlined, const Color(0xFFEDE7F6), const Color(0xFF6A1B9A), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadItemScreen(category: 'Services'))))),
      ]),
    );
  }

  Widget _buildToolsSection() {
    return _buildSectionWrapper(
      title: AppLocalizations.of(context)!.tools,
      emoji: '🛠️',
      accentColor: const Color(0xFF00838F),
      showViewMore: false,
      child: Row(children: [
        Expanded(child: _buildToolTile('Weather', Icons.wb_sunny_outlined, const Color(0xFFFFF8E1), const Color(0xFFF57F17), () => UiUtils.showCenteredToast(context, 'Coming Soon!'))),
        const SizedBox(width: 10),
        Expanded(child: _buildToolTile('Crop\nAdvice', Icons.grass, const Color(0xFFE8F5E9), const Color(0xFF2E7D32), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropAdvisoryScreen())))),
        const SizedBox(width: 10),
        Expanded(child: _buildToolTile('Mandi\nPrices', Icons.show_chart, const Color(0xFFE3F2FD), const Color(0xFF1565C0), () => UiUtils.showCenteredToast(context, 'Coming Soon!'))),
        const SizedBox(width: 10),
        Expanded(child: _buildToolTile('Calculator', Icons.calculate_outlined, const Color(0xFFF3E5F5), const Color(0xFF6A1B9A), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmingCalculatorScreen())))),
      ]),
    );
  }

  Widget _buildToolTile(String label, IconData icon, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: fg, size: 28),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg, height: 1.2)),
        ]),
      ),
    );
  }



  Widget _buildSectionWrapper({
    required String title, String? emoji, required Color accentColor,
    required Widget child, VoidCallback? onViewMore, VoidCallback? onAdd, bool showViewMore = true,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            if (emoji != null) ...[
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
            ],
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
            if (['Owner', 'Provider'].contains(_userRole) && onAdd != null) ...[ 
              const SizedBox(width: 8),
              GestureDetector(onTap: onAdd, child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: _primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.add, size: 18, color: _primaryGreen),
              )),
            ],
          ]),
          if (showViewMore && onViewMore != null)
            GestureDetector(onTap: onViewMore, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Text('View All', style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, color: accentColor, size: 16),
              ]),
            )),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  Widget _buildVisualCard(HomeServiceItem item) {
    return GestureDetector(
      onTap: item.isComingSoon ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.navigationTarget)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image or colored bg
              if (item.imagePath != null)
                Opacity(
                  opacity: item.isComingSoon ? 0.6 : 1.0,
                  child: Image.asset(item.imagePath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: item.bgColor)),
                )
              else
                Container(color: item.bgColor, child: Center(child: Icon(item.icon, color: item.iconColor, size: 48))),
              // Deeper gradient overlay for text readability
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              // Labels at bottom
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, height: 1.1),
                      maxLines: 2,
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.isComingSoon ? 'COMING SOON' : item.subtitle!,
                        style: TextStyle(
                          color: item.isComingSoon ? Colors.orangeAccent : Colors.white.withOpacity(0.7),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.isComingSoon) 
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                    child: const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 28),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransportCard(HomeServiceItem item) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.navigationTarget)),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(fit: StackFit.expand, children: [
            if (item.imagePath != null)
              Image.asset(item.imagePath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: item.bgColor))
            else
              Container(color: item.bgColor, child: Center(child: Icon(item.icon, color: item.iconColor, size: 42))),
            DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
              stops: const [0.3, 1.0],
            ))),
            Positioned(left: 12, right: 8, bottom: 10, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, height: 1.1), maxLines: 2),
              if (item.subtitle != null) Text(item.subtitle!, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _buildUploadCard(String label, IconData icon, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: fg.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: fg.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: fg, size: 22)),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg, height: 1.1), maxLines: 2),
        ]),
      ),
    );
  }

  Widget _buildSearchResults() {
    final rentals = _getFilteredItems(context, 'Rentals');
    final services = _getFilteredItems(context, 'Services');
    final transport = _getFilteredItems(context, 'Transport');

    if (rentals.isEmpty && services.isEmpty && transport.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(child: Column(children: [
          Icon(Icons.search_off, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.noMatchFound, style: TextStyle(fontSize: 15, color: Colors.grey[500])),
        ])),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (rentals.isNotEmpty) ...[
          _searchSectionHeader(AppLocalizations.of(context)!.rentEquipment),
          GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.2,
            children: rentals.map((i) => _buildVisualCard(i)).toList()),
          const SizedBox(height: 20),
        ],
        if (services.isNotEmpty) ...[
          _searchSectionHeader(AppLocalizations.of(context)!.bookServices),
          GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.2,
            children: services.map((i) => _buildVisualCard(i)).toList()),
          const SizedBox(height: 20),
        ],
        if (transport.isNotEmpty) ...[
          _searchSectionHeader(AppLocalizations.of(context)!.bookTransport),
          GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.2,
            children: transport.map((i) => _buildVisualCard(i)).toList()),
          const SizedBox(height: 20),
        ],
      ]),
    );
  }

  Widget _searchSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  List<HomeServiceItem> _getFilteredItems(BuildContext context, String category) {
    var allItems = _getAllItems(context);
    if (_searchQuery.isEmpty) return [];
    final query = _searchQuery.toLowerCase();
    return allItems.where((item) => item.category == category && item.title.replaceAll('\n', ' ').toLowerCase().contains(query)).toList();
  }
}
