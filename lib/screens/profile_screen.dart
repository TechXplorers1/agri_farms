import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'language_selection_screen.dart';
import 'edit_profile_screen.dart';
import 'notification_settings_screen.dart';
import 'help_support_screen.dart';
import 'terms_privacy_screen.dart';
import 'generic_history_screen.dart';
import '../utils/booking_manager.dart';
import '../../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../config/api_config.dart';

import 'provider/provider_requests_screen.dart';
import 'manage_items_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/ui_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedLanguage = 'English';
  String _userName = 'User';
  String _userVillage = 'Your Village';
  String _userDistrict = 'Your District';
  String _userRole = 'User';
  String? _profileImageUrl;
  bool _isUploading = false;

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
      _userRole = prefs.getString('user_role') ?? 'User';
      _profileImageUrl = prefs.getString('user_profile_image');
    });

    final userId = prefs.getString('user_id');
    if (userId != null) {
      try {
        final apiService = ApiService();
        final userData = await apiService.getUser(userId);
        await prefs.setString('user_name', userData['fullName'] ?? _userName);
        await prefs.setString('user_village', userData['village'] ?? _userVillage);
        await prefs.setString('user_district', userData['district'] ?? _userDistrict);
        await prefs.setString('user_role', userData['role'] ?? _userRole);
        if (userData['profileImageUrl'] != null) {
          await prefs.setString('user_profile_image', userData['profileImageUrl']);
        }
        if (mounted) {
          setState(() {
            _userName = userData['fullName'] ?? _userName;
            _userVillage = userData['village'] ?? _userVillage;
            _userDistrict = userData['district'] ?? _userDistrict;
            _userRole = userData['role'] ?? _userRole;
            _profileImageUrl = userData['profileImageUrl'] ?? _profileImageUrl;
          });
        }
      } catch (e) {
        debugPrint('Error fetching updated profile: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 260, width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFF66BB6A)],
                    ),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: CircleAvatar(
                                radius: 44,
                                backgroundColor: const Color(0xFFF1F8E9),
                                backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                    ? NetworkImage(ApiConfig.getFullImageUrl(_profileImageUrl))
                                    : null,
                                child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                                    ? (_isUploading ? const CircularProgressIndicator(color: Color(0xFF00AA55)) : const Icon(Icons.person, size: 48, color: Color(0xFF2E7D32)))
                                    : null,
                              ),
                            ),
                            Positioned(bottom: 2, right: 2, child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                              child: const Icon(Icons.edit, size: 14, color: Color(0xFF2E7D32)),
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text('$_userVillage, $_userDistrict', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                Positioned(
                  bottom: -35, left: 20, right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem('12', l10n.orders, Icons.shopping_bag_outlined, const Color(0xFF2E7D32)),
                        _buildDivider(),
                        _buildStatItem('5', l10n.rentals, Icons.agriculture_outlined, const Color(0xFFF9A825)),
                        _buildDivider(),
                        _buildStatItem('8', l10n.services, Icons.handyman_outlined, const Color(0xFF1565C0)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 55),
            _buildSectionHeader(l10n.activity),
            _buildActionCard([
              _buildListTile(Icons.history_rounded, 'Activity Bookings', subtitle: 'View your booking history', onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const GenericHistoryScreen(
                  title: 'Activity Bookings',
                  categories: [BookingCategory.services, BookingCategory.farmWorkers, BookingCategory.transport, BookingCategory.rentals],
                )));
              }),
            ]),
            const SizedBox(height: 20),
            _buildSectionHeader(l10n.account),
            _buildActionCard([
              _buildListTile(Icons.person_outline_rounded, l10n.editProfile, onTap: () async {
                final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                if (result == true) _loadProfileData();
              }),
              if (['Owner', 'Provider'].contains(_userRole)) ...[
                _buildDividerLine(),
                _buildListTile(Icons.inventory_2_outlined, 'My Registered Items', onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageItemsScreen()));
                }),
                _buildDividerLine(),
                _buildListTile(Icons.work_outline_rounded, l10n.serviceRequests, onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProviderRequestsScreen()));
                }),
              ],
              _buildDividerLine(),
              _buildListTile(Icons.notifications_none_rounded, l10n.notifications, onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
              }),
              _buildDividerLine(),
              _buildListTile(Icons.language_rounded, l10n.language, trailingText: _selectedLanguage, onTap: () async {
                final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LanguageSelectionScreen(isFromProfile: true)));
                if (result == true) _loadProfileData();
              }),
            ]),
            const SizedBox(height: 20),
            _buildSectionHeader(l10n.support),
            _buildActionCard([
              _buildListTile(Icons.help_outline_rounded, l10n.helpSupport, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HelpSupportScreen()))),
              _buildDividerLine(),
              _buildListTile(Icons.description_outlined, l10n.termsPrivacy, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TermsPrivacyScreen()))),
            ]),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AuthScreen()), (route) => false);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.red[100]!)),
                  backgroundColor: Colors.red[50], minimumSize: const Size(double.infinity, 54),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: Text(l10n.logout, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (image == null) return;
    setState(() => _isUploading = true);
    try {
      final apiService = ApiService();
      final uploadResponse = await apiService.uploadImage(image);
      final String? relativeUrl = uploadResponse['url'];
      if (relativeUrl != null) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id');
        if (userId != null) {
          await apiService.updateUser(userId, {'profileImageUrl': relativeUrl});
          await prefs.setString('user_profile_image', relativeUrl);
          setState(() => _profileImageUrl = relativeUrl);
          if (mounted) UiUtils.showCenteredToast(context, 'Profile photo updated successfully!');
        }
      }
    } catch (e) {
      if (mounted) UiUtils.showCustomAlert(context, 'Failed to upload profile photo: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildStatItem(String count, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(count, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1B5E20))),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildDivider() => Container(height: 30, width: 1, color: Colors.grey[200]);

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Align(alignment: Alignment.centerLeft, child: Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 1.2))),
    );
  }

  Widget _buildActionCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(IconData icon, String title, {String? subtitle, String? trailingText, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) Text(trailingText, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDividerLine() => const Divider(height: 1, indent: 64, endIndent: 20, thickness: 0.8, color: Color(0xFFF1F1F1));
}
