import 'package:flutter/material.dart';
import '../../utils/booking_manager.dart';

class ProviderRequestsScreen extends StatefulWidget {
  const ProviderRequestsScreen({super.key});

  @override
  State<ProviderRequestsScreen> createState() => _ProviderRequestsScreenState();
}

class _ProviderRequestsScreenState extends State<ProviderRequestsScreen> {
  // Assuming the current signed-in user is Provider with ID '2'
  final String _currentProviderId = '2'; 
  final BookingManager _bookingManager = BookingManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent background
      appBar: AppBar(
        title: const Text('Worker Requests'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: _bookingManager,
        builder: (context, _) {
          // Filter for my bookings that are pending
          // In a real app, you might show history too, providing a tab for 'Pending' and 'History'
          final allMyBookings = _bookingManager.getBookingsForProvider(_currentProviderId);
          final pendingBookings = allMyBookings.where((b) => b.status == 'Pending').toList();
          final historyBookings = allMyBookings.where((b) => b.status != 'Pending').toList();

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: const TabBar(
                    labelColor: Colors.green,
                    indicatorColor: Colors.green,
                    tabs: [
                      Tab(text: 'New Requests'),
                      Tab(text: 'History'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildRequestsList(pendingBookings, isPending: true),
                      _buildRequestsList(historyBookings, isPending: false),
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

  Widget _buildRequestsList(List<BookingDetails> bookings, {required bool isPending}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No new requests' : 'No history yet',
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
                    Text(booking.date, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(width: 16),
                    Icon(Icons.currency_rupee, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
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
                           _buildWorkerChip(Icons.male, 'Men: ${booking.details['male_count']}', Colors.blue),
                         if (booking.details.containsKey('male_count') && booking.details.containsKey('female_count'))
                           const SizedBox(width: 12),
                         if (booking.details.containsKey('female_count'))
                           _buildWorkerChip(Icons.female, 'Women: ${booking.details['female_count']}', Colors.pink),
                       ],
                     ),
                     const SizedBox(height: 8),
                  ],
                   ...booking.details.entries.where((e) => !['male_count', 'female_count'].contains(e.key)).map((e) => 
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
                if (isPending) ...[
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
      default: return Colors.grey;
    }
  }

  void _updateStatus(String id, String status) {
    _bookingManager.updateBookingStatus(id, status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request $status'),
        backgroundColor: status == 'Confirmed' ? Colors.green : Colors.red,
        duration: const Duration(seconds: 1),
      )
    );
  }

  Widget _buildWorkerChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
}
