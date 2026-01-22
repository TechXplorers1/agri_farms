import 'package:flutter/material.dart';
import '../utils/booking_manager.dart'; // Import BookingManager
import 'booking_confirmation_screen.dart';

class BookWorkersScreen extends StatefulWidget {
  final String providerName;
  final int maxMale;
  final int maxFemale;
  final int priceMale;
  final int priceFemale;

  const BookWorkersScreen({
    super.key,
    required this.providerName,
    required this.maxMale,
    required this.maxFemale,
    required this.priceMale,
    required this.priceFemale,
  });

  @override
  State<BookWorkersScreen> createState() => _BookWorkersScreenState();
}

class _BookWorkersScreenState extends State<BookWorkersScreen> {
  int _maleCount = 0;
  int _femaleCount = 0;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  int get _totalPrice {
    return (_maleCount * widget.priceMale) + (_femaleCount * widget.priceFemale);
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

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime 
          ? const TimeOfDay(hour: 9, minute: 0) 
          : const TimeOfDay(hour: 17, minute: 0),
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

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _confirmBooking() {
    if ((_maleCount > 0 || _femaleCount > 0) && _startTime != null && _endTime != null && _selectedDate != null) {
      
      String formattedTime = '${_startTime!.format(context)} - ${_endTime!.format(context)}';

      // Save to BookingManager
      BookingManager().addBooking(BookingDetails(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: widget.providerName,
        date: _selectedDate.toString().split(' ')[0],
        price: '₹$_totalPrice',
        status: 'Scheduled',
        category: BookingCategory.farmWorkers,
        details: {
          'Male': _maleCount,
          'Female': _femaleCount,
          'Time': formattedTime,
          'Date': _selectedDate.toString().split(' ')[0],
        }
      ));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmationScreen(
            bookingId: DateTime.now().millisecondsSinceEpoch.toString(), // Ideally reuse the ID
            bookingTitle: widget.providerName,
          ),
        ),
      );
    } else {
      String msg = 'Please fill all details';
      if (_maleCount == 0 && _femaleCount == 0) msg = 'Select at least one worker';
      else if (_selectedDate == null) msg = 'Please select a date';
      else if (_startTime == null || _endTime == null) msg = 'Please select start and end time';

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
        title: const Text('Book Workers'),
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
                         'Available: ${widget.maxMale} Male, ${widget.maxFemale} Female',
                         style: TextStyle(color: Colors.grey[700], fontSize: 13),
                       ),
                     ],
                   ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Worker Selection
            Text(
              'Select Workers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            _buildCounter('Male Workers', _maleCount, widget.maxMale, widget.priceMale, (val) {
              setState(() => _maleCount = val);
            }),
            const SizedBox(height: 16),
            _buildCounter('Female Workers', _femaleCount, widget.maxFemale, widget.priceFemale, (val) {
              setState(() => _femaleCount = val);
            }),

            const SizedBox(height: 32),

            // Date Selection
            Text(
              'Select Date',
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
                          ? 'Choose a date' 
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

            // Time Selection
            Text(
              'Select Time',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your work duration',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimePicker(
                    context: context, 
                    label: 'Start Time', 
                    time: _startTime, 
                    onTap: () => _selectTime(context, true)
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                   child: _buildTimePicker(
                    context: context, 
                    label: 'End Time', 
                    time: _endTime, 
                    onTap: () => _selectTime(context, false)
                  ),
                ),
              ],
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
                      const Text('Total Estimate:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
                      child: const Text(
                        'Confirm Booking',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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

  Widget _buildTimePicker({
    required BuildContext context, 
    required String label, 
    required TimeOfDay? time, 
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: time == null ? Colors.grey[400] : const Color(0xFF00AA55)),
                const SizedBox(width: 8),
                Text(
                  time == null ? '-- : --' : time.format(context),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: time == null ? Colors.grey[400] : Colors.black87,
                  ),
                ),
              ],
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
              Text('₹$price / person', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
          Row(
            children: [
              _buildIconButton(Icons.remove, () {
                if (count > 0) onChanged(count - 1);
              }),
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
