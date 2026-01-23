import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/booking_manager.dart';
import 'booking_confirmation_screen.dart';

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
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime? _selectedDate;

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
              primary: Colors.blue, // Transport Theme Blue
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
    if (_selectedGoodsType != null && _startTime != null && _endTime != null && _selectedDate != null) {
      
      String formattedTime = '${_startTime!.format(context)} - ${_endTime!.format(context)}';

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
          'Date': _selectedDate.toString().split(' ')[0],
        }
      ));

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
      else if (_selectedDate == null) msg = AppLocalizations.of(context)!.selectDateError;
      else if (_startTime == null || _endTime == null) msg = AppLocalizations.of(context)!.selectTimeError;

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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimePicker(
                    context: context, 
                    label: AppLocalizations.of(context)!.startTime, 
                    time: _startTime, 
                    onTap: () => _selectTime(context, true)
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                   child: _buildTimePicker(
                    context: context, 
                    label: AppLocalizations.of(context)!.endTime, 
                    time: _endTime, 
                    onTap: () => _selectTime(context, false)
                  ),
                ),
              ],
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
                Icon(Icons.access_time, size: 18, color: time == null ? Colors.grey[400] : Colors.blue),
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

}
