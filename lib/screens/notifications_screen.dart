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
        if (mounted) {
          setState(() {
            _notifications = notifications;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id, int index) async {
    if (_notifications[index]['read'] == true) return;
    try {
      await _apiService.markNotificationAsRead(id);
      if (mounted) {
        setState(() {
          _notifications[index]['read'] = true;
        });
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  void _onNotificationTap(dynamic notification, int index) async {
    if (notification['id'] != null) {
      await _markAsRead(notification['id'], index);
    }
    if (!mounted) return;

    final type = notification['type'] ?? '';
    if (type == 'booking_request') {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProviderRequestsScreen()));
    } else if (type == 'booking_status_update') {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const GenericHistoryScreen(
        title: 'Activity Bookings',
        categories: [BookingCategory.services, BookingCategory.farmWorkers, BookingCategory.transport, BookingCategory.rentals],
        showBackButton: true,
      )));
    }
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('MMM dd, hh:mm a').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadNotifications, icon: const Icon(Icons.refresh_rounded, size: 22)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00AA55)))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildPremiumCard(notification, index),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
            child: Icon(Icons.notifications_none_rounded, size: 64, color: Colors.green[200]),
          ),
          const SizedBox(height: 20),
          const Text('No notifications yet', style: TextStyle(fontSize: 18, color: Color(0xFF2C3E50), fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('We\'ll notify you when something important arrives.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(dynamic notification, int index) {
    final type = notification['type'] ?? '';
    final isRead = notification['read'] == true;
    final isNavigable = type == 'booking_request' || type == 'booking_status_update';

    Color accentColor = const Color(0xFF2E7D32);
    IconData icon = Icons.notifications_active_outlined;
    if (type == 'booking_request') {
       accentColor = const Color(0xFF1565C0);
       icon = Icons.handshake_rounded;
    } else if (type == 'booking_status_update') {
       accentColor = const Color(0xFFF9A825);
       icon = Icons.info_rounded;
    }

    return GestureDetector(
      onTap: () => _onNotificationTap(notification, index),
      child: Container(
        decoration: BoxDecoration(
          color: isRead ? Colors.white : accentColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isRead ? Colors.grey[200]! : accentColor.withValues(alpha: 0.2), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(icon, color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(notification['title'] ?? 'Notification', style: TextStyle(fontSize: 15, fontWeight: isRead ? FontWeight.w600 : FontWeight.w800, color: const Color(0xFF2C3E50)))),
                              if (!isRead) Container(width: 8, height: 8, decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(notification['message'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatTime(notification['createdAt']), style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                              if (isNavigable)
                                Row(
                                  children: [
                                    Text('View →', style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
