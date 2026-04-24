import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../utils/language_provider.dart';
import 'package:provider/provider.dart';
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
  Locale? _lastLocale;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Provider.of<LanguageProvider>(context).locale;
    if (_lastLocale != locale) {
      _lastLocale = locale;
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      final targetLang = langProvider.languageCode;
      final trans = TranslationService();

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null) {
        final notifications = await _apiService.getUserNotifications(userId) as List;
        
        // Apply Translation if not English
        if (targetLang != 'en') {
          for (var n in notifications) {
            if (n['title'] != null) n['title'] = await trans.translate(n['title'], targetLang);
            if (n['message'] != null) n['message'] = await trans.translate(n['message'], targetLang);
          }
        }

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
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1B5E20))),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadNotifications, 
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1B5E20), size: 24)
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00AA55)))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
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
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 30, offset: const Offset(0, 10)),
              ],
            ),
            child: Icon(Icons.notifications_off_rounded, size: 64, color: Colors.grey[200]),
          ),
          const SizedBox(height: 32),
          const Text(
            'All caught up!', 
            style: TextStyle(fontSize: 20, color: Color(0xFF1B5E20), fontWeight: FontWeight.w900, letterSpacing: -0.5)
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when they arrive.', 
            style: TextStyle(fontSize: 15, color: Colors.grey[500], fontWeight: FontWeight.w600)
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(dynamic notification, int index) {
    final type = notification['type'] ?? '';
    final isRead = notification['read'] == true;
    final isNavigable = type == 'booking_request' || type == 'booking_status_update';

    Color accentColor = const Color(0xFF00AA55);
    IconData icon = Icons.notifications_rounded;
    
    if (type == 'booking_request') {
       accentColor = const Color(0xFF1565C0);
       icon = Icons.handshake_rounded;
    } else if (type == 'booking_status_update') {
       accentColor = const Color(0xFFF9A825);
       icon = Icons.info_rounded;
    }

    return GestureDetector(
      onTap: () => _onNotificationTap(notification, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isRead ? Colors.black.withOpacity(0.03) : accentColor.withOpacity(0.08), 
              blurRadius: 15, 
              offset: const Offset(0, 4)
            )
          ],
          border: Border.all(
            color: isRead ? Colors.white : accentColor.withOpacity(0.2), 
            width: 1.5
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isRead ? const Color(0xFFF5F7F2) : accentColor.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(16)
                ),
                child: Icon(icon, color: isRead ? Colors.grey[400] : accentColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] ?? 'Notification', 
                            style: TextStyle(
                              fontSize: 15, 
                              fontWeight: isRead ? FontWeight.w700 : FontWeight.w900, 
                              color: const Color(0xFF2C3E50),
                              letterSpacing: -0.2
                            )
                          ),
                        ),
                        if (!isRead) 
                          Container(
                            width: 10, height: 10, 
                            decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification['message'] ?? '', 
                      style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4, fontWeight: FontWeight.w500)
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(notification['createdAt']), 
                          style: TextStyle(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w700, letterSpacing: 0.5)
                        ),
                        if (isNavigable)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isRead ? Colors.grey[50] : accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'VIEW DETAILS', 
                              style: TextStyle(color: isRead ? Colors.grey[600] : accentColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8)
                            ),
                          ),
                      ],
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
