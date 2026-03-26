import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/booking_manager.dart'; // Import BookingManager
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
    this.roleDistribution = const [],
  });

  @override
  State<BookWorkersScreen> createState() => _BookWorkersScreenState();
}

class _BookWorkersScreenState extends State<BookWorkersScreen> {
  int _maleCount = 0;
  int _femaleCount = 0;
  DateTime? _selectedDate;
  final List<int> _selectedSlots = [];
  List<dynamic> _existingBookings = [];
  bool _isLoadingBookings = false;
  final int _startHour = 6;
  final int _endHour = 20;

  final TextEditingController _addressController = TextEditingController(); // Add controller

  @override
  void initState() {
    super.initState();
    _maleCount = widget.maxMale;
    _femaleCount = widget.maxFemale;
    _loadAddress();
    // No default date, matching assets style
    _selectedDate = null;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date first')),
      );
      return;
    }
    if (_isSlotBlocked(hour)) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This slot is already booked')),
      );
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
    super.dispose();
  }
  
  final Map<String, int> _selectedRoleCounts = {};

  int get _totalPrice {
    double hours = _selectedSlots.length.toDouble();
    if (hours == 0) hours = 1.0; // Default to 1 hour if no slots selected yet for estimate

    if (widget.roleDistribution.isNotEmpty) {
      int total = 0;
      _selectedRoleCounts.forEach((role, count) {
         bool isMale = role.toLowerCase().contains('men') && !role.toLowerCase().contains('women');
         total += count * (isMale ? widget.priceMale : widget.priceFemale);
      });
      return (total * hours).toInt();
    } else {
      return (((_maleCount * widget.priceMale) + (_femaleCount * widget.priceFemale)) * hours).toInt();
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

    if (hasWorkers && _selectedSlots.isNotEmpty && _selectedDate != null && _addressController.text.isNotEmpty) {
      
      // Save address
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_address', _addressController.text);

      final String? userId = prefs.getString('user_id');

      // Format duration text
      String durationText;
      if (_selectedSlots.length == 1) {
        durationText = '${_formatTime(_selectedSlots.first)} - ${_formatTime(_selectedSlots.first + 1)}';
      } else {
         durationText = '${_selectedSlots.length} Hours (${_formatTime(_selectedSlots.first)} - ${_formatTime(_selectedSlots.last + 1)})';
      }
      
      String detailsStr = '';
      if (widget.roleDistribution.isNotEmpty) {
         detailsStr = _selectedRoleCounts.entries.map((e) {
           String label = e.key;
           try {
              final parts = e.key.split(' ');
              label = parts.sublist(1).join(' ');
              if (label.startsWith('- ')) label = label.substring(2);
           } catch (_) {}
           return '${e.value} $label';
         }).join(', ');
      } else {
        detailsStr = 'Male: $_maleCount, Female: $_femaleCount';
      }

      final Map<String, dynamic> notesMap = {
        'Provider': widget.providerName,
        'Details': detailsStr,
        'Duration': durationText,
        'Slots': _selectedSlots.map((h) => _formatTime(h)).join(', '),
      };

      DateTime start = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedSlots.first, 0);
      DateTime end = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedSlots.last + 1, 0);

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
        await BookingManager().createBooking(dto);
        
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingConfirmationScreen(
              bookingId: "Created Successfully",
              bookingTitle: widget.providerName,
            ),
          ),
        );
      } catch(e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit booking: $e'), backgroundColor: Colors.red),
        );
      }
    } else {
      String msg = AppLocalizations.of(context)!.fillAllDetails;
      if (!hasWorkers) {
        msg = AppLocalizations.of(context)!.selectAtLeastOneWorker;
      } else if (_addressController.text.isEmpty) msg = 'Please enter work location address';
      else if (_selectedDate == null) msg = AppLocalizations.of(context)!.selectDateError;
      else if (_selectedSlots.isEmpty) msg = 'Please select at least one time slot';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
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

            // Worker selection removed as per user request
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Included in this Booking:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (widget.roleDistribution.isNotEmpty)
                    ...widget.roleDistribution.map((role) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $role', style: const TextStyle(fontSize: 14)),
                    ))
                  else ...[
                    Text('• ${widget.maxMale} Male Workers', style: const TextStyle(fontSize: 14)),
                    Text('• ${widget.maxFemale} Female Workers', style: const TextStyle(fontSize: 14)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Address Section
            const Text(
              'Work Location Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter farm address/location...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Date Selection
            Text(
              AppLocalizations.of(context)!.selectDate,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
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
            // Time Selection Slots
            const Text(
              'Select Duration (Time Slots)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
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
                    onTap: () => _onSlotTap(hour),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isBlocked 
                            ? Colors.grey[200] 
                            : isSelected ? const Color(0xFF00AA55) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isBlocked 
                              ? Colors.grey[300]! 
                              : isSelected ? const Color(0xFF00AA55) : Colors.grey[300]!,
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
                      onPressed: _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AA55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
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


   // Removed _buildCounter and _buildIconButton as they were only used for multi-asset booking
  

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
