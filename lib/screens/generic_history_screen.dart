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

String _formatBookingDateTime(BookingDetails booking) {
  final dt = booking.rawScheduledStartTime;
  if (dt != null) {
    try {
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} at $displayHour:$minute $period';
    } catch (_) {}
  }
  return _formatBookingDate(booking.date);
}

String _formatBookingDateOnlyOrTime(DateTime dt) {
  try {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} at $displayHour:$minute $period';
  } catch (_) {
    return dt.toString();
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
  final Set<String> _expandedBookingIds = {};
  bool _isLoadingContact = false;
  Locale? _lastLocale;
  DateTime? _filterDate;
  bool _isInitialLoading = true;
  String _userRole = 'Farmer';

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
    final role = prefs.getString('user_role') ?? 'Farmer';
    final userId = prefs.getString('user_id');
    if (mounted) {
      setState(() {
        _userRole = role;
      });
    }
    if (userId != null) {
      try {
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
      } catch (e) {
        debugPrint('Error loading bookings: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isInitialLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
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
    final isFarmer = _userRole.toLowerCase() == 'farmer';
    return DefaultTabController(
      length: isFarmer ? 2 : 3,
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
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00AA55)),
              onPressed: () async {
                UiUtils.showCenteredToast(context, 'Refreshing bookings...');
                await _loadBookings();
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
              ),
              child: TabBar(
                labelColor: const Color(0xFF00AA55),
                indicatorColor: const Color(0xFF00AA55),
                indicatorWeight: 3,
                unselectedLabelColor: const Color(0xFF90A4AE),
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.3),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                indicatorSize: TabBarIndicatorSize.label,
                tabs: isFarmer
                    ? const [
                        Tab(text: 'Active'),
                        Tab(text: 'History'),
                      ]
                    : const [
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
            if (_bookingManager.isLoading && _isInitialLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF00AA55)));
            }
            
            final allBookings = widget.categories.expand((cat) => _bookingManager.getBookingsByCategory(cat)).toList();
            
            return Column(
              children: [
                if (_filterDate != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                    onRefresh: _loadBookings,
                    color: const Color(0xFF00AA55),
                    child: TabBarView(
                      children: isFarmer
                          ? [
                              _buildBookingList(allBookings, ['pending', 'requested', 'confirmed', 'scheduled', 'accepted', 'active', 'approve', 'approved'], 'No active bookings', Icons.event_available_rounded),
                              _buildBookingList(allBookings, ['completed', 'finished', 'rejected', 'cancelled'], 'No past history', Icons.history_rounded),
                            ]
                          : [
                              _buildBookingList(allBookings, ['pending', 'requested'], 'No pending requests', Icons.hourglass_empty_rounded),
                              _buildBookingList(allBookings, ['confirmed', 'scheduled', 'accepted', 'active', 'approve', 'approved'], 'No active bookings', Icons.event_available_rounded),
                              _buildBookingList(allBookings, ['completed', 'finished', 'rejected', 'cancelled'], 'No past history', Icons.history_rounded),
                            ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingList(List<BookingDetails> bookings, List<String> statuses, String emptyMessage, IconData emptyIcon) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final filtered = bookings.where((b) {
      final s = b.status.trim().toLowerCase();
      final targetDate = b.rawScheduledStartTime ?? b.rawBookingDate;
      final bookingDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
      
      // If a date filter is selected, check if booking date matches selected date
      if (_filterDate != null) {
        final filterDay = DateTime(_filterDate!.year, _filterDate!.month, _filterDate!.day);
        if (bookingDay != filterDay) return false;
      }
      
      if (statuses.contains('completed') || statuses.contains('history')) {
         // This is the history tab. It shows history statuses PLUS past-due pending/active
         if (statuses.contains(s)) return true;
         if (['pending', 'requested', 'confirmed', 'scheduled', 'accepted', 'active', 'approve', 'approved'].contains(s) && bookingDay.isBefore(today)) {
             return true;
         }
         return false;
      }
      
      // For active/pending tabs, must match status AND not be past due
      if (!statuses.contains(s)) return false;
      return !bookingDay.isBefore(today);
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
      final displayMessage = _filterDate != null
          ? 'No bookings found on ${_filterDate!.day} ${_getMonthName(_filterDate!.month)}'
          : emptyMessage;
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
            Text(displayMessage, style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w700)),
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

    final isExpanded = _expandedBookingIds.contains(booking.id);

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
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedBookingIds.remove(booking.id);
                } else {
                  _expandedBookingIds.add(booking.id);
                }
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(booking, accentColor, isExpanded),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, isExpanded ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardRow(Icons.history_rounded, 'Booked At', _formatBookingDateOnlyOrTime(booking.rawBookingDate)),
                      const SizedBox(height: 8),
                      _buildCardRow(Icons.calendar_today_rounded, 'Booked For', _formatBookingDateTime(booking)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (booking.price.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildCardRow(Icons.payments_rounded, 'Rate Info', booking.price),
                    ),
                  if (booking.location != null && booking.location!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: InkWell(
                        onTap: () => _openMap(booking.location!),
                        borderRadius: BorderRadius.circular(8),
                        child: _buildCardRow(Icons.near_me_rounded, 'Location', '${booking.location!} ➔'),
                      ),
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
                          ...booking.details.entries.where((e) => !['male_count', 'female_count', 'role_counts', 'Count', 'Vehicle Count', 'Location', 'location'].contains(e.key)).map((e) =>
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

                  if (booking.status.toLowerCase() == 'cancelled') ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red[100]!, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.cancel_outlined, size: 16, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              Text(
                                'CANCELLATION INFO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.red[700],
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (booking.cancelledBy != null && booking.cancelledBy!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Cancelled By: ',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                                  ),
                                  Text(
                                    booking.cancelledBy!,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Reason: ',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                                    ),
                                    Expanded(
                                      child: Text(
                                        (booking.cancellationReason != null && booking.cancellationReason!.isNotEmpty)
                                            ? booking.cancellationReason!
                                            : 'No reason provided',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                          fontStyle: (booking.cancellationReason != null && booking.cancellationReason!.isNotEmpty)
                                              ? FontStyle.normal
                                              : FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                  if (!['completed', 'finished', 'rejected', 'cancelled'].contains(booking.status.toLowerCase())) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _confirmCancelBooking(booking),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red[700],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.red[100]!, width: 1.5),
                          ),
                          backgroundColor: Colors.red[50],
                        ),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(BookingDetails booking, Color accentColor, bool isExpanded) {
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
          Row(
            children: [
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
              const SizedBox(width: 8),
              Icon(
                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFF1B5E20),
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: const Color(0xFFF5F7F2), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: const Color(0xFF00AA55)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '$label : ', style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w600)),
              TextSpan(text: value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF2C3E50))),
            ]),
          ),
        ),
      ],
    );
  }

  void _confirmCancelBooking(BookingDetails booking) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined, color: Color(0xFFD32F2F), size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cancel Booking',
                style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2C3E50), fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to cancel this booking? This action cannot be undone and will release your scheduled time slot.',
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reason for cancellation (optional):',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLength: 100,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Enter a short description...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF9FBF9),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00AA55), width: 1.5),
                  ),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Keep Booking',
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                Navigator.pop(dialogContext); // Close dialog
                
                // Show loading spinner
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00AA55)),
                  ),
                );
                
                try {
                  final prefs = await SharedPreferences.getInstance();
                  final userName = prefs.getString('user_name') ?? 'Farmer';
                  final userRole = prefs.getString('user_role') ?? 'Farmer';
                  final cancelledBy = '$userRole ($userName)';
                  
                  await _bookingManager.updateBookingStatus(
                    booking.id, 
                    'Cancelled',
                    cancelledBy: cancelledBy,
                    cancellationReason: reason.isNotEmpty ? reason : null,
                  );
                  
                  if (mounted) {
                    Navigator.pop(context); // Close spinner
                    UiUtils.showCenteredToast(context, 'Booking cancelled successfully');
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // Close spinner
                    UiUtils.showCustomAlert(context, 'Failed to cancel booking: $e', isError: true);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Yes, Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
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
