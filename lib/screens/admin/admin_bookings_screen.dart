import 'package:flutter/material.dart';
import '../../utils/booking_manager.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final BookingManager _bookingManager = BookingManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Manage Bookings'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: _bookingManager,
        builder: (context, _) {
          final bookings = _bookingManager.bookings;
          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings to manage'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: ID + Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50], 
                                  shape: BoxShape.circle
                                ),
                                child: Icon(_getIconForCategory(booking.category), size: 20, color: Colors.blue),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#${booking.id.substring(booking.id.length - 6)}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    booking.title, 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                             decoration: BoxDecoration(
                               color: _getStatusColor(booking.status).withOpacity(0.1),
                               borderRadius: BorderRadius.circular(20),
                               border: Border.all(color: _getStatusColor(booking.status).withOpacity(0.3)),
                             ),
                             child: Text(booking.status, style: TextStyle(
                               fontSize: 12, 
                               fontWeight: FontWeight.w600,
                               color: _getStatusColor(booking.status)
                             )),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      
                      // Customer Mock Info
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('Customer: Rahul Verma', style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                          const Spacer(),
                          const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('+91 98765 43210', style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                       Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('Date: ${booking.date}', style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                           const Spacer(),
                           Text(
                             booking.price, 
                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF00AA55))
                           ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Detailed Specs Grid
                      if (booking.details.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Booking Details', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: booking.details.entries.map((e) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_outline, size: 14, color: Colors.green[300]),
                                      const SizedBox(width: 4),
                                      Text('${e.key}: ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                      Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (booking.status != 'Approved' && booking.status != 'Completed' && booking.status != 'Rejected')
                            ElevatedButton(
                              onPressed: () {
                                _bookingManager.updateBookingStatus(booking.id, 'Approved');
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Approved')));
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                              child: const Text('Approve'),
                            ),
                          const SizedBox(width: 8),
                          if (booking.status != 'Completed' && booking.status != 'Rejected')
                            ElevatedButton(
                              onPressed: () {
                                _bookingManager.updateBookingStatus(booking.id, 'Completed');
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as Completed')));
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              child: const Text('Complete'),
                            ),
                           if (booking.status != 'Rejected' && booking.status != 'Completed')
                             TextButton(
                               onPressed: () {
                                 _bookingManager.updateBookingStatus(booking.id, 'Rejected');
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Rejected')));
                               },
                               child: const Text('Reject', style: TextStyle(color: Colors.red)),
                             )
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForCategory(BookingCategory category) {
    switch (category) {
      case BookingCategory.farmWorkers: return Icons.groups;
      case BookingCategory.rentals: return Icons.agriculture;
      case BookingCategory.transport: return Icons.local_shipping;
      case BookingCategory.services: return Icons.construction;
      default: return Icons.bookmark;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Scheduled': return Colors.orange;
      case 'Approved': return Colors.blue;
      case 'Completed': return Colors.green;
      case 'Rejected': return Colors.red;
      default: return Colors.grey;
    }
  }
}
