import 'package:flutter/material.dart';
import '../utils/booking_manager.dart';

class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookingManager _bookingManager = BookingManager();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Services',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00AA55),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF00AA55),
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Farm Workers'),
            Tab(text: 'App Rentals'),
            Tab(text: 'Services'),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: _bookingManager,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(BookingCategory.all),
              _buildBookingList(BookingCategory.farmWorkers),
              _buildBookingList(BookingCategory.rentals),
              _buildBookingList(BookingCategory.services),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingList(BookingCategory category) {
    final bookings = _bookingManager.getBookingsByCategory(category);

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No bookings yet',
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
        return _buildServiceCard(booking);
      },
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

