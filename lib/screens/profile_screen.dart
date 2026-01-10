import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'language_selection_screen.dart';
import 'edit_profile_screen.dart';
import 'notification_settings_screen.dart';
import 'help_support_screen.dart';
import 'terms_privacy_screen.dart';
import 'my_rentals_screen.dart';
import 'my_services_screen.dart';
import 'generic_history_screen.dart';
import 'generic_history_screen.dart';
import '../utils/booking_manager.dart';
import 'admin/admin_dashboard_screen.dart';
import 'provider/provider_requests_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedLanguage = 'English'; // Default
  String _userName = 'User';
  String _userVillage = 'Your Village';
  String _userDistrict = 'Your District';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('selected_language') ?? 'English';
      _userName = prefs.getString('user_name') ?? 'User';
      _userVillage = prefs.getString('user_village') ?? 'Your Village';
      _userDistrict = prefs.getString('user_district') ?? 'Your District';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Custom Header with Stats Card overlapping
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Green Header Background
                Container(
                  height: 280, // Adjust height as needed
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF66BB6A), // Lighter Green matching Home
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person_outline, size: 40, color: Color(0xFF00AA55)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$_userVillage, $_userDistrict',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40), // Space for the card overlap
                    ],
                  ),
                ),

                // Floating Stats Card
                Positioned(
                  bottom: -40,
                  left: 20,
                  right: 20,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('12', 'Orders', Icons.shopping_bag_outlined, Colors.green),
                          _buildDivider(),
                          _buildStatItem('5', 'Rentals', Icons.build_outlined, Colors.green),
                          _buildDivider(),
                          _buildStatItem('8', 'Services', Icons.cases_outlined, Colors.green),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60), // Space for the overlapping card

            // Activity Section
            _buildSectionHeader('Activity'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: _boxDecoration(),
              child: Column(
                children: [
                  _buildListTile(
                    Icons.history, 
                    'My Services',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const GenericHistoryScreen(
                          title: 'My Services',
                          categories: [BookingCategory.services, BookingCategory.farmWorkers],
                        )),
                      );
                    },
                  ),
                  _buildDividerLine(),
                  _buildListTile(
                    Icons.local_shipping_outlined, 
                    'My Transports',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const GenericHistoryScreen(
                          title: 'My Transports',
                          categories: [BookingCategory.transport],
                        )),
                      );
                    },
                  ),
                  _buildDividerLine(),
                  _buildListTile(
                    Icons.build_outlined, 
                    'My Rentals',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const GenericHistoryScreen(
                          title: 'My Rentals',
                          categories: [BookingCategory.rentals],
                        )),
                      );
                    },
                  ),

 
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Account Section
            _buildSectionHeader('Account'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: _boxDecoration(),
              child: Column(
                children: [
                  _buildListTile(
                    Icons.admin_panel_settings,
                    'Admin Panel',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AdminDashboard()),
                      );
                    }
                  ),
                  _buildDividerLine(),
                  _buildListTile(
                    Icons.person_outline, 
                    'Edit Profile',
                    onTap: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
                      if (result == true) {
                        _loadProfileData();
                      }
                    },
                  ),
                  _buildDividerLine(),
                  _buildListTile(
                    Icons.work_outline,
                    'Worker Requests', // New option for providers
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ProviderRequestsScreen()),
                      );
                    },
                  ),
                  _buildDividerLine(),
                  _buildListTile(
                    Icons.notifications_outlined, 
                    'Notifications',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                      );
                    },
                  ),
                  _buildDividerLine(),
                  _buildListTile(
                    Icons.language,
                    'Language',
                    trailingText: _selectedLanguage,
                    onTap: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LanguageSelectionScreen(isFromProfile: true),
                        ),
                      );
                      if (result == true) {
                        _loadProfileData(); // Reloading profile data actually reloads language too
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Support Section
            _buildSectionHeader('Support'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: _boxDecoration(),
              child: Column(
                children: [
                  _buildListTile(
                    Icons.help_outline, 
                    'Help & Support',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                      );
                    },
                  ),
                  _buildDividerLine(),
                  _buildListTile(
                    Icons.description_outlined, 
                    'Terms & Privacy',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const TermsPrivacyScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red), // Red border
                  foregroundColor: Colors.red, // Red text & icon
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[300],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black87),
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.grey[200]!),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.05),
          blurRadius: 5,
        )
      ],
    );
  }

  Widget _buildListTile(IconData icon, String title, {String? trailingText, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) 
             Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          if (trailingText != null) const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
      onTap: onTap ?? () {},
    );
  }
  
  Widget _buildDividerLine() {
    return const Divider(height: 1, indent: 16, endIndent: 16, thickness: 0.5);
  }
}
