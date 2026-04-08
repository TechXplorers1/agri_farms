import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/booking_manager.dart';
import '../../utils/ui_utils.dart';

String _formatProviderDate(String raw) {
  try {
    final dt = DateTime.parse(raw);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return raw;
  }
}

class ProviderRequestsScreen extends StatefulWidget {
  const ProviderRequestsScreen({super.key});

  @override
  State<ProviderRequestsScreen> createState() => _ProviderRequestsScreenState();
}

class _ProviderRequestsScreenState extends State<ProviderRequestsScreen> {
  String? _currentProviderId; 
  final BookingManager _bookingManager = BookingManager();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviderIdAndBookings();
  }

  Future<void> _loadProviderIdAndBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    setState(() {
      _currentProviderId = userId;
    });

    if (_currentProviderId != null) {
      await _bookingManager.fetchProviderBookings(_currentProviderId!);
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Service Requests'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent background
      appBar: AppBar(
        title: const Text('Service Requests'), // Generalized title
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: _bookingManager,
        builder: (context, _) {
          // Filter for my bookings that are pending
          // Removed category filter to show Transport/Rentals too
          final allMyBookings = (_currentProviderId != null 
              ? _bookingManager.getBookingsForProvider(_currentProviderId!)
              : <BookingDetails>[]).toList(); 
          final pendingBookings = allMyBookings.where((b) => b.status.toLowerCase() == 'pending').toList()
            ..sort((a, b) => b.rawBookingDate.compareTo(a.rawBookingDate));
            
          final activeBookings = allMyBookings.where((b) => b.status.toLowerCase() == 'confirmed').toList()
            ..sort((a, b) {
              final aDate = a.rawScheduledStartTime ?? a.rawBookingDate;
              final bDate = b.rawScheduledStartTime ?? b.rawBookingDate;
              return aDate.compareTo(bDate);
            });
            
          final historyBookings = allMyBookings.where((b) => b.status.toLowerCase() != 'pending' && b.status.toLowerCase() != 'confirmed').toList()
            ..sort((a, b) => b.rawBookingDate.compareTo(a.rawBookingDate));

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: const TabBar(
                    labelColor: Colors.green,
                    indicatorColor: Colors.green,
                    tabs: [
                      Tab(text: 'New Requests'),
                      Tab(text: 'Active Bookings'),
                      Tab(text: 'History'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildRequestsList(pendingBookings, tabType: 'new'),
                      _buildRequestsList(activeBookings, tabType: 'active'),
                      _buildRequestsList(historyBookings, tabType: 'history'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestsList(List<BookingDetails> bookings, {required String tabType}) {
    if (bookings.isEmpty) {
      String emptyMessage = 'No history yet';
      if (tabType == 'new') emptyMessage = 'No new requests';
      else if (tabType == 'active') emptyMessage = 'No active bookings';

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
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
                  children: [
                    Text(
                      booking.title, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        booking.status,
                        style: TextStyle(
                          color: _getStatusColor(booking.status), 
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
                    Text('Booked for : ${_formatProviderDate(booking.date)}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(width: 16),
                    Text(booking.price, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
                if (booking.details.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Request Details:', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  // Special handling for worker counts to look better
                  if (booking.details.containsKey('male_count') || booking.details.containsKey('female_count')) ...[
                     Row(
                       children: [
                         if (booking.details.containsKey('male_count'))
                           _buildWorkerChip('Men: ${booking.details['male_count']}', Colors.blue),
                         if (booking.details.containsKey('male_count') && booking.details.containsKey('female_count'))
                           const SizedBox(width: 12),
                         if (booking.details.containsKey('female_count'))
                           _buildWorkerChip('Women: ${booking.details['female_count']}', Colors.pink),
                       ],
                     ),
                     const SizedBox(height: 8),
                  ],
                   ...booking.details.entries.where((e) => !['male_count', 'female_count', 'Provider', 'Count', 'Vehicle Count'].contains(e.key)).map((e) => // Hide Provider name if redundant
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: Colors.grey[400]),
                          const SizedBox(width: 8),
                          Text('${_formatKey(e.key)}: ', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 13)),
                          Text('${e.value}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        ],
                      ),
                    )
                  ),
                ],
                if (booking.id.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.confirmation_number_outlined, size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        'Booking ID: #${booking.id.length > 6 ? booking.id.substring(booking.id.length - 6).toUpperCase() : booking.id.toUpperCase()}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ],
                if (tabType == 'new') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateStatus(booking.id, 'Rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateStatus(booking.id, 'Confirmed'), // Using 'Confirmed' as accepted
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  )
                ],
                if (tabType == 'active') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleCompletedTap(booking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Mark as Finished'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      case 'completed': return Colors.blue;
      default: return Colors.grey;
    }
  }

  void _updateStatus(String id, String status) {
    if (_currentProviderId != null) {
      _bookingManager.updateBookingStatus(id, status, providerId: _currentProviderId);
    } else {
      _bookingManager.updateBookingStatus(id, status);
    }
    
    UiUtils.showCenteredToast(context, 'Booking status updated to $status');
  }

  Future<void> _handleCompletedTap(BookingDetails booking) async {
    final now = DateTime.now();
    final targetDate = booking.rawScheduledStartTime ?? booking.rawBookingDate;
    
    // Check if the scheduled time is in the future
    if (targetDate.isAfter(now)) {
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Completion'),
          content: const Text('This booking is scheduled for a future date or time. Are you sure you want to mark it as completed now? This will immediately open up the time slot for others to book.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Yes, Complete'),
            ),
          ],
        ),
      ) ?? false;
      
      if (!confirm) return;
    }
    
    _updateStatus(booking.id, 'Completed');
  }

  Widget _buildWorkerChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  String _formatKey(String key) {
    return key.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
}