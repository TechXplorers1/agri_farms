import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/booking_manager.dart';
import 'booking_confirmation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/booking_dto.dart';
import '../services/api_service.dart';

class BookServiceDetailScreen extends StatefulWidget {
  final String providerName;
  final String serviceName;
  final String providerId;
  final String assetId;
  final String priceInfo;

  const BookServiceDetailScreen({
    super.key,
    required this.providerName,
    required this.serviceName,
    required this.providerId,
    required this.assetId,
    required this.priceInfo,
  });

  @override
  State<BookServiceDetailScreen> createState() => _BookServiceDetailScreenState();
}

class _BookServiceDetailScreenState extends State<BookServiceDetailScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  DateTime? _selectedDate;
  List<BookingDTO> _existingBookings = [];
  bool _isLoadingBookings = false;

  // Time Slot Configuration
  final int _startHour = 6; // 6:00 AM
  final int _endHour = 20;  // 8:00 PM (Last slot starts at 8)
  final List<int> _selectedSlots = [];

  // Real Logic: Check if a slot is blocked
  bool _isSlotBlocked(int hour) {
    if (_selectedDate == null) return false;
    
    DateTime slotStart = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, hour);
    DateTime slotEnd = slotStart.add(const Duration(hours: 1)); 

    for (var booking in _existingBookings) {
      if (booking.scheduledStartTime != null && booking.scheduledEndTime != null) {
        if (slotStart.isBefore(booking.scheduledEndTime!) && slotEnd.isAfter(booking.scheduledStartTime!)) {
           if (booking.status != 'CANCELLED' && booking.status != 'REJECTED') {
             return true;
           }
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
        _selectedSlots.sort();
      } else {
        _selectedSlots.add(hour);
        _selectedSlots.sort();
      }
    });
  }

  String _formatTime(int hour) {
      if (hour == 12) return '12 PM';
      if (hour > 12) return '${hour - 12} PM';
      return '$hour AM';
  }

  String _formatTimeRange(int hour) {
    return '${_formatTime(hour)} - ${_formatTime(hour + 1)}';
  }


  @override
  void initState() {
    super.initState();
    _loadAddress();
    _fetchAssetBookings();
  }

  Future<void> _fetchAssetBookings() async {
    setState(() {
      _isLoadingBookings = true;
    });
    try {
      final response = await ApiService().getAssetBookings(widget.assetId);
      final List<dynamic> data = response as List<dynamic>;
      setState(() {
        _existingBookings = data.map((json) => BookingDTO.fromJson(json)).toList();
      });
    } catch (e) {
      debugPrint("Error fetching bookings: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBookings = false;
        });
      }
    }
  }

  Future<void> _loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _addressController.text = prefs.getString('user_address') ?? '';
      if (_addressController.text.isEmpty) {
        // Fallback for demo if address not set, set empty to prompt user
        _addressController.text = '';
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _quantityController.dispose();
    _addressController.dispose();
    super.dispose();
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }



  void _confirmBooking() async {
    if (_selectedDate != null && _quantityController.text.isNotEmpty && _addressController.text.isNotEmpty && _selectedSlots.isNotEmpty) {
      // Save address for future use if it changed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_address', _addressController.text);

      String bookingId = DateTime.now().millisecondsSinceEpoch.toString();
      String dateStr = _selectedDate.toString().split(' ')[0];
      
      // Format time slots
      String timeStr;
      if (_selectedSlots.length == 1) {
        timeStr = _formatTimeRange(_selectedSlots.first);
      } else {
         timeStr = '${_selectedSlots.length} Hours (${_formatTime(_selectedSlots.first)} - ${_formatTime(_selectedSlots.last + 1)})'; // Simplified range display
      }

      final String? userId = prefs.getString('user_id');

      final Map<String, dynamic> notesMap = {
        'Provider': widget.providerName,
        'Service': widget.serviceName,
        'Quantity': _quantityController.text,
        'Preferred Time': timeStr,
        'Slots': _selectedSlots.map((h) => _formatTime(h)).join(', '),
        'Notes': _notesController.text,
      };

      DateTime start = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedSlots.first);
      DateTime end = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedSlots.last + 1);

      BookingDTO dto = BookingDTO(
        farmerId: userId,
        providerId: widget.providerId,
        assetId: widget.assetId,
        assetType: 'Service',
        bookingDate: DateTime.now(),
        scheduledStartTime: start,
        scheduledEndTime: end,
        status: 'PENDING',
        totalAmount: 0.0, // On Request
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
              bookingTitle: widget.serviceName,
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
      if (_quantityController.text.isEmpty) {
        msg = widget.serviceName == 'Harvesting' ? 'Please enter duration (Hours)' : 'Please enter quantity (Acres/Hours)';
      } else if (_addressController.text.isEmpty) msg = 'Please enter service address';
      else if (_selectedDate == null) msg = 'Please select a date';
      else if (_selectedSlots.isEmpty) msg = 'Please select at least one time slot';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Book ${widget.serviceName}'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9), // Light Green
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(10),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       shape: BoxShape.circle,
                       border: Border.all(color: Colors.green.withOpacity(0.2)),
                     ),
                     child: const Icon(Icons.agriculture, color: Color(0xFF00AA55), size: 24),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           widget.providerName,
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           widget.priceInfo,
                           style: TextStyle(color: Colors.green[800], fontSize: 13, fontWeight: FontWeight.w600),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quantity Input
            const Text(
              'Requirement Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: widget.serviceName == 'Harvesting' ? 'Duration (Hours)' : 'Quantity (Acres / Hours)',
                hintText: widget.serviceName == 'Harvesting' ? 'e.g. 4 Hours' : 'e.g. 2 Acres',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            
            const SizedBox(height: 24),

            // Address
            const Text(
              'Service Address (Mandatory)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
             const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter full address for service...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),

            const SizedBox(height: 24),

             // Date Selection
            Text(
              AppLocalizations.of(context)!.selectDate,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
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

            const SizedBox(height: 24),





            // Time Selection
            Text(
              AppLocalizations.of(context)!.preferredTime,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            if (_selectedDate == null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Select a date to view available time slots', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ),
            const SizedBox(height: 12),
            
            // Slots Grid
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
                int hour = _startHour + index;
                bool isBlocked = _isSlotBlocked(hour);
                bool isSelected = _selectedSlots.contains(hour);
                
                return InkWell(
                  onTap: () => _onSlotTap(hour),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isBlocked ? Colors.grey[200] : (isSelected ? const Color(0xFF00AA55) : Colors.white),
                      border: Border.all(
                        color: isBlocked ? Colors.transparent : (isSelected ? const Color(0xFF00AA55) : Colors.grey[300]!)
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _formatTimeRange(hour),
                      style: TextStyle(
                        color: isBlocked ? Colors.grey[400] : (isSelected ? Colors.white : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                        decoration: isBlocked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Notes
             TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Any specific instructions...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 40),

            // Button
             SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0E21),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.confirmRequest,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
