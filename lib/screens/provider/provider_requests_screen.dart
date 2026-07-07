import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/booking_manager.dart';
import '../../utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:agriculture/l10n/app_localizations.dart';

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
  DateTime? _filterDate;

  String _getMonthName(int month) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[month - 1];
  }

  Future<void> _openMap(String address) async {
    final query = Uri.encodeComponent(address);
    final googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$query";
    final appleMapsUrl = "https://maps.apple.com/?q=$query";
    
    try {
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
        await launchUrl(Uri.parse(appleMapsUrl), mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(Uri.parse(googleMapsUrl));
      }
    } catch (e) {
      if (mounted) {
        UiUtils.showCenteredToast(context, 'Could not open maps application.', isError: true);
      }
    }
  }

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

  Future<void> _handleRefresh() async {
    if (_currentProviderId != null) {
      await _bookingManager.fetchProviderBookings(_currentProviderId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: Text(l10n.serviceRequests, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00AA55)),
            onPressed: () async {
              UiUtils.showCenteredToast(context, 'Refreshing requests...');
              await _handleRefresh();
            },
          ),
          IconButton(
            icon: Icon(
              _filterDate == null ? Icons.calendar_month_rounded : Icons.filter_alt_off_rounded,
              color: const Color(0xFF00AA55),
            ),
            onPressed: () async {
              if (_filterDate != null) {
                setState(() {
                  _filterDate = null;
                });
                return;
              }
              final selected = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF00AA55),
                        onPrimary: Colors.white,
                        onSurface: Color(0xFF1B5E20),
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF00AA55),
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (selected != null) {
                setState(() {
                  _filterDate = selected;
                });
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00AA55)))
          : AnimatedBuilder(
              animation: _bookingManager,
              builder: (context, _) {
                final allMyBookings = (_currentProviderId != null 
                    ? _bookingManager.getBookingsForProvider(_currentProviderId!)
                    : <BookingDetails>[]).toList(); 
                
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                
                final pendingBookings = allMyBookings.where((b) {
                  if (b.status.toLowerCase() != 'pending') return false;
                  if (_filterDate != null) {
                    final targetDate = b.rawScheduledStartTime ?? b.rawBookingDate;
                    final bookingDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
                    final filterDay = DateTime(_filterDate!.year, _filterDate!.month, _filterDate!.day);
                    if (bookingDay != filterDay) return false;
                  }
                  return true;
                }).toList()
                  ..sort((a, b) => b.rawBookingDate.compareTo(a.rawBookingDate));
                  
                final activeBookings = allMyBookings.where((b) {
                  if (b.status.toLowerCase() != 'confirmed') return false;
                  final targetDate = b.rawScheduledStartTime ?? b.rawBookingDate;
                  final bookingDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
                  
                  if (_filterDate != null) {
                    final filterDay = DateTime(_filterDate!.year, _filterDate!.month, _filterDate!.day);
                    if (bookingDay != filterDay) return false;
                  }
                  
                  return !bookingDay.isBefore(today);
                }).toList()
                  ..sort((a, b) {
                    final aDate = a.rawScheduledStartTime ?? a.rawBookingDate;
                    final bDate = b.rawScheduledStartTime ?? b.rawBookingDate;
                    return aDate.compareTo(bDate);
                  });
                  
                final historyBookings = allMyBookings.where((b) {
                  final s = b.status.toLowerCase();
                  final targetDate = b.rawScheduledStartTime ?? b.rawBookingDate;
                  final bookingDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
                  
                  if (_filterDate != null) {
                    final filterDay = DateTime(_filterDate!.year, _filterDate!.month, _filterDate!.day);
                    if (bookingDay != filterDay) return false;
                  }
                  
                  if (['cancelled', 'rejected', 'completed'].contains(s)) return true;
                  if (s == 'confirmed') {
                    return bookingDay.isBefore(today);
                  }
                  return false;
                }).toList()
                  ..sort((a, b) => b.rawBookingDate.compareTo(a.rawBookingDate));

                return DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                          labelColor: const Color(0xFF2E7D32),
                          indicatorColor: const Color(0xFF2E7D32),
                          indicatorSize: TabBarIndicatorSize.label,
                          unselectedLabelColor: Colors.grey,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('New Requests'),
                                  if (pendingBookings.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFC62828),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${pendingBookings.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Tab(text: 'Active'),
                            const Tab(text: 'History'),
                          ],
                        ),
                      ),
                      if (_filterDate != null)
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00AA55).withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.filter_list_rounded, color: Color(0xFF1B5E20), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Filtered by: ${_filterDate!.day} ${_getMonthName(_filterDate!.month)} ${_filterDate!.year}',
                                  style: const TextStyle(
                                    color: Color(0xFF1B5E20),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _filterDate = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Color(0xFF1B5E20), size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _handleRefresh,
                          color: const Color(0xFF2E7D32),
                          child: TabBarView(
                            children: [
                              _buildRequestsList(pendingBookings, tabType: 'new', emptyIcon: Icons.inbox_rounded),
                              _buildRequestsList(activeBookings, tabType: 'active', emptyIcon: Icons.task_alt_rounded),
                              _buildRequestsList(historyBookings, tabType: 'history', emptyIcon: Icons.history_rounded),
                            ],
                          ),
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

      final displayMessage = _filterDate != null
          ? 'No bookings found on ${_filterDate!.day} ${_getMonthName(_filterDate!.month)}'
          : emptyMessage;

      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                child: Icon(emptyIcon, size: 48, color: Colors.grey[300]),
              ),
              const SizedBox(height: 16),
              Text(displayMessage, style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
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
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1.5),
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
                  if (booking.location != null && booking.location!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _openMap(booking.location!),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.near_me_rounded, size: 14, color: Color(0xFF00AA55)),
                            const SizedBox(width: 8),
                            Text('Location: ', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                            Expanded(
                              child: Text(
                                '${booking.location!} ➔',
                                style: const TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.w700, 
                                  color: Color(0xFF00AA55),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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

  Future<void> _updateStatus(String id, String status) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00AA55)),
      ),
    );

    try {
      if (_currentProviderId != null) {
        await _bookingManager.updateBookingStatus(id, status, providerId: _currentProviderId);
      } else {
        await _bookingManager.updateBookingStatus(id, status);
      }
      if (mounted) {
        Navigator.pop(context); // Close loading spinner
        UiUtils.showCenteredToast(context, 'Booking status updated to $status');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading spinner
        UiUtils.showCustomAlert(context, 'Failed to update status: $e', isError: true);
      }
    }
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
