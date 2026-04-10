import 'package:flutter/material.dart';
import '../utils/booking_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/ui_utils.dart';

String _formatBookingDate(String raw) {
  try {
    final dt = DateTime.parse(raw);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return raw;
  }
}

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

      if (targetUserId == null) {
        if (mounted) {
          UiUtils.showCenteredToast(context, 'Contact details not available.', isError: true);
        }
        return;
      }

      final apiService = ApiService();
      final userData = await apiService.getUser(targetUserId);
      final phone = userData['phoneNumber'] ?? userData['mobile'];

      if (phone == null) {
        if (mounted) {
          UiUtils.showCenteredToast(context, 'Phone number not found.', isError: true);
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
          UiUtils.showCenteredToast(context, 'Could not launch app.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        UiUtils.showCustomAlert(context, 'Error fetching contact info.', isError: true);
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
        backgroundColor: const Color(0xFFF9FBF9),
        appBar: AppBar(
          title: Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          automaticallyImplyLeading: widget.showBackButton,
          leading: widget.showBackButton ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ) : null,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF2E7D32),
            indicatorColor: Color(0xFF2E7D32),
            indicatorSize: TabBarIndicatorSize.label,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
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
                   _buildBookingList(allBookings, ['pending', 'requested'], 'No pending bookings', Icons.hourglass_empty_rounded),
                   _buildBookingList(allBookings, ['confirmed', 'scheduled', 'accepted', 'active', 'approve', 'approved'], 'No active bookings', Icons.event_available_rounded),
                   _buildBookingList(allBookings, ['completed', 'finished', 'rejected', 'cancelled'], 'No past bookings', Icons.history_rounded),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingList(List<BookingDetails> bookings, List<String> statuses, String emptyMessage, IconData emptyIcon) {
    final filtered = bookings.where((b) {
      final s = b.status.trim().toLowerCase();
      return statuses.contains(s);
    }).toList();

    if (statuses.contains('pending') || statuses.contains('requested')) {
      filtered.sort((a, b) => b.rawBookingDate.compareTo(a.rawBookingDate));
    } else if (statuses.contains('scheduled') || statuses.contains('confirmed') || statuses.contains('accepted')) {
      filtered.sort((a, b) {
        final aDate = a.rawScheduledStartTime ?? a.rawBookingDate;
        final bDate = b.rawScheduledStartTime ?? b.rawBookingDate;
        return aDate.compareTo(bDate);
      });
    } else {
      filtered.sort((a, b) => b.rawBookingDate.compareTo(a.rawBookingDate));
    }

    if (filtered.isEmpty) {
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
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(filtered[index]);
      },
    );
  }

  Widget _buildServiceCard(BookingDetails booking) {
    statusColor(String status) {
      final s = status.toLowerCase();
      if (['scheduled', 'active', 'confirmed', 'accepted', 'approved', 'approve'].contains(s)) return const Color(0xFF2E7D32);
      if (['completed', 'finished'].contains(s)) return const Color(0xFF1565C0);
      if (['rejected', 'cancelled'].contains(s)) return const Color(0xFFC62828);
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
            _buildCardHeader(booking, accentColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardRow(Icons.calendar_today_rounded, 'Booking Date', _formatBookingDate(booking.date)),
                  if (booking.price.isNotEmpty)
                    _buildCardRow(Icons.payments_outlined, 'Price Info', booking.price),
                  
                  if (booking.details.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text('REQUEST DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey[500], letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    ...booking.details.entries.where((e) => !['male_count', 'female_count', 'role_counts', 'Count', 'Vehicle Count'].contains(e.key)).map((e) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(margin: const EdgeInsets.only(top: 6), width: 4, height: 4, decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.5), shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Expanded(child: Text.rich(TextSpan(children: [
                              TextSpan(text: '${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF2C3E50))),
                              TextSpan(text: '${e.value}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                            ]))),
                          ],
                        ),
                      )
                    ),
                  ],
                  
                  if (['scheduled', 'active', 'confirmed', 'accepted', 'approved'].contains(booking.status.toLowerCase())) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildContactButton('Call', Icons.call_rounded, accentColor, () => _contactUser(booking, true))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildContactButton('Chat', Icons.chat_bubble_rounded, accentColor, () => _contactUser(booking, false), isPrimary: true)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(BookingDetails booking, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: accentColor.withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(booking.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF2C3E50))),
            const SizedBox(height: 2),
            Text('ID: #${booking.id.length > 8 ? booking.id.substring(booking.id.length-8).toUpperCase() : booking.id.toUpperCase()}', style: TextStyle(fontSize: 10, color: Colors.grey[500], letterSpacing: 0.5, fontWeight: FontWeight.w600)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(10)),
            child: Text(booking.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Text('$label : ', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
        ],
      ),
    );
  }

  Widget _buildContactButton(String label, IconData icon, Color color, VoidCallback onTap, {bool isPrimary = false}) {
    return ElevatedButton.icon(
      onPressed: _isLoadingContact ? null : onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? color : Colors.white,
        foregroundColor: isPrimary ? Colors.white : color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color, width: 1.5)),
      ),
    );
  }
}
