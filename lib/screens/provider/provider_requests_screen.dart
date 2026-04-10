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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text('Service Requests', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00AA55)))
          : AnimatedBuilder(
              animation: _bookingManager,
              builder: (context, _) {
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
                          labelColor: Color(0xFF2E7D32),
                          indicatorColor: Color(0xFF2E7D32),
                          indicatorSize: TabBarIndicatorSize.label,
                          unselectedLabelColor: Colors.grey,
                          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                          tabs: [
                            Tab(text: 'New Requests'),
                            Tab(text: 'Active'),
                            Tab(text: 'History'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildRequestsList(pendingBookings, tabType: 'new', emptyIcon: Icons.inbox_rounded),
                            _buildRequestsList(activeBookings, tabType: 'active', emptyIcon: Icons.task_alt_rounded),
                            _buildRequestsList(historyBookings, tabType: 'history', emptyIcon: Icons.history_rounded),
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

  Widget _buildRequestsList(List<BookingDetails> bookings, {required String tabType, required IconData emptyIcon}) {
    if (bookings.isEmpty) {
      String emptyMessage = 'No history yet';
      if (tabType == 'new') emptyMessage = 'No new requests';
      else if (tabType == 'active') emptyMessage = 'No active bookings';

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: Icon(emptyIcon, size: 48, color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildRequestCard(booking, tabType);
      },
    );
  }

  Widget _buildRequestCard(BookingDetails booking, String tabType) {
    statusColor(String status) {
      final s = status.toLowerCase();
      if (s == 'confirmed') return const Color(0xFF2E7D32);
      if (s == 'completed') return const Color(0xFF1565C0);
      if (s == 'rejected') return const Color(0xFFC62828);
      return const Color(0xFFF9A825);
    }

    final accentColor = statusColor(booking.status);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: accentColor.withValues(alpha: 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(booking.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF2C3E50))),
                    Text('ID: #${booking.id.length > 8 ? booking.id.substring(booking.id.length-8).toUpperCase() : booking.id.toUpperCase()}', style: TextStyle(fontSize: 10, color: Colors.grey[500], letterSpacing: 0.5, fontWeight: FontWeight.w600)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(10)),
                    child: Text(booking.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 8),
                      Text('Scheduled : ', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                      Text(_formatProviderDate(booking.date), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
                      const Spacer(),
                      Text(booking.price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32))),
                    ],
                  ),
                  if (booking.details.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text('REQUEST DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey[500], letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    ...booking.details.entries.where((e) => !['male_count', 'female_count', 'role_counts', 'Provider', 'Count', 'Vehicle Count'].contains(e.key)).map((e) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(margin: const EdgeInsets.only(top: 6), width: 4, height: 4, decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.5), shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Expanded(child: Text.rich(TextSpan(children: [
                              TextSpan(text: '${_formatKey(e.key)}: ', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF2C3E50))),
                              TextSpan(text: '${e.value}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                            ]))),
                          ],
                        ),
                      )
                    ),
                  ],
                  if (tabType == 'new') ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildActionButton('Reject', Colors.red, () => _updateStatus(booking.id, 'Rejected'))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildActionButton('Accept', const Color(0xFF00AA55), () => _updateStatus(booking.id, 'Confirmed'), isPrimary: true)),
                      ],
                    )
                  ],
                  if (tabType == 'active') ...[
                    const SizedBox(height: 20),
                    SizedBox(width: double.infinity, child: _buildActionButton('Mark as Finished', const Color(0xFF1565C0), () => _handleCompletedTap(booking), isPrimary: true)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap, {bool isPrimary = false}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? color : Colors.white,
        foregroundColor: isPrimary ? Colors.white : color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color, width: 1.5)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
    );
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
    if (targetDate.isAfter(now)) {
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Completion', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('This booking is scheduled for the future. Are you sure you want to finish it now? This will free up the time slot.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, elevation: 0), child: const Text('Confirm')),
          ],
        ),
      ) ?? false;
      if (!confirm) return;
    }
    _updateStatus(booking.id, 'Completed');
  }

  String _formatKey(String key) {
    return key.split('_').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' ');
  }
}