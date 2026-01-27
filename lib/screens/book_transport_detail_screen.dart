import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/booking_manager.dart';
import 'booking_confirmation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookTransportDetailScreen extends StatefulWidget {
  final String providerName;
  final String vehicleType;
  final String providerId;
  final double rate; // Rate per trip or per km usually, simplifying to 'per trip' for now

  const BookTransportDetailScreen({
    super.key,
    required this.providerName,
    required this.vehicleType,
    required this.providerId,
    required this.rate,
  });

  @override
  State<BookTransportDetailScreen> createState() => _BookTransportDetailScreenState();
}

class _BookTransportDetailScreenState extends State<BookTransportDetailScreen> {

  String? _selectedGoodsType;

  DateTime? _selectedDate;
  final TextEditingController _addressController = TextEditingController();

  // Time Slot Configuration
  final int _startHour = 6; // 6:00 AM
  final int _endHour = 20;  // 8:00 PM (Last slot starts at 8)
  final List<int> _selectedSlots = [];

  // Mock Logic: Check if a slot is blocked
  bool _isSlotBlocked(int hour) {
    if (_selectedDate == null) return false;
    // Deterministic blocking based on date and hour hash
    String dateKey = "${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}";
    int hash = dateKey.hashCode + hour;
    // Block roughly 20% of slots for demonstration
    return (hash % 5) == 0;
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
  
  // Mock data for dropdowns
  final List<String> _goodsTypes = [
    'Crops (Grains/Vegetables)',
    'Fertilizers/Seeds',
    'Machinery/Tools',
    'Livestock',
    'Construction Material',
    'Other',
  ];

  double get _totalPrice {
    // Simple mock calculation: rate * count
    return widget.rate;
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
              primary: Colors.blue,
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
    if (_selectedGoodsType != null && _selectedSlots.isNotEmpty && _selectedDate != null && _addressController.text.isNotEmpty) {
      
      // Save address
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_address', _addressController.text);

      // Format time slots
      String formattedTime;
      if (_selectedSlots.length == 1) {
        formattedTime = _formatTimeRange(_selectedSlots.first);
      } else {
         formattedTime = '${_selectedSlots.length} Hours (${_formatTime(_selectedSlots.first)} - ${_formatTime(_selectedSlots.last + 1)})'; // Simplified range display
      }

      BookingManager().addBooking(BookingDetails(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '${widget.vehicleType} Service',
        date: _selectedDate.toString().split(' ')[0], 
        price: '₹${_totalPrice.toStringAsFixed(0)}',
        status: 'Pending',
        category: BookingCategory.transport,
        providerId: widget.providerId, // Link to provider
        details: {
          'Provider': widget.providerName,
          'Vehicle Type': widget.vehicleType,
          'Vehicle Count': 1,
          'Goods Type': _selectedGoodsType,
          'Time': formattedTime,
          'Slots': _selectedSlots.map((h) => _formatTime(h)).join(', '),
          'Date': _selectedDate.toString().split(' ')[0],
          'Address': _addressController.text,
        }
      ));
      
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmationScreen(
            bookingId: DateTime.now().millisecondsSinceEpoch.toString(),
            bookingTitle: '${widget.vehicleType} Service',
          ),
        ),
      );
    } else {
      String msg = AppLocalizations.of(context)!.fillAllDetails;
      if (_selectedGoodsType == null) msg = AppLocalizations.of(context)!.selectGoodsTypeError;
      else if (_addressController.text.isEmpty) msg = 'Please enter address';
      else if (_selectedDate == null) msg = AppLocalizations.of(context)!.selectDateError;
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
        title: Text(AppLocalizations.of(context)!.bookTransportTitle(widget.vehicleType)),
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
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(10),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       shape: BoxShape.circle,
                       border: Border.all(color: Colors.blue.withOpacity(0.2)),
                     ),
                     child: const Icon(Icons.local_shipping, color: Colors.blue, size: 24),
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
                           '${widget.vehicleType} • ₹${widget.rate.toStringAsFixed(0)} / trip',
                           style: TextStyle(color: Colors.grey[700], fontSize: 13),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Goods Type
            Text(
              AppLocalizations.of(context)!.goodsType,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: Text(AppLocalizations.of(context)!.selectGoodsType),
                  value: _selectedGoodsType,
                  items: _goodsTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGoodsType = newValue;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Pickup/Drop Address
            const Text(
              'Pickup/Drop Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
             const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter pickup or drop location address...',
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
                    Icon(Icons.calendar_today, color: _selectedDate == null ? Colors.grey[400] : Colors.blue),
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
                      color: isBlocked ? Colors.grey[200] : (isSelected ? Colors.blue : Colors.white), // Blue for Transport
                      border: Border.all(
                        color: isBlocked ? Colors.transparent : (isSelected ? Colors.blue : Colors.grey[300]!)
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
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
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
                        backgroundColor: Colors.blue, // Transport Theme Color
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
          ],
        ),
      ),
    );
  }



}
