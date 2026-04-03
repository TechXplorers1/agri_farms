import 'package:flutter/material.dart';
import '../utils/booking_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class GenericHistoryScreen extends StatefulWidget {
  final String title;
  final List<BookingCategory> categories;
  final bool showBackButton;

  const GenericHistoryScreen({
    super.key,
    required this.title,
    required this.categories,
    this.showBackButton = true,
  });

  @override
  State<GenericHistoryScreen> createState() => _GenericHistoryScreenState();
}

class _GenericHistoryScreenState extends State<GenericHistoryScreen> {
  final BookingManager _bookingManager = BookingManager();
  bool _isLoadingContact = false;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null) {
      await _bookingManager.fetchFarmerBookings(userId);
    }
  }

  Future<void> _contactUser(BookingDetails booking, bool isCall) async {
    if (_isLoadingContact) return;
    setState(() => _isLoadingContact = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');
      
      String? targetUserId;
      if (currentUserId == booking.farmerId) {
        targetUserId = booking.providerId;
      } else {
        targetUserId = booking.farmerId;
      }

      if (targetUserId == null || targetUserId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact details not available.')));
        }
        return;
      }

      final apiService = ApiService();
      final userData = await apiService.getUser(targetUserId);
      final phone = userData['phoneNumber'] ?? userData['mobile'];

      if (phone == null || phone.toString().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number not found.')));
        }
        return;
      }

      final uri = isCall 
        ? Uri.parse('tel:$phone')
        : Uri.parse('https://wa.me/$phone');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch app.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error fetching contact info.')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingContact = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            widget.title,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          automaticallyImplyLeading: widget.showBackButton,
          leading: widget.showBackButton ? IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ) : null,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF00AA55),
            indicatorColor: Color(0xFF00AA55),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'My Booking'),
              Tab(text: 'Accepted'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: AnimatedBuilder(
          animation: _bookingManager,
          builder: (context, _) {
            if (_bookingManager.isLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF00AA55)));
            }
            
            final allBookings = widget.categories.expand((cat) => _bookingManager.getBookingsByCategory(cat)).toList();
            
            return RefreshIndicator(
              onRefresh: _loadBookings,
              color: const Color(0xFF00AA55),
              child: TabBarView(
                children: [
                  _buildBookingList(allBookings, ['pending', 'requested'], 'No pending bookings'),
                  _buildBookingList(allBookings, ['confirmed', 'scheduled', 'accepted', 'active', 'approve', 'approved'], 'No active bookings'),
                  _buildBookingList(allBookings, ['completed', 'cancelled', 'rejected', 'finished'], 'No past bookings'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingList(List<BookingDetails> bookings, List<String> statuses, String emptyMessage) {
    final filtered = bookings.where((b) {
      final s = b.status.trim().toLowerCase();
      return statuses.contains(s);
    }).toList();

    if (statuses.contains('pending') || statuses.contains('requested')) {
      filtered.sort((a, b) => b.rawBookingDate.compareTo(a.rawBookingDate)); // Latest requested first
    } else if (statuses.contains('scheduled') || statuses.contains('confirmed') || statuses.contains('accepted')) {
      filtered.sort((a, b) {
        final aDate = a.rawScheduledStartTime ?? a.rawBookingDate;
        final bDate = b.rawScheduledStartTime ?? b.rawBookingDate;
        return aDate.compareTo(bDate); // Earliest actual activity first
      });
    } else {
      filtered.sort((a, b) => b.rawBookingDate.compareTo(a.rawBookingDate)); // Latest finished first
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(filtered[index]);
      },
    );
  }

  Widget _buildServiceCard(BookingDetails booking) {
    Color statusColor = Colors.grey[200]!;
    Color statusTextColor = Colors.black87;

    final statusLower = booking.status.toLowerCase();
    if (statusLower == 'scheduled' || statusLower == 'active' || statusLower == 'confirmed' || statusLower == 'accepted' || statusLower == 'approve') {
      statusColor = const Color(0xFFE8F5E9);
      statusTextColor = const Color(0xFF00AA55);
    } else if (statusLower == 'completed' || statusLower == 'finished') {
      statusColor = Colors.blue[50]!;
      statusTextColor = Colors.blue[700]!;
    } else if (statusLower == 'rejected' || statusLower == 'cancelled') {
      statusColor = Colors.red[50]!;
      statusTextColor = Colors.red[700]!;
    } else {
      statusColor = Colors.orange[50]!;
      statusTextColor = Colors.orange[800]!;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    booking.title, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(
                      color: statusTextColor, 
                      fontWeight: FontWeight.bold,
                      fontSize: 12
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Booked For: ${booking.date}', 
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  )
                ),
                if (booking.price.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(booking.price, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ]
              ],
            ),
            if (booking.details.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text('Request Details:', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              ...booking.details.entries.where((e) => !['Count', 'Vehicle Count'].contains(e.key)).map((e) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle, size: 6, color: Colors.grey[400]),
                      ),
                      const SizedBox(width: 8),
                      Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 13)),
                      Expanded(child: Text('${e.value}', style: TextStyle(color: Colors.grey[700], fontSize: 13))),
                    ],
                  ),
                )
              ),
            ],
            if (statusLower == 'scheduled' || statusLower == 'active' || statusLower == 'confirmed') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoadingContact ? null : () => _contactUser(booking, true),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingContact ? null : () => _contactUser(booking, false),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
