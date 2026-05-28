import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _userMap;

  // State variables for toggles
  bool _orderUpdates = true;
  bool _bookingUpdates = true;
  bool _paymentUpdates = true;
  bool _communityActivity = false; 
  bool _promotionalOffers = false;

  @override
  void initState() {
    super.initState();
    _loadSettingsFromBackend();
  }

  Future<void> _loadSettingsFromBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null) {
        final userData = await _apiService.getUser(userId);
        if (userData != null && userData is Map<String, dynamic>) {
          setState(() {
            _userMap = userData;
            _orderUpdates = userData['notificationOrderUpdates'] ?? true;
            _bookingUpdates = userData['notificationBookingUpdates'] ?? true;
            _paymentUpdates = userData['notificationPaymentUpdates'] ?? true;
            _communityActivity = userData['notificationCommunityActivity'] ?? false;
            _promotionalOffers = userData['notificationPromotionalOffers'] ?? false;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load settings: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _updateSetting(String key, bool val) async {
    if (_userMap == null) return;
    
    setState(() {
      _isSaving = true;
      // Instantly update local switch state
      if (key == 'notificationOrderUpdates') _orderUpdates = val;
      if (key == 'notificationBookingUpdates') _bookingUpdates = val;
      if (key == 'notificationPaymentUpdates') _paymentUpdates = val;
      if (key == 'notificationCommunityActivity') _communityActivity = val;
      if (key == 'notificationPromotionalOffers') _promotionalOffers = val;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null) {
        // Update preference in user map
        _userMap![key] = val;
        
        // Save the full map to avoid resetting primitive defaults
        await _apiService.updateUser(userId, _userMap!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preferences updated successfully'),
              duration: Duration(seconds: 1),
              backgroundColor: Color(0xFF00AA55),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
      // Rollback on failure
      setState(() {
        if (key == 'notificationOrderUpdates') _orderUpdates = !val;
        if (key == 'notificationBookingUpdates') _bookingUpdates = !val;
        if (key == 'notificationPaymentUpdates') _paymentUpdates = !val;
        if (key == 'notificationCommunityActivity') _communityActivity = !val;
        if (key == 'notificationPromotionalOffers') _promotionalOffers = !val;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Column(
            children: [
              if (_isSaving)
                const LinearProgressIndicator(
                  color: Color(0xFF00AA55),
                  backgroundColor: Colors.transparent,
                  minHeight: 2,
                ),
              Container(
                color: Colors.grey[200],
                height: 1.0,
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00AA55),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              children: [
                _buildSwitchTile(
                  title: 'Order Updates',
                  subtitle: 'Get notified about order status',
                  value: _orderUpdates,
                  onChanged: (val) => _updateSetting('notificationOrderUpdates', val),
                ),
                const SizedBox(height: 24),
                _buildSwitchTile(
                  title: 'Booking Updates',
                  subtitle: 'Rental and service bookings',
                  value: _bookingUpdates,
                  onChanged: (val) => _updateSetting('notificationBookingUpdates', val),
                ),
                const SizedBox(height: 24),
                _buildSwitchTile(
                  title: 'Payment Updates',
                  subtitle: 'Transaction notifications',
                  value: _paymentUpdates,
                  onChanged: (val) => _updateSetting('notificationPaymentUpdates', val),
                ),
                const SizedBox(height: 24),
                _buildSwitchTile(
                  title: 'Community Activity',
                  subtitle: 'Replies and mentions',
                  value: _communityActivity,
                  onChanged: (val) => _updateSetting('notificationCommunityActivity', val),
                ),
                const SizedBox(height: 24),
                _buildSwitchTile(
                  title: 'Promotional Offers',
                  subtitle: 'Deals and discounts',
                  value: _promotionalOffers,
                  onChanged: (val) => _updateSetting('notificationPromotionalOffers', val),
                ),
              ],
            ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF001F24), // Dark text color
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Transform.scale(
          scale: 0.8, // Adjust scale to match design if needed
          child: Switch(
            value: value,
            onChanged: _isSaving ? null : onChanged,
            activeColor: Colors.black, // Thumb color when active
            activeTrackColor: Colors.white, // Track color when active
            activeThumbImage: null,
            trackColor: WidgetStateProperty.resolveWith((states) {
               if (states.contains(WidgetState.selected)) {
                 return Colors.black;
               }
               return Colors.grey[300];
            }),
             thumbColor: WidgetStateProperty.all(Colors.white),
             trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ),
      ],
    );
  }
}
