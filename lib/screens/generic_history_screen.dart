import 'package:flutter/material.dart';
import '../utils/booking_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class GenericHistoryScreen extends StatefulWidget {
  final String title;
  final List<BookingCategory> categories;

  const GenericHistoryScreen({
    super.key,
    required this.title,
    required this.categories,
  });

  @override
  State<GenericHistoryScreen> createState() => _GenericHistoryScreenState();
}

class _GenericHistoryScreenState extends State<GenericHistoryScreen> {
  final BookingManager _bookingManager = BookingManager();
  bool _isLoadingContact = false;

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[200],
            height: 1.0,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _bookingManager,
        builder: (context, _) {
          final allBookings = widget.categories.expand((cat) => _bookingManager.getBookingsByCategory(cat)).toList();
          // Sort by date or id if needed, for now just list them
          
          if (allBookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No ${widget.title.toLowerCase()} yet',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allBookings.length,
            itemBuilder: (context, index) {
              return _buildServiceCard(allBookings[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(BookingDetails booking) {
    Color statusColor = Colors.grey[200]!;
    Color statusTextColor = Colors.black87;

    final statusLower = booking.status.toLowerCase();
    if (statusLower == 'scheduled' || statusLower == 'active' || statusLower == 'confirmed') {
      statusColor = const Color(0xFFE8F5E9);
      statusTextColor = const Color(0xFF00AA55);
    } else if (statusLower == 'completed') {
      statusColor = Colors.grey[100]!;
      statusTextColor = Colors.grey[600]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.status,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            booking.date,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
           if (booking.details.isNotEmpty) ...[
             const SizedBox(height: 8),
             Wrap(
               spacing: 8,
               children: booking.details.entries.map((e) {
                 return Chip(
                   label: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 10)),
                   padding: EdgeInsets.zero,
                   visualDensity: VisualDensity.compact,
                   backgroundColor: Colors.grey[50],
                   side: BorderSide(color: Colors.grey[200]!),
                 );
               }).toList(),
             ),
           ],
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200], height: 1),
          const SizedBox(height: 16),
          if (statusLower == 'scheduled' || statusLower == 'active' || statusLower == 'confirmed') ...[
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
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking.price,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  foregroundColor: Colors.black87,
                ),
                child: const Text('View Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
