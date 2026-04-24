import 'package:flutter/material.dart';
import '../utils/booking_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../utils/language_provider.dart';
import 'package:provider/provider.dart';
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
      _loadBookings();
    }
  }

  Future<void> _loadBookings() async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final targetLang = langProvider.languageCode;
    final trans = TranslationService();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null) {
      await _bookingManager.fetchFarmerBookings(userId);
      
      // Apply translation to all loaded bookings
      if (targetLang != 'en') {
        for (var b in _bookingManager.bookings) {
          b.title = await trans.translate(b.title, targetLang);
          b.status = await trans.translate(b.status, targetLang);
          
          // Translate dynamic details map keys and values
          Map<String, dynamic> translatedDetails = {};
          for (var entry in b.details.entries) {
            final translatedKey = await trans.translate(entry.key, targetLang);
            final translatedValue = await trans.translate(entry.value.toString(), targetLang);
            translatedDetails[translatedKey] = translatedValue;
          }
          b.details = translatedDetails;
        }
        // Force rebuild of manager listeners
        _bookingManager.forceRefresh();
      }
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
        backgroundColor: const Color(0xFFF5F7F2),
        appBar: AppBar(
          title: Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: widget.showBackButton,
          centerTitle: true,
          leading: widget.showBackButton ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B5E20), size: 20),
            onPressed: () => Navigator.pop(context),
          ) : null,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
              ),
              child: const TabBar(
                labelColor: Color(0xFF00AA55),
                indicatorColor: Color(0xFF00AA55),
                indicatorWeight: 3,
                unselectedLabelColor: Color(0xFF90A4AE),
                labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.3),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                indicatorSize: TabBarIndicatorSize.label,
                tabs: [
                  Tab(text: 'Requests'),
                  Tab(text: 'Active'),
                  Tab(text: 'History'),
                ],
              ),
            ),
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
                   _buildBookingList(allBookings, ['pending', 'requested'], 'No pending requests', Icons.hourglass_empty_rounded),
                   _buildBookingList(allBookings, ['confirmed', 'scheduled', 'accepted', 'active', 'approve', 'approved'], 'No active bookings', Icons.event_available_rounded),
                   _buildBookingList(allBookings, ['completed', 'finished', 'rejected', 'cancelled'], 'No past history', Icons.history_rounded),
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
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white, 
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
              ),
              child: Icon(emptyIcon, size: 54, color: Colors.grey[200]),
            ),
            const SizedBox(height: 24),
            Text(emptyMessage, style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(filtered[index]);
      },
    );
  }

  Widget _buildServiceCard(BookingDetails booking) {
    statusColor(String status) {
      final s = status.toLowerCase();
      if (['scheduled', 'active', 'confirmed', 'accepted', 'approved', 'approve'].contains(s)) return const Color(0xFF00AA55);
      if (['completed', 'finished'].contains(s)) return const Color(0xFF1565C0);
      if (['rejected', 'cancelled'].contains(s)) return const Color(0xFFE57373);
      return const Color(0xFFF9A825);
    }

    final accentColor = statusColor(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 20, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(booking, accentColor),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardRow(Icons.calendar_today_rounded, 'Scheduled For', _formatBookingDate(booking.date)),
                if (booking.price.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildCardRow(Icons.payments_rounded, 'Rate Info', booking.price),
                  ),
                
                if (booking.details.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBF9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BOOKING DETAILS', 
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey[500], letterSpacing: 0.8)
                        ),
                        const SizedBox(height: 12),
                        ...booking.details.entries.where((e) => !['male_count', 'female_count', 'role_counts', 'Count', 'Vehicle Count'].contains(e.key)).map((e) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 6), 
                                  width: 5, height: 5, 
                                  decoration: BoxDecoration(color: accentColor.withOpacity(0.3), shape: BoxShape.circle)
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text.rich(
                                  TextSpan(children: [
                                    TextSpan(text: '${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1B5E20))),
                                    TextSpan(text: '${e.value}', style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
                                  ]),
                                )),
                              ],
                            ),
                          )
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (['scheduled', 'active', 'confirmed', 'accepted', 'approved'].contains(booking.status.toLowerCase())) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildContactButton('Call Owner', Icons.call_rounded, accentColor, () => _contactUser(booking, true))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildContactButton('WhatsApp', Icons.chat_bubble_rounded, accentColor, () => _contactUser(booking, false), isPrimary: true)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(BookingDetails booking, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.06),
        border: Border(bottom: BorderSide(color: accentColor.withOpacity(0.1), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              booking.title, 
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1B5E20), letterSpacing: -0.3)
            ),
            const SizedBox(height: 4),
            Text(
              'ID #${booking.id.length > 8 ? booking.id.substring(booking.id.length-8).toUpperCase() : booking.id.toUpperCase()}', 
              style: TextStyle(fontSize: 10, color: Colors.grey[500], letterSpacing: 1, fontWeight: FontWeight.w800)
            ),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor, 
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: accentColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Text(
              booking.status.toUpperCase(), 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: const Color(0xFFF5F7F2), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: const Color(0xFF00AA55)),
        ),
        const SizedBox(width: 12),
        Text('$label : ', style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
      ],
    );
  }

  Widget _buildContactButton(String label, IconData icon, Color color, VoidCallback onTap, {bool isPrimary = false}) {
    return Container(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoadingContact ? null : onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? color : Colors.white,
          foregroundColor: isPrimary ? Colors.white : color,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), 
            side: BorderSide(color: color, width: 2)
          ),
        ),
      ),
    );
  }
}
