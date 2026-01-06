import 'package:flutter/material.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'agri_services_screen.dart';
import 'book_transport_screen.dart';
import 'equipment_rentals_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _userName = 'User';
  String _userLocation = 'Your Village, Your District';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
      String village = prefs.getString('user_village') ?? 'Your Village';
      String district = prefs.getString('user_district') ?? 'Your District';
      _userLocation = '$village, $district';
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

  @override
  Widget build(BuildContext context) {
    // List of widget options for each tab
    final List<Widget> _widgetOptions = <Widget>[
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Namaste,',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                            onPressed: () {},
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
                    decoration: InputDecoration(
                      hintText: 'Search seeds, tractor, spraying...',
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
                  // Services Grid Card
                  Container(
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
                    child: GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.95,
                      children: [
                        _buildServiceItem(Icons.shopping_bag_outlined, 'Book\nServices', const Color(0xFFE1BEE7), Colors.purple, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AgriServicesScreen()));
                        }),
                        _buildServiceItem(Icons.local_shipping_outlined, 'Book\nTransport', const Color(0xFFFFCDD2), Colors.red, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const BookTransportScreen()));
                        }),
                        _buildServiceItem(Icons.build_outlined, 'Rent\nEquipment', const Color(0xFFFFE0B2), Colors.orange, onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => const EquipmentRentalsScreen()));
                        }),
                        _buildServiceItem(Icons.shopping_cart_outlined, 'Buy\nProducts', const Color(0xFFBBDEFB), Colors.blue),
                        _buildServiceItem(Icons.inventory_2_outlined, 'Sell\nProducts', const Color(0xFFC8E6C9), Colors.green),
                        _buildServiceItem(Icons.request_quote_outlined, 'Request\nProduct', const Color(0xFFF8BBD0), Colors.pink),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Tools',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // Tools Section
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildToolCard('Crop\nAdvisory', Icons.grass, const Color(0xFFE3F2FD), Colors.blue),
                        const SizedBox(width: 12),
                        _buildToolCard('Fertilizer\ncalculator', Icons.calculate_outlined, const Color(0xFFE3F2FD), Colors.blue),
                        const SizedBox(width: 12),
                        _buildToolCard('Pesticide\ncalculator', Icons.science_outlined, const Color(0xFFE3F2FD), Colors.blue, isNew: true),
                        const SizedBox(width: 12),
                         _buildToolCard('Farming\ncalculator', Icons.agriculture_outlined, const Color(0xFFE3F2FD), Colors.blue, isNew: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Banners
                  // Banners
                  _buildBanner('50% off on Seeds', 'Limited time offer', const Color(0xFFE8F5E9)), // Light Green
                  const SizedBox(height: 12),
                  _buildBanner('Free Soil Testing', 'Book now', const Color(0xFFE3F2FD)), // Light Blue
                  const SizedBox(height: 12),
                  _buildBanner('New Tractors Available', 'Low rental rates', const Color(0xFFFFF3E0)), // Light Orange

                  const SizedBox(height: 24),
                  
                  // Info Cards (Mandi & Weather)
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard('Mandi\nPrices', 'Check today\'s\nrates', 'View Prices', Icons.show_chart, Colors.orange[100]!, Colors.orange)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInfoCard('Weather', '28°C, Sunny\n\n7-Day Forecast', '', Icons.cloud_outlined, Colors.blue[50]!, Colors.blue)),
                    ],
                  ),

                  const SizedBox(height: 24),
                  
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
                            const Text(
                              'Community Questions',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildCommunityQuestion('How to treat leaf curl in tomato?', '12 answers • 2h ago'),
                        const Divider(height: 24),
                        _buildCommunityQuestion('Best time for wheat sowing?', '8 answers • 5h ago'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      // Market Placeholder (Index 1)
      const Center(child: Text('Market Screen Placeholder')), // You can replace this later
      // Rentals Placeholder (Index 2)
      const EquipmentRentalsScreen(),
      // Community Placeholder (Index 3)
      const Center(child: Text('Community Screen Placeholder')), // You can replace this later
      // Profile Tab (Index 4)
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100], 
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00AA55),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Market'), 
          BottomNavigationBarItem(icon: Icon(Icons.build_outlined), label: 'Rentals'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outlined), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String title, Color bgColor, Color iconColor, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Align to top to avoid center bias if needed, but center is usually fine
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(String title, IconData icon, Color bgColor, Color iconColor, {bool isNew = false}) {
    return Stack(
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
      height: 180,
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
