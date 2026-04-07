import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/booking_manager.dart';
import '../utils/ui_utils.dart';
import 'booking_confirmation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/booking_dto.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class BookTransportDetailScreen extends StatefulWidget {
  final String providerName;
  final String vehicleType;
  final String providerId;
  final String assetId;
  final double rate; // Rate per trip or per km usually, simplifying to 'per trip' for now
  final String? ownerProfileImage;

  const BookTransportDetailScreen({
    super.key,
    required this.providerName,
    required this.vehicleType,
    required this.providerId,
    required this.assetId,
    required this.rate,
    this.ownerProfileImage,
  });

  @override
  State<BookTransportDetailScreen> createState() => _BookTransportDetailScreenState();
}

class _BookTransportDetailScreenState extends State<BookTransportDetailScreen> {

  String? _selectedGoodsType;

  DateTime? _selectedDate;
  final TextEditingController _addressController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, String?> _fieldErrors = {};
  
  // GlobalKeys for scrolling
  final GlobalKey _goodsSectionKey = GlobalKey();
  final GlobalKey _addressSectionKey = GlobalKey();
  final GlobalKey _dateSectionKey = GlobalKey();
  final GlobalKey _timeSectionKey = GlobalKey();
  List<BookingDTO> _existingBookings = [];
  bool _isLoadingBookings = false;
  bool _isSubmitting = false;

  // Time Slot Configuration
  final int _startHour = 6;
  final int _endHour = 20;
  int? _selectedStartHour;
  int _durationHours = 1;

  List<int> get _selectedSlots {
    if (_selectedStartHour == null) return [];
    return List.generate(_durationHours, (i) => _selectedStartHour! + i);
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
      UiUtils.showCenteredToast(context, 'Please select a date first', isError: true);
      return;
    }
    if (_isSlotBlocked(hour)) {
      UiUtils.showCenteredToast(context, 'This slot is already booked', isError: true);
      return;
    }

    setState(() {
      _selectedStartHour = hour;
      _durationHours = 1;
    });
  }

  bool _isRangeAvailable(int startHour, int duration) {
    for (int i = 0; i < duration; i++) {
      if (_isSlotBlocked(startHour + i) || (startHour + i) >= _endHour) {
        return false;
      }
    }
    return true;
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
        _selectedStartHour = null;
        _durationHours = 1;
      });
    }
  }



  void _confirmBooking() async {
    if (_selectedGoodsType != null && _selectedSlots.isNotEmpty && _selectedDate != null && _addressController.text.isNotEmpty) {
      setState(() {
        _isSubmitting = true;
      });
      // Save address
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_address', _addressController.text);
      final String? userId = prefs.getString('user_id');
      final String? userName = prefs.getString('user_name');

      // Format time slots
      String formattedTime;
      if (_selectedSlots.length == 1) {
        formattedTime = _formatTimeRange(_selectedSlots.first);
      } else {
         formattedTime = '${_formatTime(_selectedSlots.first)} - ${_formatTime(_selectedSlots.last + 1)}'; // Simplified range display
      }

      final Map<String, dynamic> notesMap = {
        'Booked By': userName ?? 'Unknown User',
        'Provider': widget.providerName,
        'Vehicle Type': widget.vehicleType,
        'Location': _addressController.text,
        'Goods Type': _selectedGoodsType,
        'Time': formattedTime,
      };

      DateTime start = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedSlots.first);
      DateTime end = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedSlots.last + 1);

      BookingDTO dto = BookingDTO(
        farmerId: userId,
        providerId: widget.providerId,
        assetId: widget.assetId,
        assetType: 'Transport',
        bookingDate: DateTime.now(),
        scheduledStartTime: start,
        scheduledEndTime: end,
        status: 'PENDING',
        totalAmount: _totalPrice,
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
              bookingTitle: '${widget.vehicleType} Service',
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
        if (_selectedGoodsType == null) {
          _fieldErrors['goods'] = AppLocalizations.of(context)!.selectGoodsTypeError;
        }
        if (_addressController.text.isEmpty) {
          _fieldErrors['address'] = 'Please enter address';
        }
        if (_selectedDate == null) {
          _fieldErrors['date'] = AppLocalizations.of(context)!.selectDateError;
        }
        if (_selectedSlots.isEmpty) {
          _fieldErrors['slots'] = 'Please select at least one time slot';
        }
      });

      // Scroll to first error
      if (_fieldErrors.containsKey('goods')) {
        _scrollToField(_goodsSectionKey);
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
        title: Text(AppLocalizations.of(context)!.bookTransportTitle(widget.vehicleType)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
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
                   GestureDetector(
                     onTap: () => _showFullImage(context, widget.ownerProfileImage, widget.providerName),
                     child: CircleAvatar(
                       radius: 30, // Increased size
                       backgroundColor: Colors.white,
                       backgroundImage: widget.ownerProfileImage != null
                           ? NetworkImage(ApiConfig.getFullImageUrl(widget.ownerProfileImage))
                           : null,
                       child: widget.ownerProfileImage == null
                           ? const Icon(Icons.local_shipping, color: Colors.blue, size: 30)
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
              key: _goodsSectionKey,
              AppLocalizations.of(context)!.goodsType,
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: _fieldErrors.containsKey('goods') ? Colors.red : Colors.black87
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _fieldErrors.containsKey('goods') ? Colors.red : Colors.grey[300]!),
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
                      if (newValue != null && _fieldErrors.containsKey('goods')) {
                        _fieldErrors.remove('goods');
                      }
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Pickup/Drop Address
            Text(
              key: _addressSectionKey,
              'Pickup/Drop Address',
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
                hintText: 'Enter pickup or drop location address...',
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
                  borderSide: BorderSide(color: _fieldErrors.containsKey('address') ? Colors.red : Colors.blue, width: 2),
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
              key: _timeSectionKey,
              AppLocalizations.of(context)!.preferredTime,
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: _fieldErrors.containsKey('slots') ? Colors.red : Colors.black87
              ),
            ),
            if (_selectedDate == null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Select a date first to view available slots', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
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
                  onTap: () {
                    _onSlotTap(hour);
                    if (_selectedSlots.isNotEmpty && _fieldErrors.containsKey('slots')) {
                      setState(() => _fieldErrors.remove('slots'));
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isBlocked ? Colors.grey[200] : (isSelected ? Colors.blue : Colors.white),
                      border: Border.all(
                        color: isBlocked 
                            ? Colors.transparent 
                            : (isSelected ? Colors.blue : (_fieldErrors.containsKey('slots') ? Colors.red.withOpacity(0.5) : Colors.grey[300]!)),
                        width: isSelected ? 2 : 1,
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

            if (_selectedStartHour != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Select Duration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildDurationButton(
                          icon: Icons.remove,
                          onPressed: _durationHours > 1 
                            ? () => setState(() => _durationHours--)
                            : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            '$_durationHours ${_durationHours == 1 ? 'Hour' : 'Hours'}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        _buildDurationButton(
                          icon: Icons.add,
                          onPressed: _isRangeAvailable(_selectedStartHour!, _durationHours + 1)
                            ? () => setState(() => _durationHours++)
                            : null,
                        ),
                      ],
                    ),
                    Text(
                      '${_formatTime(_selectedStartHour!)} to ${_formatTime(_selectedStartHour! + _durationHours)}',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (!_isRangeAvailable(_selectedStartHour!, _durationHours + 1) && (_selectedStartHour! + _durationHours) < _endHour)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'Next slot is already booked or unavailable',
                    style: TextStyle(color: Colors.orange[800], fontSize: 12),
                  ),
                ),
            ],

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
                      onPressed: _isSubmitting ? null : _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Transport Theme Color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
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

  Widget _buildDurationButton({required IconData icon, VoidCallback? onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed == null ? Colors.grey[200] : Colors.blue[50],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: onPressed == null ? Colors.grey[400] : Colors.blue),
        onPressed: onPressed,
      ),
    );
  }
}

