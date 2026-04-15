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
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
  bool _isFetchingLocation = false;

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
           final String status = booking.status?.toUpperCase() ?? '';
           if (status != 'CANCELLED' && status != 'REJECTED' && status != 'COMPLETED' && status != 'FINISHED') {
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

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) UiUtils.showCenteredToast(context, 'Location services are disabled. Please enable GPS.', isError: true);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) UiUtils.showCenteredToast(context, 'Location permission denied.', isError: true);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) UiUtils.showCenteredToast(context, 'Location permission permanently denied. Enable it in Settings.', isError: true);
        return;
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if ((p.name ?? '').isNotEmpty && p.name != p.thoroughfare) p.name!,
          if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
          if ((p.locality ?? '').isNotEmpty) p.locality!,
          if ((p.administrativeArea ?? '').isNotEmpty) p.administrativeArea!,
          if ((p.postalCode ?? '').isNotEmpty) p.postalCode!,
        ];
        final address = parts.join(', ');
        if (mounted) {
          setState(() => _addressController.text = address);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_address', address);
          if (_fieldErrors.containsKey('address')) setState(() => _fieldErrors.remove('address'));
        }
      }
    } catch (e) {
      if (mounted) UiUtils.showCenteredToast(context, 'Could not fetch location. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        title: Text(l10n.bookTransportTitle(widget.vehicleType), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1B5E20), fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B5E20), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                   GestureDetector(
                     onTap: () => _showFullImage(context, widget.ownerProfileImage, widget.providerName),
                     child: Container(
                       padding: const EdgeInsets.all(3),
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         border: Border.all(color: const Color(0xFF00AA55).withOpacity(0.2), width: 2),
                       ),
                       child: CircleAvatar(
                         radius: 32,
                         backgroundColor: const Color(0xFFF5F7F2),
                         backgroundImage: widget.ownerProfileImage != null && widget.ownerProfileImage!.isNotEmpty
                             ? NetworkImage(ApiConfig.getFullImageUrl(widget.ownerProfileImage))
                             : null,
                         child: widget.ownerProfileImage == null || widget.ownerProfileImage!.isEmpty
                             ? const Icon(Icons.local_shipping_rounded, color: Color(0xFF00AA55), size: 32)
                             : null,
                       ),
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           widget.providerName,
                           style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1B5E20), letterSpacing: -0.5),
                         ),
                         const SizedBox(height: 4),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(
                             color: const Color(0xFFE8F5E9),
                             borderRadius: BorderRadius.circular(8),
                           ),
                           child: Text(
                             '₹${widget.rate.toStringAsFixed(0)} / trip',
                             style: const TextStyle(color: Color(0xFF00AA55), fontSize: 12, fontWeight: FontWeight.w800),
                           ),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Goods Selection
            _buildSectionCard(
              key: _goodsSectionKey,
              title: l10n.goodsType,
              icon: Icons.inventory_2_rounded,
              isError: _fieldErrors.containsKey('goods'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('What are you transporting?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBF9),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _fieldErrors.containsKey('goods') ? Colors.red : const Color(0xFFE8F5E9)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Text(l10n.selectGoodsType, style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w500)),
                        value: _selectedGoodsType,
                        icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF00AA55)),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF2C3E50)),
                        items: _goodsTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedGoodsType = newValue;
                            if (newValue != null && _fieldErrors.containsKey('goods')) _fieldErrors.remove('goods');
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Location Section
            _buildSectionCard(
              key: _addressSectionKey,
              title: 'Lush Pickup/Drop Location',
              icon: Icons.location_on_rounded,
              isError: _fieldErrors.containsKey('address'),
              child: _buildTextField(
                controller: _addressController,
                label: 'Location Address',
                hint: 'Enter pickup/drop location...',
                maxLines: 2,
                errorKey: 'address',
                icon: Icons.map_rounded,
                suffixIcon: _isFetchingLocation
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00AA55))),
                    )
                  : IconButton(
                      icon: const Icon(Icons.my_location_rounded, color: Color(0xFF00AA55)),
                      onPressed: _fetchCurrentLocation,
                    ),
              ),
            ),

            // Schedule Section
            _buildSectionCard(
              key: _dateSectionKey,
              title: 'Transport Schedule',
              icon: Icons.calendar_today_rounded,
              isError: _fieldErrors.containsKey('date') || _fieldErrors.containsKey('slots'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Trip Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      await _selectDate(context);
                      if (_selectedDate != null && _fieldErrors.containsKey('date')) {
                        setState(() => _fieldErrors.remove('date'));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBF9),
                        border: Border.all(color: _fieldErrors.containsKey('date') ? Colors.red : const Color(0xFFE8F5E9)),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 20, color: _selectedDate == null ? Colors.grey[400] : const Color(0xFF00AA55)),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDate == null 
                                ? l10n.chooseDate 
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: TextStyle(
                              fontSize: 15,
                              color: _selectedDate == null ? Colors.grey[500] : Colors.black87,
                              fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.expand_more_rounded, color: Color(0xFF00AA55)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text( 'Select Preferred Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
                  if (_selectedDate == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Select a date first to view availability', style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                    )
                  else ...[
                    const SizedBox(height: 16),
                    if (_isLoadingBookings)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF00AA55))))
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, 
                          childAspectRatio: 2.2, 
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
                              if (_selectedSlots.isNotEmpty && _fieldErrors.containsKey('slots')) setState(() => _fieldErrors.remove('slots'));
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isBlocked ? Colors.grey[100] : (isSelected ? const Color(0xFF00AA55) : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isBlocked ? Colors.transparent : (isSelected ? const Color(0xFF00AA55) : const Color(0xFFE8F5E9)),
                                  width: 1.5,
                                ),
                                boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF00AA55).withOpacity(0.2), blurRadius: 8)] : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _formatTimeRange(hour),
                                style: TextStyle(
                                  color: isBlocked ? Colors.grey[400] : (isSelected ? Colors.white : const Color(0xFF2C3E50)),
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                  fontSize: 11,
                                  decoration: isBlocked ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],

                  if (_selectedStartHour != null) ...[
                    const SizedBox(height: 24),
                    const Text('Transport Duration (Est)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBF9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8F5E9)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildDurationControl(
                                icon: Icons.remove_rounded,
                                onPressed: _durationHours > 1 ? () => setState(() => _durationHours--) : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  '$_durationHours ${_durationHours == 1 ? 'Hour' : 'Hours'}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
                                ),
                              ),
                              _buildDurationControl(
                                icon: Icons.add_rounded,
                                onPressed: _isRangeAvailable(_selectedStartHour!, _durationHours + 1) ? () => setState(() => _durationHours++) : null,
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_formatTime(_selectedStartHour!)} - ${_formatTime(_selectedStartHour! + _durationHours)}',
                              style: const TextStyle(color: Color(0xFF00AA55), fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Footer Total Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.totalEstimate, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF546E7A))),
                      Text(
                        '₹${_totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20), letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF00AA55).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AA55),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : Text(
                            l10n.confirmRequest,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child, GlobalKey? key, bool isError = false}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
        border: isError ? Border.all(color: Colors.red.withOpacity(0.5), width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF00AA55)),
                const SizedBox(width: 12),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20), letterSpacing: 1.2),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String errorKey,
    required IconData icon,
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    final bool hasError = _fieldErrors.containsKey(errorKey);
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: (_) { if (hasError) setState(() => _fieldErrors.remove(errorKey)); },
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF2C3E50)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: hasError ? Colors.red : const Color(0xFF00AA55), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9FBF9),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: hasError ? Colors.red.withOpacity(0.5) : Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF00AA55), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDurationControl({required IconData icon, VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onPressed == null ? Colors.grey[100] : const Color(0xFF00AA55).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: onPressed == null ? Colors.grey[400] : const Color(0xFF00AA55)),
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
                borderRadius: BorderRadius.circular(24),
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
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

