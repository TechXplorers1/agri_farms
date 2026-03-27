import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/booking_manager.dart';
import 'booking_confirmation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/booking_dto.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class BookEquipmentDetailScreen extends StatefulWidget {
  final String providerName;
  final String equipmentType;
  final String providerId;
  final String assetId;
  final double rate; // Rate per hour or day
  final String? ownerProfileImage;

  const BookEquipmentDetailScreen({
    super.key,
    required this.providerName,
    required this.equipmentType,
    required this.providerId,
    required this.assetId,
    required this.rate,
    this.ownerProfileImage,
  });

  @override
  State<BookEquipmentDetailScreen> createState() => _BookEquipmentDetailScreenState();
}

class _BookEquipmentDetailScreenState extends State<BookEquipmentDetailScreen> {
  final int _equipmentCount = 1; // Fixed to 1 as per user request
  final List<int> _selectedSlots = []; // Stores selected hours (24h format, e.g., 9, 10, 11)
  bool _includeOperator = false; // "With Driver"
  DateTime? _selectedDate;
  final TextEditingController _addressController = TextEditingController();
  List<BookingDTO> _existingBookings = [];
  bool _isLoadingBookings = false;

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
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // Time Slot Configuration
  final int _startHour = 6; // 6:00 AM
  final int _endHour = 20;  // 8:00 PM (Last slot starts at 8)

  double get _totalPrice {
    // Price calculation based on number of slots (hours)
    // If no slots selected, 0
    if (_selectedSlots.isEmpty) return 0;
    
    double hours = _selectedSlots.length.toDouble();
    double operatorCost = _includeOperator ? (200 * hours) : 0; // 200/hr for operator
    return ((widget.rate * hours) + operatorCost) * _equipmentCount;
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
              primary: Colors.green, // Equipment Theme Green
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
        _selectedSlots.clear(); // Clear slots when date changes
      });
    }
  }

  // Real Logic: Check if a slot is blocked
  bool _isSlotBlocked(int hour) {
    if (_selectedDate == null) return false;
    
    DateTime slotStart = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, hour);
    DateTime slotEnd = slotStart.add(const Duration(hours: 1)); 

    // Block past time slots for today
    if (slotStart.isBefore(DateTime.now())) {
      return true;
    }

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
        // Clean up non-contiguous selection if needed, or allow gaps?
        // For now, simple toggle.
        _selectedSlots.sort();
      } else {
        _selectedSlots.add(hour);
        _selectedSlots.sort();
        // Optional: Enforce contiguous selection logic could go here
        // For now, simpler multi-select for UX clarity
      }
    });
  }

  void _confirmBooking() async {
    if (_selectedSlots.isNotEmpty && _selectedDate != null && _addressController.text.isNotEmpty) {
      // Save address
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_address', _addressController.text);

      // Format duration text
      String durationText;
      if (_selectedSlots.length == 1) {
        durationText = '${_formatTime(_selectedSlots.first)} - ${_formatTime(_selectedSlots.first + 1)}';
      } else {
         durationText = '${_selectedSlots.length} Hours (${_formatTime(_selectedSlots.first)} - ${_formatTime(_selectedSlots.last + 1)})';
      }

      final String? userId = prefs.getString('user_id');

      final Map<String, dynamic> notesMap = {
        'Provider': widget.providerName,
        'Equipment': widget.equipmentType,
        'Count': _equipmentCount,
        'Duration': durationText,
        'Operator Required': _includeOperator ? 'Yes' : 'No',
        'Slots': _selectedSlots.map((h) => _formatTime(h)).join(', '),
      };

      DateTime start = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedSlots.first);
      DateTime end = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedSlots.last + 1);

      BookingDTO dto = BookingDTO(
        farmerId: userId,
        providerId: widget.providerId,
        assetId: widget.assetId,
        assetType: 'Equipment',
        bookingDate: DateTime.now(),
        scheduledStartTime: start,
        scheduledEndTime: end,
        status: 'PENDING',
        totalAmount: _totalPrice,
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
              bookingTitle: '${widget.equipmentType} Rental',
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
      if (_selectedDate == null) {
        msg = 'Select a start date';
      } else if (_addressController.text.isEmpty) msg = 'Please enter delivery address';
      else if (_selectedSlots.isEmpty) msg = 'Select at least one time slot';

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
        title: Text('Rent ${widget.equipmentType}'),
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
                   GestureDetector(
                     onTap: () => _showFullImage(context, widget.ownerProfileImage, widget.providerName),
                     child: CircleAvatar(
                       radius: 30, // Increased size
                       backgroundColor: Colors.white,
                       backgroundImage: widget.ownerProfileImage != null && widget.ownerProfileImage!.isNotEmpty
                           ? NetworkImage(ApiConfig.getFullImageUrl(widget.ownerProfileImage))
                           : null,
                       child: widget.ownerProfileImage == null || widget.ownerProfileImage!.isEmpty
                           ? const Icon(Icons.agriculture, color: Colors.green, size: 30)
                           : null,
                     ),
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
                           '${widget.equipmentType} • ₹${widget.rate.toStringAsFixed(0)} / hr',
                           style: TextStyle(color: Colors.grey[700], fontSize: 13),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Removed Quantity section as per user request
            const SizedBox(height: 8),

            const SizedBox(height: 24),

            // Delivery Address
            const Text(
              'Delivery/Usage Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
             const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter location for equipment delivery/usage...',
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
                    Icon(Icons.calendar_today, color: _selectedDate == null ? Colors.grey[400] : Colors.green),
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

            // Time Slots
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
            
            // Slots Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Reduced to 3 to fit text better
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _endHour - _startHour, // One less item since we show ranges (6-7, 7-8... 19-20)
              itemBuilder: (context, index) {
                int hour = _startHour + index;
                bool isBlocked = _isSlotBlocked(hour);
                bool isSelected = _selectedSlots.contains(hour);
                
                return InkWell(
                  onTap: () => _onSlotTap(hour),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isBlocked ? Colors.grey[200] : (isSelected ? Colors.green : Colors.white),
                      border: Border.all(
                        color: isBlocked ? Colors.transparent : (isSelected ? Colors.green : Colors.grey[300]!)
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

            // Operator Option
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include Driver/Operator', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('+ ₹200 / hr', style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: _includeOperator, 
              activeColor: Colors.green,
              onChanged: (bool val) {
                setState(() {
                  _includeOperator = val;
                });
              }
            ),

             const SizedBox(height: 40),

            // Footer
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
                        '₹${_totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
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
                        backgroundColor: Colors.green, 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.rentNow,
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
  
  
  String _formatTime(int hour) {
      if (hour == 12) return '12 PM';
      if (hour > 12) return '${hour - 12} PM';
      return '$hour AM';
  }

  String _formatTimeRange(int hour) {
    return '${_formatTime(hour)} - ${_formatTime(hour + 1)}';
  }

  void _showFullImage(BuildContext context, String? imageUrl, String title) {
    if (imageUrl == null || imageUrl.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  ApiConfig.getFullImageUrl(imageUrl),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(40),
                    child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
