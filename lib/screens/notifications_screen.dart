import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'provider/provider_requests_screen.dart';
import 'generic_history_screen.dart';
import '../utils/booking_manager.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId != null) {
        final notifications = await _apiService.getUserNotifications(userId);
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String id, int index) async {
    if (_notifications[index]['read'] == true) return;
    try {
      await _apiService.markNotificationAsRead(id);
      setState(() {
        _notifications[index]['read'] = true;
      });
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  void _onNotificationTap(dynamic notification, int index) async {
    // Mark as read first
    if (notification['id'] != null) {
      await _markAsRead(notification['id'], index);
    }

    if (!mounted) return;

    final type = notification['type'] ?? '';

    if (type == 'booking_request') {
      // Asset owner received a new booking request → Service Requests screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ProviderRequestsScreen(),
        ),
      );
    } else if (type == 'booking_status_update') {
      // Farmer/requester received status update → Activity Bookings screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const GenericHistoryScreen(
            title: 'Activity Bookings',
            categories: [
              BookingCategory.services,
              BookingCategory.farmWorkers,
              BookingCategory.transport,
              BookingCategory.rentals,
            ],
            showBackButton: true,
          ),
        ),
      );
    }
    // General notifications: just mark as read, no navigation
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Notifications',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            Text(
              'Your alerts and updates',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final type = notification['type'] ?? '';
                    final isNavigable =
                        type == 'booking_request' || type == 'booking_status_update';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () => _onNotificationTap(notification, index),
                        child: Stack(
                          children: [
                            _buildNotificationCard(
                              type: type,
                              title: notification['title'] ?? 'Notification',
                              description: notification['message'] ?? '',
                              time: _formatTime(notification['createdAt']),
                              isRead: notification['read'] == true,
                            ),
                            if (isNavigable)
                              Positioned(
                                right: 16,
                                bottom: 14,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      type == 'booking_request'
                                          ? 'View Requests'
                                          : 'View Bookings',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: type == 'booking_request'
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFFF57F17),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 10,
                                      color: type == 'booking_request'
                                          ? const Color(0xFF2E7D32)
                                          : const Color(0xFFF57F17),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
                fontSize: 18, color: Colors.grey[800], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something arrives.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required String type,
    required String title,
    required String description,
    required String time,
    required bool isRead,
  }) {
    Color bgColor = Colors.white;
    Color iconBg = const Color(0xFFF1F8E9);
    IconData icon = Icons.notifications_active;
    Color iconColor = const Color(0xFF2E7D32);

    if (type == 'booking_request') {
      bgColor = isRead ? Colors.white : const Color(0xFFE8F5E9);
      iconBg = const Color(0xFFC8E6C9);
      icon = Icons.handshake_outlined;
      iconColor = const Color(0xFF2E7D32);
    } else if (type == 'booking_status_update') {
      bgColor = isRead ? Colors.white : const Color(0xFFFFF8E1);
      iconBg = const Color(0xFFFFECB3);
      icon = Icons.info_outline;
      iconColor = const Color(0xFFF57F17);
    } else {
      bgColor = isRead ? Colors.white : const Color(0xFFF3E5F5);
      iconBg = const Color(0xFFE1BEE7);
      icon = Icons.campaign_outlined;
      iconColor = const Color(0xFF6A1B9A);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (!isRead)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'New',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
          // Extra bottom padding to leave room for the "View →" link
          const SizedBox(height: 24),
          // Time
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
