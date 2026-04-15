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
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B5E20), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking History',
          style: TextStyle(color: Color(0xFF1B5E20), fontSize: 18, fontWeight: FontWeight.w900),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7F2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: const Color(0xFF00AA55),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00AA55).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Workers'),
                Tab(text: 'Rentals'),
                Tab(text: 'Services'),
              ],
            ),
          ),
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
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)],
              ),
              child: const Icon(Icons.history_rounded, size: 64, color: Color(0xFFB0BEC5)),
            ),
            const SizedBox(height: 24),
            const Text(
              'No bookings yet',
              style: TextStyle(color: Color(0xFF1B5E20), fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Your service requests will appear here',
              style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildServiceCard(booking);
      },
    );
  }

  Widget _buildServiceCard(BookingDetails booking) {
    Color statusColor = const Color(0xFF00AA55);
    Color statusBg = const Color(0xFF00AA55).withOpacity(0.1);

    final statusLower = booking.status.toLowerCase();
    if (statusLower == 'scheduled' || statusLower == 'active' || statusLower == 'confirmed') {
      statusColor = const Color(0xFF00AA55);
      statusBg = const Color(0xFF00AA55).withOpacity(0.1);
    } else if (statusLower == 'completed' || statusLower == 'finished') {
      statusColor = Colors.blueAccent;
      statusBg = Colors.blueAccent.withOpacity(0.1);
    } else if (statusLower == 'pending') {
      statusColor = Colors.orangeAccent;
      statusBg = Colors.orangeAccent.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          booking.status.toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ),
                      Text(
                        booking.date,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    booking.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 12),
                  if (booking.details.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: booking.details.entries.map((e) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE8F5E9)),
                          ),
                          child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20))),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FBF9),
                border: Border(top: BorderSide(color: Color(0xFFF1F1F1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL AMOUNT', style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(
                        booking.price,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: const Color(0xFF00AA55).withOpacity(0.1), blurRadius: 10)],
                    ),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AA55),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

