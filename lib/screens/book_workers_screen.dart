import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/booking_manager.dart'; // Import BookingManager
import '../utils/ui_utils.dart';
import 'booking_confirmation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/booking_dto.dart';
import '../services/api_service.dart';

class BookWorkersScreen extends StatefulWidget {
  final String providerName;
  final String providerId;
  final String assetId;
  final int maxMale;
  final int maxFemale;
  final int priceMale;
  final int priceFemale;
  final int priceMaleHourly;
  final int priceFemaleHourly;
  final List<String> roleDistribution;

  const BookWorkersScreen({
    super.key,
    required this.providerName,
    required this.providerId,
    required this.assetId,
    required this.maxMale,
    required this.maxFemale,
    required this.priceMale,
    required this.priceFemale,
    this.priceMaleHourly = 0,
    this.priceFemaleHourly = 0,
    this.roleDistribution = const [],
  });

  @override
  State<BookWorkersScreen> createState() => _BookWorkersScreenState();
}

class _BookWorkersScreenState extends State<BookWorkersScreen> {
  int _maleCount = 0;
  int _femaleCount = 0;
  String _bookingMode = 'Daily'; // 'Daily' or 'Hourly'
  DateTime? _selectedDate;
  final List<int> _selectedSlots = [];
  List<dynamic> _existingBookings = [];
  bool _isLoadingBookings = false;
  bool _isSubmitting = false;
  final int _startHour = 6;
  final int _endHour = 20;

  final TextEditingController _addressController = TextEditingController(); // Add controller
  final ScrollController _scrollController = ScrollController();
  final Map<String, String?> _fieldErrors = {};
  
  // GlobalKeys for scrolling to sections
  final GlobalKey _workerSectionKey = GlobalKey();
  final GlobalKey _addressSectionKey = GlobalKey();
  final GlobalKey _dateSectionKey = GlobalKey();
  final GlobalKey _timeSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.roleDistribution.isNotEmpty) {
      for (var role in widget.roleDistribution) {
         _selectedRoleCounts[role] = 0; // Default to 0
      }
    } else {
      _maleCount = 0; // Default to 0
      _femaleCount = 0; // Default to 0
    }
    _loadAddress();
    _selectedDate = null;
  }

  // Helper to parse role strings like "10 Male - Harvesting"
  int _getMaxCountForRole(String roleStr) {
     try {
        final firstPart = roleStr.split(' ')[0];
        return int.parse(firstPart);
     } catch (_) {
        return 0;
     }
  }

  String _getGenderForRole(String roleStr) {
     final lowered = roleStr.toLowerCase();
     if (lowered.contains('women') || lowered.contains('female')) return 'Female';
     return 'Male';
  }

  String _getSkillForRole(String roleStr) {
     try {
        final parts = roleStr.split(' - ');
        if (parts.length > 1) return parts[1];
        
        final skipFirst = roleStr.split(' ').sublist(2).join(' ');
        if (skipFirst.startsWith('- ')) return skipFirst.substring(2);
        return skipFirst;
     } catch (_) {
        return roleStr;
     }
  }

  String _formatTime(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour == 12) return '12:00 PM';
    if (hour < 12) return '$hour:00 AM';
    return '${hour - 12}:00 PM';
  }

  String _formatTimeRange(int hour) {
    return '${_formatTime(hour)} - ${_formatTime(hour + 1)}';
  }

  Future<void> _fetchAssetBookings() async {
    if (_selectedDate == null) return;
    
    setState(() => _isLoadingBookings = true);
    try {
      final bookings = await ApiService().getAssetBookings(widget.assetId);
      setState(() {
        _existingBookings = bookings;
        _isLoadingBookings = false;
        _selectedSlots.clear(); // Clear selection when date or data changes
      });
    } catch (e) {
      setState(() => _isLoadingBookings = false);
      print('Error fetching bookings: $e');
    }
  }

  bool _isSlotBlocked(int hour) {
    if (_selectedDate == null) return true;

    // Check past time if selected date is today
    final now = DateTime.now();
    if (_selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day) {
      if (hour <= now.hour) return true;
    }

    // Check existing bookings
    for (var booking in _existingBookings) {
      if (booking['status'] == 'CANCELLED') continue;

      DateTime start = DateTime.parse(booking['scheduledStartTime']);
      DateTime end = DateTime.parse(booking['scheduledEndTime']);

      // Check if this hour overlaps with booking
      // A booking from 9:00 to 11:00 blocks slots 9 and 10.
      if (_selectedDate!.year == start.year &&
          _selectedDate!.month == start.month &&
          _selectedDate!.day == start.day) {
        if (hour >= start.hour && hour < end.hour) {
          return true;
        }
      }
    }
    return false;
  }

  void _onSlotTap(int hour) {
    if (_selectedDate == null) {
      UiUtils.showCenteredToast(context, 'Please select a date first', isError: true);
      return;
    }
    if (_isSlotBlocked(hour)) {
       UiUtils.showCenteredToast(context, 'This slot is already booked', isError: true);
      return;
    }
    setState(() {
      if (_selectedSlots.contains(hour)) {
        _selectedSlots.remove(hour);
      } else {
        _selectedSlots.add(hour);
        _selectedSlots.sort();
      }
    });
  }

  Future<void> _loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _addressController.text = prefs.getString('user_address') ?? '';
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToField(GlobalKey key) {
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
  
  final Map<String, int> _selectedRoleCounts = {};

  int get _totalPrice {
    if (_bookingMode == 'Daily') {
       if (widget.roleDistribution.isNotEmpty) {
         int total = 0;
         _selectedRoleCounts.forEach((role, count) {
            bool isMale = _getGenderForRole(role) == 'Male';
            total += count * (isMale ? widget.priceMale : widget.priceFemale);
         });
         return total;
       } else {
         return (_maleCount * widget.priceMale) + (_femaleCount * widget.priceFemale);
       }
    } else {
       double hours = _selectedSlots.length.toDouble();
       if (hours == 0) hours = 1.0;
   
       if (widget.roleDistribution.isNotEmpty) {
         int total = 0;
         _selectedRoleCounts.forEach((role, count) {
            bool isMale = _getGenderForRole(role) == 'Male';
            // Use hourly price if available, else fallback to daily/8 as approx
            int hourlyMale = widget.priceMaleHourly > 0 ? widget.priceMaleHourly : (widget.priceMale / 8).round();
            int hourlyFemale = widget.priceFemaleHourly > 0 ? widget.priceFemaleHourly : (widget.priceFemale / 8).round();
            total += count * (isMale ? hourlyMale : hourlyFemale);
         });
         return (total * hours).toInt();
       } else {
         int hourlyMale = widget.priceMaleHourly > 0 ? widget.priceMaleHourly : (widget.priceMale / 8).round();
         int hourlyFemale = widget.priceFemaleHourly > 0 ? widget.priceFemaleHourly : (widget.priceFemale / 8).round();
         return (((_maleCount * hourlyMale) + (_femaleCount * hourlyFemale)) * hours).toInt();
       }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00AA55),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && (picked.year != _selectedDate?.year || picked.month != _selectedDate?.month || picked.day != _selectedDate?.day)) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchAssetBookings();
    }
  }


  void _confirmBooking() async {
    bool hasWorkers = widget.roleDistribution.isNotEmpty ? _selectedRoleCounts.isNotEmpty : (_maleCount > 0 || _femaleCount > 0);
    bool hasValidTime = _bookingMode == 'Daily' || _selectedSlots.isNotEmpty;

    if (hasWorkers && hasValidTime && _selectedDate != null && _addressController.text.isNotEmpty) {
      setState(() {
        _isSubmitting = true;
      });

      // Save address
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_address', _addressController.text);

      final String? userId = prefs.getString('user_id');
      final String? userName = prefs.getString('user_name');

      // Format duration text
      String durationText;
      if (_bookingMode == 'Daily') {
         durationText = 'Full Day';
      } else {
         if (_selectedSlots.length == 1) {
           durationText = '${_formatTime(_selectedSlots.first)} - ${_formatTime(_selectedSlots.first + 1)}';
         } else {
            durationText = '${_formatTime(_selectedSlots.first)} - ${_formatTime(_selectedSlots.last + 1)}';
         }
      }
      
      String detailsStr = '';
      if (widget.roleDistribution.isNotEmpty) {
         detailsStr = _selectedRoleCounts.entries
          .where((e) => e.value > 0)
          .map((e) {
            final skill = _getSkillForRole(e.key);
            final gender = _getGenderForRole(e.key);
            return '${e.value} $gender ($skill)';
          }).join(', ');
      } else {
        List<String> parts = [];
        if (_maleCount > 0) parts.add('Male: $_maleCount');
        if (_femaleCount > 0) parts.add('Female: $_femaleCount');
        detailsStr = parts.join(', ');
      }

      final Map<String, dynamic> notesMap = {
        'Booked By': userName ?? 'Unknown User',
        'Provider': widget.providerName,
        'Mode': _bookingMode,
        'Details': detailsStr,
        'Duration': durationText,
        'Location': _addressController.text,
        'Slots': _bookingMode == 'Daily' ? 'Full Day' : _selectedSlots.map((h) => _formatTime(h)).join(', '),
      };

      DateTime start;
      DateTime end;
      if (_bookingMode == 'Daily') {
          start = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 8, 0);
          end = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 18, 0);
      } else {
          start = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedSlots.first, 0);
          end = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedSlots.last + 1, 0);
      }

      BookingDTO dto = BookingDTO(
        farmerId: userId,
        providerId: widget.providerId,
        assetId: widget.assetId,
        assetType: 'worker_group',
        bookingDate: DateTime.now(),
        scheduledStartTime: start,
        scheduledEndTime: end,
        status: 'PENDING',
        totalAmount: _totalPrice.toDouble(),
        addressText: _addressController.text,
        notes: jsonEncode(notesMap),
      );
      
      try {
        final newBooking = await BookingManager().createBooking(dto);
        
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingConfirmationScreen(
              bookingId: newBooking.bookingId ?? "ID-Error",
              bookingTitle: widget.providerName,
            ),
          ),
        );
      } catch(e) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
        UiUtils.showCustomAlert(context, 'Failed to submit booking: $e', isError: true);
      }
    } else {
      setState(() {
        _fieldErrors.clear();
        if (!hasWorkers) {
          _fieldErrors['workers'] = AppLocalizations.of(context)!.selectAtLeastOneWorker;
        }
        if (_addressController.text.isEmpty) {
          _fieldErrors['address'] = 'Please enter work location address';
        }
        if (_selectedDate == null) {
          _fieldErrors['date'] = AppLocalizations.of(context)!.selectDateError;
        }
        if (_bookingMode == 'Hourly' && _selectedSlots.isEmpty) {
          _fieldErrors['slots'] = 'Please select at least one time slot';
        }
      });

      // Scroll to first error
      if (_fieldErrors.containsKey('workers')) {
        _scrollToField(_workerSectionKey);
      } else if (_fieldErrors.containsKey('address')) {
        _scrollToField(_addressSectionKey);
      } else if (_fieldErrors.containsKey('date')) {
        _scrollToField(_dateSectionKey);
      } else if (_fieldErrors.containsKey('slots')) {
        _scrollToField(_timeSectionKey);
      }

      UiUtils.showCenteredToast(context, AppLocalizations.of(context)!.fillAllDetails, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.bookWorkers),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                   const CircleAvatar(
                     backgroundColor: Colors.green,
                     child: Icon(Icons.person, color: Colors.white),
                   ),
                   const SizedBox(width: 12),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         widget.providerName,
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                       ),
                       Text(
                         AppLocalizations.of(context)!.availableWorkers(widget.maxMale, widget.maxFemale),
                         style: TextStyle(color: Colors.grey[700], fontSize: 13),
                       ),
                     ],
                   ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Booking Mode Selection
            const Text(
              'Booking Mode',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _bookingMode = 'Daily';
                        _selectedSlots.clear(); // Clear hourly slots on switch
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _bookingMode == 'Daily' ? const Color(0xFF00AA55) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Daily',
                          style: TextStyle(
                            color: _bookingMode == 'Daily' ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _bookingMode = 'Hourly'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _bookingMode == 'Hourly' ? const Color(0xFF00AA55) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Hourly',
                          style: TextStyle(
                            color: _bookingMode == 'Hourly' ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),


            // Worker selection restored and improved
            Text(
              key: _workerSectionKey,
              AppLocalizations.of(context)!.selectWorkers,
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: _fieldErrors.containsKey('workers') ? Colors.red : Colors.black87
              ),
            ),
            if (_fieldErrors.containsKey('workers'))
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(_fieldErrors['workers']!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 12),
            if (widget.roleDistribution.isNotEmpty)
              ...widget.roleDistribution.map((role) {
                final skill = _getSkillForRole(role);
                final gender = _getGenderForRole(role);
                final maxCount = _getMaxCountForRole(role);
                final currentCount = _selectedRoleCounts[role] ?? 0;
                final price = gender == 'Male' ? widget.priceMale : widget.priceFemale;

                return _buildCounter(
                  label: skill,
                  subtitle: '$gender | ₹$price ${AppLocalizations.of(context)!.perDay} | Max: $maxCount',
                  count: currentCount,
                  max: maxCount,
                  onChanged: (val) => setState(() => _selectedRoleCounts[role] = val),
                );
              })
            else ...[
               _buildCounter(
                 label: AppLocalizations.of(context)!.maleWorkers,
                 subtitle: '₹${widget.priceMale} ${AppLocalizations.of(context)!.perDay} | ${AppLocalizations.of(context)!.available}: ${widget.maxMale}',
                 count: _maleCount,
                 max: widget.maxMale,
                 onChanged: (val) => setState(() => _maleCount = val),
               ),
               _buildCounter(
                 label: AppLocalizations.of(context)!.femaleWorkers,
                 subtitle: '₹${widget.priceFemale} ${AppLocalizations.of(context)!.perDay} | ${AppLocalizations.of(context)!.available}: ${widget.maxFemale}',
                 count: _femaleCount,
                 max: widget.maxFemale,
                 onChanged: (val) => setState(() => _femaleCount = val),
               ),
            ],

            const SizedBox(height: 32),

            // Address Section
            Text(
              key: _addressSectionKey,
              'Work Location Address',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: _fieldErrors.containsKey('address') ? Colors.red : Colors.black87
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              maxLines: 3,
              onChanged: (_) {
                if (_fieldErrors.containsKey('address')) setState(() => _fieldErrors.remove('address'));
              },
              decoration: InputDecoration(
                hintText: 'Enter farm address/location...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _fieldErrors.containsKey('address') ? Colors.red : Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _fieldErrors.containsKey('address') ? Colors.red : Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _fieldErrors.containsKey('address') ? Colors.red : const Color(0xFF00AA55), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Date Selection
            Text(
              key: _dateSectionKey,
              AppLocalizations.of(context)!.selectDate,
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: _fieldErrors.containsKey('date') ? Colors.red : Colors.black87
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                await _selectDate(context);
                if (_selectedDate != null && _fieldErrors.containsKey('date')) {
                  setState(() => _fieldErrors.remove('date'));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _fieldErrors.containsKey('date') ? Colors.red : Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: _selectedDate == null ? Colors.grey[400] : const Color(0xFF00AA55)),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null 
                          ? AppLocalizations.of(context)!.chooseDate 
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate == null ? Colors.grey[500] : Colors.black87,
                        fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_bookingMode == 'Hourly') ...[
              // Time Selection Slots
              Text(
                key: _timeSectionKey,
                'Select Duration (Time Slots)',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: _fieldErrors.containsKey('slots') ? Colors.red : Colors.black87
                ),
              ),
            if (_selectedDate == null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Select a date to view available time slots', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ),
            const SizedBox(height: 12),
            
            if (_isLoadingBookings)
              const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: Color(0xFF00AA55)),
              ))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _endHour - _startHour,
                itemBuilder: (context, index) {
                  final hour = _startHour + index;
                  final isBlocked = _isSlotBlocked(hour);
                  final isSelected = _selectedSlots.contains(hour);

                  return GestureDetector(
                    onTap: () {
                      _onSlotTap(hour);
                      if (_selectedSlots.isNotEmpty && _fieldErrors.containsKey('slots')) {
                         setState(() => _fieldErrors.remove('slots'));
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isBlocked 
                            ? Colors.grey[200] 
                            : isSelected ? const Color(0xFF00AA55) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isBlocked 
                              ? Colors.grey[300]! 
                              : isSelected 
                                  ? const Color(0xFF00AA55) 
                                  : (_fieldErrors.containsKey('slots') ? Colors.red.withOpacity(0.5) : Colors.grey[300]!),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _formatTimeRange(hour),
                        style: TextStyle(
                          color: isBlocked 
                              ? Colors.grey[400] 
                              : isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                          decoration: isBlocked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 40),

            // Footer / Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${AppLocalizations.of(context)!.totalEstimate}:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      Text(
                        '₹$_totalPrice',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00AA55)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AA55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            AppLocalizations.of(context)!.confirmBooking,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
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


  Widget _buildCounter({required String label, required int count, required int max, required Function(int) onChanged, String? subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (subtitle != null)
                   Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              _buildIconButton(Icons.remove, () => onChanged(count - 1), isDisabled: count <= 0),
              SizedBox(
                width: 40,
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              _buildIconButton(Icons.add, () => onChanged(count + 1), isDisabled: count >= max),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed, {bool isDisabled = false}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey[200] : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: isDisabled ? Colors.grey : const Color(0xFF00AA55)),
        onPressed: isDisabled ? null : onPressed,
      ),
    );
  }
}
