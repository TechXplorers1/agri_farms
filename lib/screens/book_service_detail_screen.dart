import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agriculture/l10n/app_localizations.dart';
import '../utils/booking_manager.dart';
import '../utils/app_translations.dart';
import '../utils/ui_utils.dart';
import 'booking_confirmation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/booking_dto.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../utils/location_helper.dart';
import '../services/geocoding_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:async';


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

  // New Geocoding & Calendar Fields
  double? _detectedLat;
  double? _detectedLng;
  bool _isGeocodingAddress = false;
  Timer? _geocodeDebounce;
  DateTime _calendarMonth = DateTime.now();

  // Time Slot Configuration
  final int _startHour = 6;
  final int _endHour = 20;
  final List<int> _selectedSlots = [];
  int? _selectedStartHour;
  int _durationHours = 1;

  void _addHour() {
    if (_selectedSlots.isEmpty) return;
    int lastHour = _selectedSlots.last;
    for (int h = lastHour + 1; h < _endHour; h++) {
      if (!_isSlotBlocked(h)) {
        setState(() {
          _selectedSlots.add(h);
          _selectedSlots.sort();
          _selectedStartHour = _selectedSlots.first;
          _durationHours = _selectedSlots.length;
        });
        break;
      }
    }
  }

  void _removeHour() {
    if (_selectedSlots.isEmpty) return;
    setState(() {
      _selectedSlots.removeLast();
      if (_selectedSlots.isNotEmpty) {
        _selectedStartHour = _selectedSlots.first;
        _durationHours = _selectedSlots.length;
      } else {
        _selectedStartHour = null;
        _durationHours = 1;
      }
    });
  }

  bool _canAddMoreHours() {
    if (_selectedSlots.isEmpty) return false;
    int lastHour = _selectedSlots.last;
    for (int h = lastHour + 1; h < _endHour; h++) {
      if (!_isSlotBlocked(h)) return true;
    }
    return false;
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

  bool _isSlotBlockedForDate(DateTime date, int hour) {
    DateTime slotStart = DateTime(date.year, date.month, date.day, hour);
    DateTime slotEnd = slotStart.add(const Duration(hours: 1)); 

    // Block past time slots for today
    if (slotStart.isBefore(DateTime.now())) {
      return true;
    }

    for (var booking in _existingBookings) {
      if (booking.scheduledStartTime != null && booking.scheduledEndTime != null) {
        DateTime bStart = booking.scheduledStartTime!.toLocal();
        DateTime bEnd = booking.scheduledEndTime!.toLocal();
        
        Map<String, dynamic> notes = {};
        try { notes = jsonDecode(booking.notes ?? '{}'); } catch(_){}
        
        List<int> bookedHours = [];
        if (notes.containsKey('slots_list')) {
          try {
            bookedHours = (notes['slots_list'] as List<dynamic>).map((e) => int.parse(e.toString())).toList();
          } catch (_) {}
        }
        
        bool isOccupiedInThisSlot = false;
        if (bookedHours.isNotEmpty) {
          isOccupiedInThisSlot = bookedHours.contains(hour);
        } else {
          isOccupiedInThisSlot = slotStart.isBefore(bEnd) && slotEnd.isAfter(bStart);
        }
        
        if (isOccupiedInThisSlot) {
           final String status = booking.status?.toUpperCase() ?? '';
           if (status != 'CANCELLED' && status != 'REJECTED' && status != 'COMPLETED' && status != 'FINISHED') {
             return true;
           }
        }
      }
    }
    return false;
  }

  // Real Logic: Check if a slot is blocked
  bool _isSlotBlocked(int hour) {
    if (_selectedDate == null) return false;
    return _isSlotBlockedForDate(_selectedDate!, hour);
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
      if (_selectedSlots.contains(hour)) {
        _selectedSlots.remove(hour);
      } else {
        _selectedSlots.add(hour);
        _selectedSlots.sort();
      }
      if (_selectedSlots.isNotEmpty) {
        _selectedStartHour = _selectedSlots.first;
        _durationHours = _selectedSlots.length;
      } else {
        _selectedStartHour = null;
        _durationHours = 1;
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
    _quantityController.addListener(() {
      if (mounted) setState(() {});
    });
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
    _geocodeDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _addressController.text = prefs.getString('user_address') ?? '';
      _detectedLat = prefs.getDouble('user_latitude');
      _detectedLng = prefs.getDouble('user_longitude');
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
      
      // Use helper for cross-platform reverse geocoding
      final addressData = await LocationHelper.getAddressFromCoordinates(position.latitude, position.longitude);
      final String exactAddress = addressData['exactAddress']!;
      final String village = addressData['village']!;
      final String district = addressData['district']!;
      final String address = exactAddress.isNotEmpty ? exactAddress : "$village, $district";

      if (mounted) {
        setState(() {
          _addressController.text = address;
          _detectedLat = position.latitude;
          _detectedLng = position.longitude;
        });
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_address', address);
        await prefs.setDouble('user_latitude', position.latitude);
        await prefs.setDouble('user_longitude', position.longitude);
        
        if (_fieldErrors.containsKey('address')) setState(() => _fieldErrors.remove('address'));
      }
    } catch (e) {
      if (mounted) UiUtils.showCenteredToast(context, 'Could not fetch location. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _pasteFromClipboard(TextEditingController controller, String errorKey) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null && data.text!.isNotEmpty) {
        setState(() {
          controller.text = data.text!;
          if (_fieldErrors.containsKey(errorKey)) {
            _fieldErrors.remove(errorKey);
          }
        });
        _debounceGeocoding();
        UiUtils.showCenteredToast(context, 'Address pasted successfully');
      } else {
        UiUtils.showCenteredToast(context, 'Clipboard is empty or contains non-text content', isError: true);
      }
    } catch (e) {
      UiUtils.showCenteredToast(context, 'Failed to paste from clipboard', isError: true);
    }
  }

  Future<void> _useProfileAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final houseNo = prefs.getString('user_houseNo') ?? '';
    final street = prefs.getString('user_street') ?? '';
    final village = prefs.getString('user_village') ?? '';
    final district = prefs.getString('user_district') ?? '';
    final state = prefs.getString('user_state') ?? '';
    final country = prefs.getString('user_country') ?? '';
    final pincode = prefs.getString('user_pincode') ?? '';

    final parts = [houseNo, street, village, district, state, country, pincode]
        .where((part) => part.isNotEmpty)
        .join(', ');

    if (parts.isNotEmpty) {
      setState(() {
        _addressController.text = parts;
        if (_fieldErrors.containsKey('address')) {
          _fieldErrors.remove('address');
        }
      });
      _debounceGeocoding();
      UiUtils.showCenteredToast(context, 'Profile address loaded');
    } else {
      UiUtils.showCenteredToast(context, 'No profile address saved. Please update in profile page.', isError: true);
    }
  }

  void _debounceGeocoding() {
    if (_geocodeDebounce?.isActive ?? false) _geocodeDebounce!.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && _addressController.text.isNotEmpty) {
        _geocodeManualAddress();
      }
    });
  }

  Future<void> _geocodeManualAddress() async {
    if (_addressController.text.isEmpty) return;
    setState(() => _isGeocodingAddress = true);
    try {
      String address = _addressController.text.trim();
      double? lat, lng;
      
      // 1. Try mobile native geocoding first
      try {
        final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
        if (isMobile) {
          List<geo.Location> locations = await geo.locationFromAddress(address);
          if (locations.isNotEmpty) {
            lat = locations.first.latitude;
            lng = locations.first.longitude;
          }
        }
      } catch (e) {
        debugPrint("Native geocoding failed: $e");
      }

      // 2. Try Nominatim/Fallback geocoding
      if (lat == null || lng == null) {
        final coords = await GeocodingService.getCoordinates(address);
        if (coords != null) {
          lat = coords['latitude'];
          lng = coords['longitude'];
        }
      }

      if (lat != null && lng != null) {
        setState(() {
          _detectedLat = lat;
          _detectedLng = lng;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('user_latitude', lat);
        await prefs.setDouble('user_longitude', lng);
      } else {
        setState(() {
          _detectedLat = null;
          _detectedLng = null;
        });
      }
    } catch (e) {
      debugPrint("Geocoding failed: $e");
    } finally {
      if (mounted) setState(() => _isGeocodingAddress = false);
    }
  }

  Widget _buildCoordsBadge() {
    if (_isGeocodingAddress) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE8F5E9)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00AA55)),
            ),
            SizedBox(width: 10),
            Text(
              "Detecting coordinates...",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00AA55)),
            ),
          ],
        ),
      );
    }

    if (_detectedLat != null && _detectedLng != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFC8E6C9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.gps_fixed_rounded, size: 16, color: Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                "Coords Detected: ${_detectedLat!.toStringAsFixed(6)}, ${_detectedLng!.toStringAsFixed(6)}",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_rounded, size: 16, color: Colors.orange[800]),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              "No Coordinates Detected (Type address to resolve)",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange[800]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToField(GlobalKey key) {
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  double get _totalPrice {
    double unitPrice = 0.0;
    try {
      final clean = widget.priceInfo.replaceAll(RegExp(r'[^0-9.]'), '');
      unitPrice = double.tryParse(clean) ?? 0.0;
    } catch (_) {}

    if (unitPrice == 0.0) return 0.0;

    final l10n = AppLocalizations.of(context)!;
    bool isAcreBilled = widget.serviceName == 'Ploughing' || 
                        widget.serviceName == l10n.ploughing ||
                        widget.serviceName == 'Harvesting' || 
                        widget.serviceName == l10n.harvesting ||
                        widget.serviceName == 'Drone Spraying' ||
                        widget.serviceName == l10n.droneSpraying ||
                        widget.serviceName == 'Irrigation' ||
                        widget.serviceName == l10n.irrigation;

    if (isAcreBilled) {
      double acres = double.tryParse(_quantityController.text) ?? 0.0;
      return unitPrice * acres;
    } else {
      return unitPrice * _selectedSlots.length;
    }
  }

  bool _isDateBooked(DateTime date) {
    for (int hour = _startHour; hour < _endHour; hour++) {
      if (!_isSlotBlockedForDate(date, hour)) {
        return false;
      }
    }
    return true;
  }



  String _getMonthFullName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  List<DateTime?> _generateCalendarDays() {
    int year = _calendarMonth.year;
    int month = _calendarMonth.month;
    
    DateTime firstDayOfMonth = DateTime(year, month, 1);
    int startWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    
    int daysInMonth = DateTime(year, month + 1, 0).day;
    
    List<DateTime?> days = [];
    
    // Add empty spaces for leading days
    for (int i = 1; i < startWeekday; i++) {
      days.add(null);
    }
    
    // Add all the days of the month
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(year, month, i));
    }
    
    return days;
  }

  void _confirmBooking() async {
    bool isElectrician = widget.serviceName == 'Electricians' || 
                        widget.serviceName == AppTranslations.translate(context, 'electricians');
    bool isQtyValid = isElectrician 
      ? (_selectedPurpose != null && (_selectedPurpose != 'Others' || _customPurposeController.text.isNotEmpty)) &&
        (_selectedAssetType != null && (_selectedAssetType != 'Others' || _customAssetController.text.isNotEmpty))
      : _quantityController.text.isNotEmpty;

    bool hasValidPrice = _totalPrice > 0;

    if (_selectedDate != null && isQtyValid && _addressController.text.isNotEmpty && _selectedSlots.isNotEmpty && hasValidPrice) {
      setState(() {
        _isSubmitting = true;
      });
      // Save address for future use if it changed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_address', _addressController.text);

      // Format time slots by joining individual formatted slots
      String timeStr = _selectedSlots.map((hour) => _formatTimeRange(hour)).join(', ');

      final String? userId = prefs.getString('user_id');
      final String? userName = prefs.getString('user_name');

      final Map<String, dynamic> notesMap = {
        'Booked By': userName ?? 'Unknown User',
        'Provider': widget.providerName,
        'Service': widget.serviceName,
        'Location': _addressController.text,
        'Preferred Time': timeStr,
        'slots_list': _selectedSlots,
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
        totalAmount: _totalPrice,
        addressText: _addressController.text,
        locationLat: _detectedLat,
        locationLng: _detectedLng,
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
      if (_selectedDate != null && isQtyValid && _addressController.text.isNotEmpty && _selectedSlots.isNotEmpty && !hasValidPrice) {
        UiUtils.showCenteredToast(context, 'Total price cannot be zero. Cannot book without cost info.', isError: true);
        return;
      }
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
    final l10n = AppLocalizations.of(context)!;
    bool isElectrician = widget.serviceName == 'Electricians' || 
                        widget.serviceName == AppTranslations.translate(context, 'electricians');
    
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _addressController,
                    label: 'Mandatory for service',
                    hint: 'Enter full address...',
                    maxLines: 3,
                    errorKey: 'address',
                    icon: Icons.map_rounded,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.home_rounded, color: Color(0xFF00AA55)),
                          onPressed: _useProfileAddress,
                          tooltip: 'Use profile address',
                        ),
                        _isFetchingLocation
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00AA55))),
                            )
                          : IconButton(
                              icon: const Icon(Icons.my_location_rounded, color: Color(0xFF00AA55)),
                              tooltip: 'Use my current location',
                              onPressed: _fetchCurrentLocation,
                            ),
                      ],
                    ),
                    onChanged: (_) {
                      if (_fieldErrors.containsKey('address')) setState(() => _fieldErrors.remove('address'));
                      _debounceGeocoding();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCoordsBadge(),
                ],
              ),
            ),

            // Date & Time Selection Card
            _buildSectionCard(
              key: _dateSectionKey,
              title: 'Schedule Booking',
              icon: Icons.event_available_rounded,
              isError: _fieldErrors.containsKey('date') || _fieldErrors.containsKey('slots'),
              child: _isLoadingBookings
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Color(0xFF00AA55)),
                          const SizedBox(height: 16),
                          Text(
                            'Loading service schedule...',
                            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 12),
                  // Month navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF1B5E20)),
                        onPressed: _calendarMonth.year == DateTime.now().year && _calendarMonth.month == DateTime.now().month
                          ? null
                          : () {
                              setState(() {
                                _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1);
                              });
                            },
                      ),
                      Text(
                        "${_getMonthFullName(_calendarMonth.month)} ${_calendarMonth.year}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF1B5E20)),
                        onPressed: () {
                          setState(() {
                            _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Weekday labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                      return SizedBox(
                        width: 40,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500]),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Days grid
                  Builder(
                    builder: (context) {
                      final days = _generateCalendarDays();
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: days.length,
                        itemBuilder: (context, index) {
                          final date = days[index];
                          if (date == null) {
                            return const SizedBox();
                          }
                          
                          final bool isPast = date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
                          final bool isBooked = _isDateBooked(date);
                          final bool isSelected = _selectedDate != null &&
                              _selectedDate!.year == date.year &&
                              _selectedDate!.month == date.month &&
                              _selectedDate!.day == date.day;
                          final bool isToday = DateTime.now().year == date.year &&
                              DateTime.now().month == date.month &&
                              DateTime.now().day == date.day;
                              
                          if (isPast) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "${date.day}",
                                style: TextStyle(color: Colors.grey[300], fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          
                          if (isBooked) {
                            return Material(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () {
                                  UiUtils.showCenteredToast(
                                    context,
                                    'This date has already been booked by someone else. Please select a free date.',
                                    isError: true
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFFCDD2)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Text(
                                        "${date.day}",
                                        style: TextStyle(
                                          color: Colors.red[400],
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 4,
                                        child: Container(
                                          width: 4,
                                          height: 4,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                          
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected 
                                ? const Color(0xFF00AA55) 
                                : (isToday ? const Color(0xFFE8F5E9) : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                  ? const Color(0xFF00AA55) 
                                  : (isToday ? const Color(0xFF00AA55) : const Color(0xFFE8F5E9)),
                                width: isSelected || isToday ? 1.5 : 1.0,
                              ),
                              boxShadow: isSelected 
                                ? [BoxShadow(color: const Color(0xFF00AA55).withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))] 
                                : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedDate = date;
                                    _selectedSlots.clear();
                                    if (_fieldErrors.containsKey('date')) _fieldErrors.remove('date');
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    "${date.day}",
                                    style: TextStyle(
                                      color: isSelected 
                                        ? Colors.white 
                                        : (isToday ? const Color(0xFF1B5E20) : const Color(0xFF2C3E50)),
                                      fontSize: 14,
                                      fontWeight: isSelected || isToday ? FontWeight.w900 : FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }
                  ),

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.preferredTime,
                        key: _timeSectionKey,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)),
                      ),
                      if (_selectedSlots.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedSlots.clear();
                              _selectedStartHour = null;
                              _durationHours = 1;
                            });
                          },
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Clear All',
                            style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
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
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
                            ),
                          ),
                        );
                      },
                    ),

                    if (_selectedSlots.isNotEmpty) ...[
                      const SizedBox(height: 30),
                      const Text(
                        'Selected Slots Details',
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    _buildDurationControl(
                                      icon: Icons.remove_rounded,
                                      onPressed: _selectedSlots.length > 1 ? _removeHour : null,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        '${_selectedSlots.length} ${_selectedSlots.length == 1 ? 'Hour' : 'Hours'}',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
                                      ),
                                    ),
                                    _buildDurationControl(
                                      icon: Icons.add_rounded,
                                      onPressed: _canAddMoreHours() ? _addHour : null,
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
                                    '₹${_totalPrice.toStringAsFixed(0)} Est.',
                                    style: const TextStyle(color: Color(0xFF00AA55), fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedSlots.map((hour) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFC8E6C9)),
                                ),
                                child: Text(
                                  _formatTimeRange(hour),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                                ),
                              )).toList(),
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
          isExpanded: true,
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
