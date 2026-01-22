import 'package:flutter/material.dart';
import '../utils/booking_manager.dart';

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
  String? _selectedDuration;
  bool _includeOperator = false; // "With Driver"
  DateTime? _selectedDate;

  // Duration options with multipliers
  final Map<String, double> _durationOptions = {
    '4 Hours (Half Day)': 0.6, 
    '8 Hours (Full Day)': 1.0, 
    '2 Days': 2.0,
    '3 Days': 3.0,
    '1 Week': 6.0, 
  };

  // Helper to get multiplier
  double _getDurationMultiplier(String duration) {
    if (duration.contains('4 Hours')) return 4;
    if (duration.contains('8 Hours')) return 8;
    if (duration.contains('2 Days')) return 16; // 8*2 working hours
    if (duration.contains('3 Days')) return 24;
    if (duration.contains('1 Week')) return 48;
    return 1;
  }

  double get _totalPrice {
    double multiplier = _selectedDuration != null ? _getDurationMultiplier(_selectedDuration!) : 0;
    double operatorCost = _includeOperator ? (200 * multiplier) : 0; // 200/hr for operator
    return ((widget.rate * multiplier) + operatorCost) * _equipmentCount;
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
      });
    }
  }

  void _confirmBooking() {
    if (_selectedDuration != null && _selectedDate != null) {
      
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
          'Duration': _selectedDuration,
          'Operator Required': _includeOperator ? 'Yes' : 'No',
          'Date': _selectedDate.toString().split(' ')[0],
        }
      ));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rental Request Sent! Added to My Rentals.'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); 
      Navigator.pop(context);
    } else {
      String msg = 'Please fill all details';
      if (_selectedDate == null) msg = 'Select a start date';
      else if (_selectedDuration == null) msg = 'Select rental duration';

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
            const Text(
              'Select Start Date',
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
                    Icon(Icons.calendar_today, color: _selectedDate == null ? Colors.grey[400] : Colors.green),
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
            const SizedBox(height: 24),

            // Duration
            const Text(
              'Rental Duration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
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
                  hint: const Text('Select duration'),
                  value: _selectedDuration,
                  items: _durationOptions.keys.map((String mood) {
                    return DropdownMenuItem<String>(
                      value: mood,
                      child: Text(mood),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDuration = newValue;
                    });
                  },
                ),
              ),
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
                      const Text('Total Estimate:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
                      child: const Text(
                        'Confirm Rental',
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
}
