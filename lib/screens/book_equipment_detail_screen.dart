import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/booking_manager.dart';
import 'booking_confirmation_screen.dart';

class BookEquipmentDetailScreen extends StatefulWidget {
  final String providerName;
  final String equipmentType;
  final String providerId;
  final double rate; // Rate per hour or day

  const BookEquipmentDetailScreen({
    super.key,
    required this.providerName,
    required this.equipmentType,
    required this.providerId,
    required this.rate,
  });

  @override
  State<BookEquipmentDetailScreen> createState() => _BookEquipmentDetailScreenState();
}

class _BookEquipmentDetailScreenState extends State<BookEquipmentDetailScreen> {
  int _equipmentCount = 1;
  final List<int> _selectedSlots = []; // Stores selected hours (24h format, e.g., 9, 10, 11)
  bool _includeOperator = false; // "With Driver"
  DateTime? _selectedDate;

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

  void _confirmBooking() {
    if (_selectedSlots.isNotEmpty && _selectedDate != null) {
      // Format duration text
      String durationText;
      if (_selectedSlots.length == 1) {
        durationText = '${_formatTime(_selectedSlots.first)} - ${_formatTime(_selectedSlots.first + 1)}';
      } else {
         durationText = '${_selectedSlots.length} Hours (${_formatTime(_selectedSlots.first)} - ${_formatTime(_selectedSlots.last + 1)})';
      }

      BookingManager().addBooking(BookingDetails(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '${widget.equipmentType} Rental',
        date: _selectedDate.toString().split(' ')[0], 
        price: '₹${_totalPrice.toStringAsFixed(0)}',
        status: 'Pending',
        category: BookingCategory.rentals,
        providerId: widget.providerId,
        details: {
          'Provider': widget.providerName,
          'Equipment': widget.equipmentType,
          'Count': _equipmentCount,
          'Duration': durationText,
          'Operator Required': _includeOperator ? 'Yes' : 'No',
          'Date': _selectedDate.toString().split(' ')[0],
          'Slots': _selectedSlots.map((h) => _formatTime(h)).join(', '),
        }
      ));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmationScreen(
            bookingId: DateTime.now().millisecondsSinceEpoch.toString(),
            bookingTitle: '${widget.equipmentType} Rental',
          ),
        ),
      );
    } else {
      String msg = AppLocalizations.of(context)!.fillAllDetails;
      if (_selectedDate == null) msg = 'Select a start date';
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
                   Container(
                     padding: const EdgeInsets.all(10),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       shape: BoxShape.circle,
                       border: Border.all(color: Colors.green.withOpacity(0.2)),
                     ),
                     child: const Icon(Icons.agriculture, color: Colors.green, size: 24),
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

            // Count
            const Text(
              'Quantity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            _buildCounter('Number of Machines', _equipmentCount, 3, widget.rate.toInt(), (val) {
              setState(() => _equipmentCount = val);
            }),

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

  Widget _buildCounter(String label, int count, int max, int price, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text('at ₹$price / hr', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
          Row(
            children: [
              _buildIconButton(Icons.remove, () {
                if (count > 1) onChanged(count - 1);
              }, isDisabled: count <= 1),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              _buildIconButton(Icons.add, () {
                if (count < max) onChanged(count + 1);
              }, isDisabled: count >= max),
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
        color: isDisabled ? Colors.grey[200] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: isDisabled ? Colors.grey : Colors.green),
        onPressed: isDisabled ? null : onPressed,
      ),
    );
  }
  
  String _formatTime(int hour) {
      if (hour == 12) return '12 PM';
      if (hour > 12) return '${hour - 12} PM';
      return '$hour AM';
  }

  String _formatTimeRange(int hour) {
    return '${_formatTime(hour)} - ${_formatTime(hour + 1)}';
  }
}
