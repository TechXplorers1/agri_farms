import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'agri_services_screen.dart';
import 'book_transport_screen.dart';
import 'equipment_rentals_screen.dart';
import 'service_providers_screen.dart';
import 'tools/fertilizer_calculator_screen.dart';
import 'tools/pesticide_calculator_screen.dart';
import 'tools/farming_calculator_screen.dart';
import 'tools/farming_calculator_screen.dart';
import 'tools/crop_advisory_screen.dart';
import 'provider/provider_requests_screen.dart'; // Import for header action
import 'community_screen.dart';
import 'upload_item_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

class HomeServiceItem {
  final String title;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final String category; // 'Services', 'Transport', 'Rentals'
  final Widget navigationTarget;

  final String? imagePath;

  HomeServiceItem(this.title, this.icon, this.bgColor, this.iconColor, this.category, this.navigationTarget, {this.imagePath});
}


class HomeScreen extends StatefulWidget {
  final String? userRole;
  const HomeScreen({super.key, this.userRole});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _userName = 'User';
  String _userLocation = 'Your Village, Your District';
  String _userRole = 'User';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Helper method to get localized items
  List<HomeServiceItem> _getAllItems(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    return [
      // Rentals
      HomeServiceItem(l10n.tractors, Icons.agriculture, Colors.green[50]!, Colors.green, 'Rentals', ServiceProvidersScreen(serviceKey: 'Tractors', title: l10n.tractors, userRole: widget.userRole)),
      HomeServiceItem(l10n.harvesters, Icons.grass, Colors.yellow[50]!, Colors.orange, 'Rentals', ServiceProvidersScreen(serviceKey: 'Harvesters', title: l10n.harvesters, userRole: widget.userRole)),
      HomeServiceItem(l10n.sprayers, Icons.water_drop, Colors.blue[50]!, Colors.blue, 'Rentals', ServiceProvidersScreen(serviceKey: 'Sprayers', title: l10n.sprayers, userRole: widget.userRole)),
      HomeServiceItem(l10n.trolleys, Icons.shopping_cart_outlined, Colors.grey[100]!, Colors.grey, 'Rentals', ServiceProvidersScreen(serviceKey: 'Trolleys', title: l10n.trolleys, userRole: widget.userRole)),
      HomeServiceItem(
        l10n.jcb, 
        Icons.construction, 
        Colors.orange[50]!, 
        Colors.orange, 
        'Rentals', 
        ServiceProvidersScreen(serviceKey: 'JCB', title: l10n.jcb, userRole: widget.userRole),
        imagePath: 'assets/images/jcb_icon.png'
      ),

      // Services
      HomeServiceItem(l10n.ploughing, Icons.agriculture, const Color(0xFFE3F2FD), Colors.blue, 'Services', ServiceProvidersScreen(serviceKey: 'Ploughing', title: l10n.ploughing, userRole: widget.userRole)),
      HomeServiceItem(l10n.harvesting, Icons.grass, const Color(0xFFFFF9C4), Colors.orange, 'Services', ServiceProvidersScreen(serviceKey: 'Harvesting', title: l10n.harvesting, userRole: widget.userRole)),
      HomeServiceItem(l10n.farmWorkers, Icons.groups, const Color(0xFFF3E5F5), Colors.purple, 'Services', ServiceProvidersScreen(serviceKey: 'Farm Workers', title: l10n.farmWorkers, userRole: widget.userRole)),
      HomeServiceItem(l10n.droneSpraying, Icons.airplanemode_active, const Color(0xFFE8F5E9), Colors.green, 'Services', ServiceProvidersScreen(serviceKey: 'Drone Spraying', title: l10n.droneSpraying, userRole: widget.userRole)),
      HomeServiceItem(l10n.irrigation, Icons.water_drop, const Color(0xFFE1F5FE), Colors.cyan, 'Services', ServiceProvidersScreen(serviceKey: 'Irrigation', title: l10n.irrigation, userRole: widget.userRole)),
      HomeServiceItem(l10n.soilTesting, Icons.science, const Color(0xFFF3E5F5), Colors.purple, 'Services', ServiceProvidersScreen(serviceKey: 'Soil Testing', title: l10n.soilTesting, userRole: widget.userRole)),
      HomeServiceItem(l10n.vetCare, Icons.pets, const Color(0xFFFCE4EC), Colors.pink, 'Services', ServiceProvidersScreen(serviceKey: 'Vet Care', title: l10n.vetCare, userRole: widget.userRole)),
      
      // Transport
      HomeServiceItem(l10n.miniTruck, Icons.local_shipping, const Color(0xFFE3F2FD), Colors.blue, 'Transport', ServiceProvidersScreen(serviceKey: 'Mini Truck', title: l10n.miniTruck, userRole: widget.userRole)),
      HomeServiceItem(l10n.tractorTrolley, Icons.agriculture, const Color(0xFFE8F5E9), Colors.green, 'Transport', ServiceProvidersScreen(serviceKey: 'Tractor Trolley', title: l10n.tractorTrolley, userRole: widget.userRole)),
      HomeServiceItem(l10n.fullTruck, Icons.local_shipping_outlined, const Color(0xFFFFF3E0), Colors.orange, 'Transport', ServiceProvidersScreen(serviceKey: 'Full Truck', title: l10n.fullTruck, userRole: widget.userRole)),
      HomeServiceItem(l10n.tempo, Icons.airport_shuttle, const Color(0xFFFFF9C4), Colors.amber[800]!, 'Transport', ServiceProvidersScreen(serviceKey: 'Tempo', title: l10n.tempo, userRole: widget.userRole)),
      HomeServiceItem(l10n.pickupVan, Icons.fire_truck, const Color(0xFFF3E5F5), Colors.purple, 'Transport', ServiceProvidersScreen(serviceKey: 'Pickup Van', title: l10n.pickupVan, userRole: widget.userRole)),
      HomeServiceItem(l10n.container, Icons.inventory, const Color(0xFFEFEBE9), Colors.brown, 'Transport', ServiceProvidersScreen(serviceKey: 'Container', title: l10n.container, userRole: widget.userRole)),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
      String village = prefs.getString('user_village') ?? 'Your Village';
      String district = prefs.getString('user_district') ?? 'Your District';
      _userLocation = '$village, $district';
      _userRole = prefs.getString('user_role') ?? 'User';
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      _loadUserData(); // Reload data when switching back to Home
    }
  }

  void _showLocationSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Location',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.my_location, color: Colors.blue),
                title: const Text('Auto Detect Location'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                   _userLocation = "Kodad, Suryapet"; 
                  });
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location detected successfully!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_city, color: Colors.orange),
                title: const Text('Select Village / District Manually'),
                onTap: () {
                  Navigator.pop(context);
                   _showManualLocationDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showManualLocationDialog() {
      showDialog(
        context: context,
        builder: (context) {
            String tempVillage = '';
            String tempDistrict = '';
            return AlertDialog(
                title: const Text('Enter Location'),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        TextField(
                            decoration: const InputDecoration(labelText: 'Village'),
                            onChanged: (val) => tempVillage = val,
                        ),
                        TextField(
                            decoration: const InputDecoration(labelText: 'District'),
                            onChanged: (val) => tempDistrict = val,
                        ),
                    ],
                ),
                actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () {
                        if (tempVillage.isNotEmpty && tempDistrict.isNotEmpty) {
                            setState(() {
                                _userLocation = "$tempVillage, $tempDistrict";
                            });
                             Navigator.pop(context);
                        }
                    }, child: const Text('Save')),
                ],
            );
        }
      );
  }

  @override
  Widget build(BuildContext context) {
    // List of widget options for each tab
    final List<Widget> widgetOptions = <Widget>[
      // Home Tab Content (Index 0)
      SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF66BB6A), // Lighter Green
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo and Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00AA55), // Match Splash Screen Green
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.eco, color: Colors.white, size: 24), // Match Splash Icon
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Agri Farms', // Match Splash Text Spacing
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      // Actions
                      Row(
                        children: [
                          if (['Owner', 'Provider'].contains(_userRole)) // Visible for Owners and Providers
                            IconButton(
                              icon: const Icon(Icons.assignment_outlined, color: Colors.white),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const ProviderRequestsScreen()),
                                );
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.location_on_outlined, color: Colors.white),
                            onPressed: () => _showLocationSelector(context),
                          ),
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                                  );
                                },
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: const Text(
                                    '2',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Greeting Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline, // Align text baselines
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.namaste,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18, // Slightly increased for consistency
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _userLocation,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchHint,
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ],
              ),
            ),

            // Content Body
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   if (_searchQuery.isNotEmpty) ...[
                      // SEARCH RESULTS VIEW
                      if (_getFilteredItems(context, 'Services').isEmpty && 
                          _getFilteredItems(context, 'Transport').isEmpty && 
                          _getFilteredItems(context, 'Rentals').isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40.0),
                              child: Column(
                                children: [
                                  Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(context)!.noMatchFound,
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      
                      if (_getFilteredItems(context, 'Rentals').isNotEmpty) ...[
                         _buildSectionHeader(AppLocalizations.of(context)!.rentEquipment, () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => EquipmentRentalsScreen(userRole: widget.userRole)));
                         }),
                         const SizedBox(height: 12),
                          _buildSectionContainer(
                           Wrap(
                             spacing: 12,
                             runSpacing: 12,
                             children: _getFilteredItems(context, 'Rentals').map((item) => 
                               SizedBox(
                                 width: (MediaQuery.of(context).size.width - 64) / 3,
                                 child: _buildServiceItem(item.icon, item.title, item.bgColor, item.iconColor, onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => item.navigationTarget));
                                 }),
                               )
                             ).toList(),
                           )
                          ),
                         const SizedBox(height: 24),
                      ],
                      if (_getFilteredItems(context, 'Services').isNotEmpty) ...[
                         _buildSectionHeader(AppLocalizations.of(context)!.bookServices, () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => AgriServicesScreen(userRole: widget.userRole)));
                         }),
                         const SizedBox(height: 12),
                          _buildSectionContainer(
                           // Use Wrap or Grid for search results to show potentially more than 3
                           Wrap(
                             spacing: 12,
                             runSpacing: 12,
                             children: _getFilteredItems(context, 'Services').map((item) => 
                               SizedBox(
                                 width: (MediaQuery.of(context).size.width - 64) / 3, // Approx 3 items per row logic
                                 child: _buildServiceItem(item.icon, item.title, item.bgColor, item.iconColor, onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => item.navigationTarget));
                                 }),
                               )
                             ).toList(),
                           )
                          ),
                         const SizedBox(height: 24),
                      ],
                      if (_getFilteredItems(context, 'Transport').isNotEmpty) ...[
                         _buildSectionHeader(AppLocalizations.of(context)!.bookTransport, () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => BookTransportScreen(userRole: widget.userRole)));
                         }),
                         const SizedBox(height: 12),
                          _buildSectionContainer(
                           Wrap(
                             spacing: 12,
                             runSpacing: 12,
                             children: _getFilteredItems(context, 'Transport').map((item) => 
                               SizedBox(
                                 width: (MediaQuery.of(context).size.width - 64) / 3,
                                 child: _buildServiceItem(item.icon, item.title, item.bgColor, item.iconColor, onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => item.navigationTarget));
                                 }),
                               )
                             ).toList(),
                           )
                          ),
                         const SizedBox(height: 24),
                      ],
                   ] else ...[
                  // DEFAULT VIEW (No Search)
                  
                  // 1. Rent Equipment Section
                  _buildSectionHeader(AppLocalizations.of(context)!.rentEquipment, () {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => EquipmentRentalsScreen(userRole: widget.userRole)));
                  }),
                  const SizedBox(height: 12),
                   _buildSectionContainer(
                     Row(
                      children: [
                        Expanded(child: _buildServiceItem(Icons.agriculture, AppLocalizations.of(context)!.tractors, Colors.green[50]!, Colors.green, onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceProvidersScreen(serviceKey: 'Tractors', title: AppLocalizations.of(context)!.tractors, userRole: widget.userRole)));
                        })),
                         const SizedBox(width: 12),
                        Expanded(child: _buildServiceItem(Icons.grass, AppLocalizations.of(context)!.harvesters, Colors.yellow[50]!, Colors.orange, onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceProvidersScreen(serviceKey: 'Harvesters', title: AppLocalizations.of(context)!.harvesters, userRole: widget.userRole)));
                        })),
                         const SizedBox(width: 12),
                        Expanded(child: _buildServiceItem(Icons.water_drop, AppLocalizations.of(context)!.sprayers, Colors.blue[50]!, Colors.blue, onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceProvidersScreen(serviceKey: 'Sprayers', title: AppLocalizations.of(context)!.sprayers, userRole: widget.userRole)));
                        })),
                        const SizedBox(width: 8),
                         _buildArrowButton(onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => EquipmentRentalsScreen(userRole: widget.userRole)));
                        }),
                      ],
                    ),
                   ),

                  const SizedBox(height: 24),

                  // 2. Book Services Section
                  _buildSectionHeader(AppLocalizations.of(context)!.bookServices, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AgriServicesScreen()));
                  }),
                  const SizedBox(height: 12),
                     _buildSectionContainer(
                     Row(
                      children: [
                        Expanded(child: _buildServiceItem(Icons.agriculture, AppLocalizations.of(context)!.ploughing, const Color(0xFFE3F2FD), Colors.blue, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceProvidersScreen(serviceKey: 'Ploughing', title: AppLocalizations.of(context)!.ploughing, userRole: widget.userRole)));
                        })),
                        const SizedBox(width: 12),
                        Expanded(child: _buildServiceItem(Icons.grass, AppLocalizations.of(context)!.harvesting, const Color(0xFFFFF9C4), Colors.orange, onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceProvidersScreen(serviceKey: 'Harvesting', title: AppLocalizations.of(context)!.harvesting, userRole: widget.userRole)));
                        })),
                        const SizedBox(width: 12),
                        Expanded(child: _buildServiceItem(Icons.groups, AppLocalizations.of(context)!.farmWorkers, const Color(0xFFF3E5F5), Colors.purple, onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceProvidersScreen(serviceKey: 'Farm Workers', title: AppLocalizations.of(context)!.farmWorkers, userRole: widget.userRole)));
                        })),
                        const SizedBox(width: 8),
                         _buildArrowButton(onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => const AgriServicesScreen()));
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Book Transport Section
                  _buildSectionHeader(AppLocalizations.of(context)!.bookTransport, () {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => BookTransportScreen(userRole: widget.userRole)));
                  }),
                  const SizedBox(height: 12),
                   _buildSectionContainer(
                     Row(
                      children: [
                        Expanded(child: _buildServiceItem(Icons.local_shipping, AppLocalizations.of(context)!.miniTruck, const Color(0xFFE3F2FD), Colors.blue, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceProvidersScreen(serviceKey: 'Mini Truck', title: AppLocalizations.of(context)!.miniTruck, userRole: widget.userRole)));
                        })),
                        const SizedBox(width: 12),
                        Expanded(child: _buildServiceItem(Icons.agriculture, AppLocalizations.of(context)!.tractorTrolley, const Color(0xFFE8F5E9), Colors.green, onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceProvidersScreen(serviceKey: 'Tractor Trolley', title: AppLocalizations.of(context)!.tractorTrolley, userRole: widget.userRole)));
                        })),
                        const SizedBox(width: 12),
                        Expanded(child: _buildServiceItem(Icons.local_shipping_outlined, AppLocalizations.of(context)!.fullTruck, const Color(0xFFFFF3E0), Colors.orange, onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceProvidersScreen(serviceKey: 'Full Truck', title: AppLocalizations.of(context)!.fullTruck, userRole: widget.userRole)));
                        })),
                        const SizedBox(width: 8),
                         _buildArrowButton(onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => BookTransportScreen(userRole: widget.userRole)));
                        }),
                      ],
                    ),
                   ),

                  const SizedBox(height: 24),
                  const SizedBox(height: 24),

                  // List Your Assets Section (For Providers/Farmers)
                   Text(
                    AppLocalizations.of(context)!.listYourAssets,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildSectionContainer(
                     Row(
                      children: [
                        Expanded(child: _buildServiceItem(Icons.local_shipping, AppLocalizations.of(context)!.listTransport, const Color(0xFFE8F5E9), Colors.green, onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadItemScreen(category: 'Transport')));
                        })),
                        const SizedBox(width: 12),
                        Expanded(child: _buildServiceItem(Icons.agriculture, AppLocalizations.of(context)!.listEquipment, const Color(0xFFFFF3E0), Colors.orange, onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadItemScreen(category: 'Equipment')));
                        })),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                   Text(
                    AppLocalizations.of(context)!.tools,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // Tools Section
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildToolCard(context, AppLocalizations.of(context)!.weather, Icons.cloud_outlined, const Color(0xFFE3F2FD), Colors.blue, onTap: () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Detailed Weather Coming Soon!')));
                        }),
                        const SizedBox(width: 12),
                        _buildToolCard(context, AppLocalizations.of(context)!.cropAdvisory, Icons.grass, const Color(0xFFE8F5E9), Colors.green, onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => const CropAdvisoryScreen()));
                        }),
                         const SizedBox(width: 12),
                        _buildToolCard(context, AppLocalizations.of(context)!.mandiPrices, Icons.show_chart, const Color(0xFFFFF3E0), Colors.orange, onTap: () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Market Prices Coming Soon!')));
                        }),
                        const SizedBox(width: 12),
                        _buildToolCard(context, AppLocalizations.of(context)!.farmingCalculator, Icons.calculate_outlined, const Color(0xFFF3E5F5), Colors.purple, onTap: () {
                          // Show bottom sheet to choose calculator type? Or just link to one main one. 
                          // Linking to FarmingCalculatorScreen as main entrance
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const FarmingCalculatorScreen()));
                        }),
                        const SizedBox(width: 12),
                        _buildToolCard(context, 'Support', Icons.headset_mic_outlined, const Color(0xFFE0F7FA), Colors.cyan, onTap: () {
                           // Navigate to Help or specific support screen
                           // For now reusing Profile or a simple placeholder
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support Center Coming Soon!')));
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Banners
                  _buildBanner(AppLocalizations.of(context)!.freeSoilTesting, AppLocalizations.of(context)!.bookNow, const Color(0xFFE3F2FD)), // Light Blue
                  const SizedBox(height: 12),
                  _buildBanner(AppLocalizations.of(context)!.newTractorsAvailable, AppLocalizations.of(context)!.lowRentalRates, const Color(0xFFFFF3E0)), // Light Orange
                  
                  const SizedBox(height: 24),
                   
                   // Info Cards & Weather

                  
                  // Community Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E5F5),
                                borderRadius: BorderRadius.circular(8),
                                ),
                              child: const Icon(Icons.chat_bubble_outline, color: Colors.purple),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(context)!.communityQuestions,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildCommunityQuestion(
                          'What is the best fertilizer for cotton in black soil?',
                          '24 answers • 2 hours ago',
                        ),

                        const SizedBox(height: 16),
                        _buildCommunityQuestion('How to treat leaf curl in tomato?', '12 answers • 2h ago'),
                        const Divider(height: 24),
                        _buildCommunityQuestion('Best time for wheat sowing?', '8 answers • 5h ago'),
                      ],
                    ),
                  ),
                   ], // End else (Default View)
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      // Market Placeholder (Index 1) - Disabled
      // const Center(child: Text('Market Screen Placeholder')),
      // Rentals Placeholder (Index 2)
      // Rentals Placeholder (Index 2)
      EquipmentRentalsScreen(userRole: widget.userRole),
      // Community Placeholder (Index 3)
      // Community Placeholder (Index 3)
      const CommunityScreen(),
      // Profile Tab (Index 4)
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100], 
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00AA55),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: AppLocalizations.of(context)!.navHome),
          // BottomNavigationBarItem(icon: const Icon(Icons.storefront_outlined), label: AppLocalizations.of(context)!.navMarket), 
          BottomNavigationBarItem(icon: const Icon(Icons.build_outlined), label: AppLocalizations.of(context)!.navRentals),
          BottomNavigationBarItem(icon: const Icon(Icons.people_outlined), label: AppLocalizations.of(context)!.navCommunity),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: AppLocalizations.of(context)!.navProfile),
        ],
      ),
    );
  }
  
  List<HomeServiceItem> _getFilteredItems(BuildContext context, String category) {
    var allItems = _getAllItems(context);
    if (_searchQuery.isEmpty) return [];
    final query = _searchQuery.toLowerCase();
    return allItems.where((item) => 
      item.category == category && item.title.replaceAll('\n', ' ').toLowerCase().contains(query)
    ).toList();
  }

  Widget _buildSectionContainer(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewMore) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: onViewMore,
          child: Text(AppLocalizations.of(context)!.viewMore),
        ),
      ],
    );
  }

  Widget _buildArrowButton({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String title, Color bgColor, Color iconColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // Ensure tap is detected
      child: Container(
        // width: 100, // Removed fixed width
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, String title, IconData icon, Color bgColor, Color iconColor, {bool isNew = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 140, // Fixed width for horizontal scrolling
            height: 140, // Fixed height for square shape
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
            children: [
              Container(
                 padding: const EdgeInsets.all(10), // Larger icon bg
                 decoration: BoxDecoration(
                   color: bgColor,
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Icon(icon, color: iconColor, size: 28), // Larger icon
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black87),
              ),
            ],
          ),
        ),
        if (isNew)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFA020F0), // Purple color for New badge
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: const Text(
                'New',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(String title, String subtitle, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25), // Increased padding height
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12), // Slightly customized radius
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, String action, IconData icon, Color iconBg, Color iconColor) {
    return Container(
      // height: 180, // Removed fixed height to let parent control it

      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
         border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Container(
                 padding: const EdgeInsets.all(6),
                 decoration: BoxDecoration(
                   color: iconBg,
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Icon(icon, color: iconColor, size: 20),
               ),
               Text(
                 title,
                 style: const TextStyle(fontSize: 14, color: Colors.grey),
               )
             ],
           ),
           const Spacer(),
           Text(
             content,
             style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
           ),
           if (action.isNotEmpty) ...[
             const SizedBox(height: 12),
             Text(
               action,
               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
             ),
           ]
        ],
      ),
    );
  }

  Widget _buildCommunityQuestion(String question, String meta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          meta,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
