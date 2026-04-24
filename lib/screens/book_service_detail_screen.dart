import 'package:flutter/material.dart';
import 'package:agriculture/l10n/app_localizations.dart';
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

class BookServiceDetailScreen extends StatefulWidget {
  final String providerName;
  final String serviceName;
  final String providerId;
  final String assetId;
  final String priceInfo;
  final String? ownerProfileImage;

  const BookServiceDetailScreen({
    super.key,
    required this.providerName,
    required this.serviceName,
    required this.providerId,
    required this.assetId,
    required this.priceInfo,
    this.ownerProfileImage,
  });

  @override
  State<BookServiceDetailScreen> createState() => _BookServiceDetailScreenState();
}

class _BookServiceDetailScreenState extends State<BookServiceDetailScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, String?> _fieldErrors = {};
  
  // GlobalKeys for scrolling
  final GlobalKey _qtySectionKey = GlobalKey();
  final GlobalKey _addressSectionKey = GlobalKey();
  final GlobalKey _dateSectionKey = GlobalKey();
  final GlobalKey _timeSectionKey = GlobalKey();
  DateTime? _selectedDate;
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

  // Electrician Specific Fields
  final List<String> _electricianPurposes = [
    'Pump Motor Repair',
    'Wiring Installation/Repair',
    'Solar Panel Maintenance',
    'Generator Servicing',
    'Control Panel Troubleshooting',
    'Lighting Installation',
    'Battery/Inverter Maintenance',
    'Others'
  ];

  final List<String> _electricianAssets = [
    'Submersible Pump',
    'Monoblock Pump',
    'Diesel Generator',
    'Solar System',
    'Farmhouse Wiring',
    'Cold Storage Unit',
    'Poultry House Ventilation',
    'Others'
  ];

  String? _selectedPurpose;
  String? _selectedAssetType;
  final TextEditingController _customPurposeController = TextEditingController();
  final TextEditingController _customAssetController = TextEditingController();

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

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    _quantityController.dispose();
    _customPurposeController.dispose();
    _customAssetController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _scrollToField(GlobalKey key) {
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
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
        _selectedStartHour = null;
        _durationHours = 1;
      });
    }
  }



  void _confirmBooking() async {
    bool isElectrician = widget.serviceName == 'Electricians';
    bool isQtyValid = isElectrician 
      ? (_selectedPurpose != null && (_selectedPurpose != 'Others' || _customPurposeController.text.isNotEmpty)) &&
        (_selectedAssetType != null && (_selectedAssetType != 'Others' || _customAssetController.text.isNotEmpty))
      : _quantityController.text.isNotEmpty;

    if (_selectedDate != null && isQtyValid && _addressController.text.isNotEmpty && _selectedSlots.isNotEmpty) {
      setState(() {
        _isSubmitting = true;
      });
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
         timeStr = '${_formatTime(_selectedSlots.first)} - ${_formatTime(_selectedSlots.last + 1)}'; // Simplified range display
      }

      final String? userId = prefs.getString('user_id');
      final String? userName = prefs.getString('user_name');

      final Map<String, dynamic> notesMap = {
        'Booked By': userName ?? 'Unknown User',
        'Provider': widget.providerName,
        'Service': widget.serviceName,
        'Location': _addressController.text,
        'Preferred Time': timeStr,
        'Notes': _notesController.text,
      };

      if (isElectrician) {
        notesMap['Purpose of Visit'] = _selectedPurpose == 'Others' ? _customPurposeController.text : _selectedPurpose;
        notesMap['Asset to Repair'] = _selectedAssetType == 'Others' ? _customAssetController.text : _selectedAssetType;
      } else {
        notesMap['Number of Acres'] = _quantityController.text;
      }

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
              bookingTitle: widget.serviceName,
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
        if (isElectrician) {
          if (_selectedPurpose == null) _fieldErrors['purpose'] = 'Please select purpose of visit';
          else if (_selectedPurpose == 'Others' && _customPurposeController.text.isEmpty) _fieldErrors['purpose_custom'] = 'Please specify purpose';
          
          if (_selectedAssetType == null) _fieldErrors['asset'] = 'Please select asset type';
          else if (_selectedAssetType == 'Others' && _customAssetController.text.isEmpty) _fieldErrors['asset_custom'] = 'Please specify asset name';
        } else {
          if (_quantityController.text.isEmpty) {
            _fieldErrors['qty'] = 'Please enter number of acres';
          }
        }
        
        if (_addressController.text.isEmpty) {
          _fieldErrors['address'] = 'Please enter service address';
        }
        if (_selectedDate == null) {
          _fieldErrors['date'] = 'Please select a date';
        }
        if (_selectedSlots.isEmpty) {
          _fieldErrors['slots'] = 'Please select at least one time slot';
        }
      });

      // Scroll to first error
      if (_fieldErrors.containsKey('purpose') || _fieldErrors.containsKey('purpose_custom') || 
          _fieldErrors.containsKey('asset') || _fieldErrors.containsKey('asset_custom') ||
          _fieldErrors.containsKey('qty')) {
        _scrollToField(_qtySectionKey);
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
    bool isElectrician = widget.serviceName == 'Electricians';
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        title: Text('Book ${widget.serviceName}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1B5E20))),
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
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Info Premium Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
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
                         radius: 35,
                         backgroundColor: const Color(0xFFF1F8F1),
                         backgroundImage: widget.ownerProfileImage != null
                             ? NetworkImage(ApiConfig.getFullImageUrl(widget.ownerProfileImage))
                             : null,
                         child: widget.ownerProfileImage == null
                             ? const Icon(Icons.agriculture_rounded, color: Color(0xFF00AA55), size: 35)
                             : null,
                       ),
                     ),
                   ),
                   const SizedBox(width: 20),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           widget.providerName,
                           style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1B5E20), letterSpacing: -0.5),
                         ),
                         const SizedBox(height: 6),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                           decoration: BoxDecoration(
                             color: const Color(0xFFE8F5E9),
                             borderRadius: BorderRadius.circular(20),
                           ),
                           child: Text(
                             widget.priceInfo,
                             style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 13, fontWeight: FontWeight.w800),
                           ),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Requirement Details Card
            _buildSectionCard(
              key: _qtySectionKey,
              title: 'Requirement Details',
              icon: Icons.list_alt_rounded,
              isError: (_fieldErrors.containsKey('qty') || _fieldErrors.containsKey('purpose') || _fieldErrors.containsKey('asset')),
              child: isElectrician ? Column(
                children: [
                  _buildDropdownField(
                    label: 'Purpose of Visit',
                    hint: 'Choose purpose of visit',
                    value: _selectedPurpose,
                    items: _electricianPurposes,
                    errorKey: 'purpose',
                    icon: Icons.help_outline_rounded,
                    onChanged: (val) => setState(() => _selectedPurpose = val),
                  ),
                  if (_selectedPurpose == 'Others') ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _customPurposeController,
                      label: 'Specify Purpose',
                      hint: 'Enter your custom purpose...',
                      errorKey: 'purpose_custom',
                      icon: Icons.edit_note_rounded,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _buildDropdownField(
                    label: 'Type of Asset',
                    hint: 'Choose type of asset/machinery',
                    value: _selectedAssetType,
                    items: _electricianAssets,
                    errorKey: 'asset',
                    icon: Icons.precision_manufacturing_rounded,
                    onChanged: (val) => setState(() => _selectedAssetType = val),
                  ),
                  if (_selectedAssetType == 'Others') ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _customAssetController,
                      label: 'Specify Asset Name',
                      hint: 'Enter asset/machinery name...',
                      errorKey: 'asset_custom',
                      icon: Icons.edit_rounded,
                    ),
                  ],
                ],
              ) : _buildTextField(
                controller: _quantityController,
                label: 'Number of Acres',
                hint: 'e.g. 2 Acres',
                keyboardType: TextInputType.number,
                errorKey: 'qty',
                icon: Icons.landscape_rounded,
                onChanged: (_) {
                  if (_fieldErrors.containsKey('qty')) setState(() => _fieldErrors.remove('qty'));
                },
              ),
            ),

            // Address Card
            _buildSectionCard(
              key: _addressSectionKey,
              title: 'Service Address',
              icon: Icons.location_on_rounded,
              isError: _fieldErrors.containsKey('address'),
              child: _buildTextField(
                controller: _addressController,
                label: 'Mandatory for service',
                hint: 'Enter full address...',
                maxLines: 3,
                errorKey: 'address',
                icon: Icons.map_rounded,
                suffixIcon: _isFetchingLocation
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00AA55))),
                    )
                  : IconButton(
                      icon: const Icon(Icons.my_location_rounded, color: Color(0xFF00AA55)),
                      tooltip: 'Use my current location',
                      onPressed: _fetchCurrentLocation,
                    ),
                onChanged: (_) {
                  if (_fieldErrors.containsKey('address')) setState(() => _fieldErrors.remove('address'));
                },
              ),
            ),

            // Date & Time Selection Card
            _buildSectionCard(
              key: _dateSectionKey,
              title: 'Schedule Booking',
              icon: Icons.event_available_rounded,
              isError: _fieldErrors.containsKey('date') || _fieldErrors.containsKey('slots'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 10),
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
                          Icon(Icons.calendar_today_rounded, size: 20, color: _selectedDate == null ? Colors.grey[400] : const Color(0xFF00AA55)),
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

                  const SizedBox(height: 30),
                  Text(
                    l10n.preferredTime,
                    key: _timeSectionKey,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)),
                  ),
                  if (_selectedDate == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4),
                      child: Text('Please select a date first', style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                    )
                  else ...[
                    const SizedBox(height: 16),
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
                            if (_selectedSlots.isNotEmpty && _fieldErrors.containsKey('slots')) {
                              setState(() => _fieldErrors.remove('slots'));
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isBlocked 
                                ? Colors.grey[100] 
                                : (isSelected ? const Color(0xFF00AA55) : Colors.white),
                              border: Border.all(
                                color: isBlocked 
                                    ? Colors.transparent 
                                    : (isSelected ? const Color(0xFF00AA55) : const Color(0xFFE8F5E9)),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
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

                    if (_selectedStartHour != null) ...[
                      const SizedBox(height: 30),
                      const Text(
                        'Select Duration',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FBF9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE8F5E9)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    _buildDurationButton(
                                      icon: Icons.remove_rounded,
                                      onPressed: _durationHours > 1 
                                        ? () => setState(() => _durationHours--)
                                        : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      '$_durationHours ${_durationHours == 1 ? 'Hour' : 'Hours'}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
                                    ),
                                    const SizedBox(width: 16),
                                    _buildDurationButton(
                                      icon: Icons.add_rounded,
                                      onPressed: _isRangeAvailable(_selectedStartHour!, _durationHours + 1)
                                        ? () => setState(() => _durationHours++)
                                        : null,
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00AA55).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_formatTime(_selectedStartHour!)} - ${_formatTime(_selectedStartHour! + _durationHours)}',
                                    style: const TextStyle(color: Color(0xFF00AA55), fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            if (!_isRangeAvailable(_selectedStartHour!, _durationHours + 1) && (_selectedStartHour! + _durationHours) < _endHour)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  'Next slot is already booked or unavailable',
                                  style: TextStyle(color: Colors.orange[800], fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            // Additional Notes Card
            _buildSectionCard(
              title: 'Additional Notes',
              icon: Icons.note_add_rounded,
              child: _buildTextField(
                controller: _notesController,
                label: 'Any specific instructions?',
                hint: 'Type here...',
                maxLines: 3,
                errorKey: 'notes',
                icon: Icons.speaker_notes_rounded,
              ),
            ),

            const SizedBox(height: 24),
            // Confirm Button
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00AA55).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
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
            const SizedBox(height: 48),
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

  Widget _buildSectionCard({Key? key, required String title, required IconData icon, required Widget child, bool isError = false}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: isError ? Border.all(color: Colors.red.withOpacity(0.3), width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF00AA55)),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildDurationButton({required IconData icon, VoidCallback? onPressed}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: onPressed == null ? Colors.white : const Color(0xFF00AA55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: onPressed == null ? Colors.grey[200]! : Colors.transparent),
        boxShadow: onPressed != null ? [BoxShadow(color: const Color(0xFF00AA55).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : null,
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: onPressed == null ? Colors.grey[300] : Colors.white),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required String errorKey,
    required ValueChanged<String?> onChanged,
    IconData? icon,
  }) {
    bool hasError = _fieldErrors.containsKey(errorKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w700, 
            color: hasError ? Colors.red : const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
          decoration: _inputDecoration(hint, isError: hasError, icon: icon),
          items: items.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (val) {
            onChanged(val);
            if (_fieldErrors.containsKey(errorKey)) setState(() => _fieldErrors.remove(errorKey));
            if (errorKey == 'purpose' && _fieldErrors.containsKey('purpose_custom')) setState(() => _fieldErrors.remove('purpose_custom'));
            if (errorKey == 'asset' && _fieldErrors.containsKey('asset_custom')) setState(() => _fieldErrors.remove('asset_custom'));
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String errorKey,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    Widget? suffixIcon,
    Function(String)? onChanged,
  }) {
    bool hasError = _fieldErrors.containsKey(errorKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w700, 
            color: hasError ? Colors.red : const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
          onChanged: (val) {
            if (onChanged != null) onChanged(val);
            if (_fieldErrors.containsKey(errorKey)) setState(() => _fieldErrors.remove(errorKey));
          },
          decoration: _inputDecoration(hint, isError: hasError, icon: icon).copyWith(suffixIcon: suffixIcon),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, {bool isError = false, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: const Color(0xFF00AA55)) : null,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: isError ? Colors.red : const Color(0xFFE8F5E9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: isError ? Colors.red : const Color(0xFFE8F5E9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF00AA55), width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FBF9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
