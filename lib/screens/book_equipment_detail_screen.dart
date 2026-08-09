import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:agriculture/l10n/app_localizations.dart';
import '../utils/booking_manager.dart';
import '../utils/ui_utils.dart';
import 'booking_confirmation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/booking_dto.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/location_helper.dart';
import '../utils/translated_text.dart';
import '../services/geocoding_service.dart';

class BookEquipmentDetailScreen extends StatefulWidget {
  final String providerName;
  final String equipmentType;
  final String providerId;
  final String assetId;
  final double rate; // Rate per hour or day
  final double? pricePerHalfDay; // For Trolleys
  final double? operatorPrice;
  final bool operatorAvailable;
  final String? ownerProfileImage;
  final String? description;
  final String? serialNumber;
  final List<String>? attachedEquipments;

  const BookEquipmentDetailScreen({
    super.key,
    required this.providerName,
    required this.equipmentType,
    required this.providerId,
    required this.assetId,
    required this.rate,
    this.pricePerHalfDay,
    this.operatorPrice,
    this.operatorAvailable = true,
    this.ownerProfileImage,
    this.description,
    this.serialNumber,
    this.attachedEquipments,
  });

  @override
  State<BookEquipmentDetailScreen> createState() => _BookEquipmentDetailScreenState();
}

class _BookEquipmentDetailScreenState extends State<BookEquipmentDetailScreen> {
  final int _equipmentCount = 1;
  final int _startHour = 6;
  final int _endHour = 20;
  int? _selectedStartHour;
  int _durationHours = 1;
  bool _includeOperator = false;
  bool _isTrolleyHalfDay = false; // Added for Equipment Trolley Mode
  DateTime? _selectedDate;

  // Address Controllers
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _mandalController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(text: 'India');
  final TextEditingController _pincodeController = TextEditingController();
  double? _detectedLat;
  double? _detectedLng;
  bool _isGeocodingAddress = false;

  final TextEditingController _notesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, String?> _fieldErrors = {};
  
  // GlobalKeys for scrolling
  final GlobalKey _addressSectionKey = GlobalKey();
  final GlobalKey _dateSectionKey = GlobalKey();
  final GlobalKey _timeSectionKey = GlobalKey();

  List<String> _selectedEquipments = [];
  List<String> _displaySprayerTypes = [];

  List<BookingDTO> _existingBookings = [];
  bool _isLoadingBookings = false;
  bool _isSubmitting = false;
  bool _isFetchingLocation = false;

  final List<int> _selectedSlots = [];

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

  @override
  void initState() {
    super.initState();
    _includeOperator = widget.operatorAvailable;
    _loadAddress();
    _fetchAssetBookings();
    
    if (widget.equipmentType.contains('Sprayer') && widget.attachedEquipments != null) {
      for (var eq in widget.attachedEquipments!) {
        String typeName = eq.trim();
        final match = RegExp(r'\(Capacities:(.*?)\)').firstMatch(typeName);
        if (match != null) {
           typeName = typeName.split('(Capacities:').first.trim();
           if (match.group(1) != null) {
              final caps = match.group(1)!.split(',').map((e) => e.replaceAll('L', '').trim()).where((e) => e.isNotEmpty).toList();
              for (var cap in caps) {
                 _displaySprayerTypes.add('$typeName - $cap L');
              }
           }
        } else {
           _displaySprayerTypes.add(typeName);
        }
      }
    }
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
      _houseNoController.text = prefs.getString('user_houseNo') ?? '';
      _streetController.text = prefs.getString('user_street') ?? '';
      _villageController.text = prefs.getString('user_village') ?? '';
      _mandalController.text = prefs.getString('user_mandal') ?? '';
      _districtController.text = prefs.getString('user_district') ?? '';
      _stateController.text = prefs.getString('user_state') ?? '';
      _countryController.text = prefs.getString('user_country') ?? 'India';
      _pincodeController.text = prefs.getString('user_pincode') ?? '';
      _detectedLat = prefs.getDouble('user_latitude');
      _detectedLng = prefs.getDouble('user_longitude');
    });
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }
      
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      setState(() {
        _detectedLat = position.latitude;
        _detectedLng = position.longitude;
      });

      String? houseNo;
      String? street;
      String? village;
      String? district;
      String? state;
      String? country;
      String? pincode;
      String? exactAddress;

      // 1. Try cross-platform geocoding (nominatim)
      try {
        final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json');
        final responseData = await http.get(url, headers: {'User-Agent': 'AgriFarmsApp/1.0'});
        final response = json.decode(responseData.body);
        if (response != null && response['address'] != null) {
          final addr = response['address'];
          houseNo = addr['house_number'];
          street = addr['road'] ?? addr['suburb'] ?? addr['neighbourhood'];
          village = addr['suburb'] ?? addr['village'] ?? addr['neighbourhood'] ?? addr['city_district'];
          district = addr['district'] ?? addr['city'] ?? addr['county'];
          state = addr['state'];
          pincode = addr['postcode'];
          country = addr['country'];
          exactAddress = response['display_name'];
        }
      } catch (e) {
        debugPrint("Reverse geocoding failed: $e");
      }

      // 2. Fallback to mobile-specific safely
      final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
      if (isMobile) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks.first;
            houseNo ??= place.subThoroughfare;
            street ??= place.thoroughfare ?? place.subLocality;
            village ??= place.subLocality ?? place.locality;
            district ??= place.subAdministrativeArea ?? place.administrativeArea;
            state ??= place.administrativeArea;
            pincode ??= place.postalCode;
            country ??= place.country;
            
            if (exactAddress == null) {
              exactAddress = [
                place.street,
                place.subLocality,
                place.locality,
                place.subAdministrativeArea,
                place.administrativeArea,
                place.postalCode,
                place.country
              ].where((part) => part != null && part.isNotEmpty).join(', ');
            }
          }
        } catch (e) {}
      }

      village ??= 'Unknown Village';
      district ??= 'District';
      exactAddress ??= '$village, $district';

      if (mounted) {
        setState(() {
          _houseNoController.text = houseNo ?? '';
          _streetController.text = street ?? '';
          _villageController.text = village ?? '';
          _districtController.text = district ?? '';
          _stateController.text = state ?? '';
          _countryController.text = country ?? '';
          _pincodeController.text = pincode ?? '';
        });
        
        UiUtils.showCenteredToast(
          context, 
          'Location detected: $exactAddress\nCoords: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'
        );
        if (_fieldErrors.containsKey('address')) setState(() => _fieldErrors.remove('address'));
      }
    } catch (e) {
      if (mounted) UiUtils.showCenteredToast(context, 'Could not fetch location: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _geocodeManualAddress() async {
    if (_houseNoController.text.isEmpty &&
        _streetController.text.isEmpty &&
        _villageController.text.isEmpty &&
        _districtController.text.isEmpty &&
        _stateController.text.isEmpty &&
        _pincodeController.text.isEmpty) {
      UiUtils.showCenteredToast(context, 'Please enter address details first.', isError: true);
      return;
    }

    setState(() => _isGeocodingAddress = true);
    try {
      String fullAddress = "${_houseNoController.text}, ${_streetController.text}, ${_villageController.text}, ${_districtController.text}, ${_stateController.text}, ${_countryController.text}, ${_pincodeController.text}";
      
      double? lat, lng;
      // 1. Try mobile native geocoding first safely
      try {
        final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
        if (isMobile) {
          List<Location> locations = await locationFromAddress(fullAddress);
          if (locations.isNotEmpty) {
            lat = locations.first.latitude;
            lng = locations.first.longitude;
          }
        }
      } catch (e) {
        debugPrint("Native geocoding failed: $e");
      }

      // 2. Try Nominatim/Fallback geocoding (Works on Web!)
      if (lat == null || lng == null) {
        String fallbackAddress = "${_villageController.text}, ${_districtController.text}, ${_stateController.text}, ${_countryController.text}";
        final coords = await GeocodingService.getCoordinates(fullAddress, fallbackAddress: fallbackAddress);
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
        if (mounted) {
          UiUtils.showCenteredToast(
            context, 
            'Coordinates resolved successfully!\nCoords: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'
          );
        }
      } else {
        throw Exception("Could not find coordinates for the entered address.");
      }
    } catch (e) {
      if (mounted) {
        UiUtils.showCustomAlert(context, 'Geocoding failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isGeocodingAddress = false);
    }
  }

  Future<void> _pasteAddressFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null && data.text!.isNotEmpty) {
        final addressText = data.text!;
        final parts = addressText.split(',').map((e) => e.trim()).toList();
        
        setState(() {
          if (parts.length >= 7) {
            _houseNoController.text = parts[0];
            _streetController.text = parts[1];
            _villageController.text = parts[2];
            _districtController.text = parts[3];
            _stateController.text = parts[4];
            _countryController.text = parts[5];
            _pincodeController.text = parts[6];
          } else if (parts.length == 6) {
            _houseNoController.text = parts[0];
            _streetController.text = parts[1];
            _villageController.text = parts[2];
            _districtController.text = parts[3];
            _stateController.text = parts[4];
            _pincodeController.text = parts[5];
          } else if (parts.length == 5) {
            _houseNoController.text = '';
            _streetController.text = parts[0];
            _villageController.text = parts[1];
            _districtController.text = parts[2];
            _stateController.text = parts[3];
            _pincodeController.text = parts[4];
          } else if (parts.length == 4) {
            _houseNoController.text = '';
            _streetController.text = '';
            _villageController.text = parts[0];
            _districtController.text = parts[1];
            _stateController.text = parts[2];
            _pincodeController.text = parts[3];
          } else {
            _houseNoController.text = '';
            _streetController.text = '';
            _villageController.text = parts[0];
            if (parts.length > 1) _districtController.text = parts[1];
            if (parts.length > 2) _stateController.text = parts[2];
          }
          if (_fieldErrors.containsKey('address')) {
            _fieldErrors.remove('address');
          }
        });
        UiUtils.showCenteredToast(context, 'Address pasted and filled successfully');
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
    final country = prefs.getString('user_country') ?? 'India';
    final pincode = prefs.getString('user_pincode') ?? '';

    if (houseNo.isNotEmpty || street.isNotEmpty || village.isNotEmpty || district.isNotEmpty || state.isNotEmpty || pincode.isNotEmpty) {
      setState(() {
        _houseNoController.text = houseNo;
        _streetController.text = street;
        _villageController.text = village;
        _districtController.text = district;
        _stateController.text = state;
        _countryController.text = country;
        _pincodeController.text = pincode;
        if (_fieldErrors.containsKey('address')) {
          _fieldErrors.remove('address');
        }
      });
      UiUtils.showCenteredToast(context, 'Profile address loaded');
    } else {
      UiUtils.showCenteredToast(context, 'No profile address saved. Please update in profile page.', isError: true);
    }
  }

  @override
  void dispose() {
    _houseNoController.dispose();
    _streetController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();
    _notesController.dispose();
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

  double get _totalPrice {
    if (widget.equipmentType.contains('Trolley')) {
      double base = _isTrolleyHalfDay ? (widget.pricePerHalfDay ?? 0.0) : widget.rate;
      double opPrice = widget.operatorPrice ?? 200.0;
      double operatorCost = _includeOperator ? opPrice : 0; 
      return (base + operatorCost) * _equipmentCount;
    }

    if (_selectedSlots.isEmpty) return 0;

    double hours = _selectedSlots.length.toDouble();
    double opPrice = widget.operatorPrice ?? 200.0;
    double operatorCost = _includeOperator ? (opPrice * hours) : 0;
    return ((widget.rate * hours) + operatorCost) * _equipmentCount;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00AA55), // Equipment Theme Green
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
        _selectedSlots.clear();
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
        bool isSameDay = bStart.year == slotStart.year &&
                         bStart.month == slotStart.month &&
                         bStart.day == slotStart.day;
                         
        if (isSameDay) {
          if (bookedHours.isNotEmpty) {
            isOccupiedInThisSlot = bookedHours.contains(hour);
          } else {
            isOccupiedInThisSlot = slotStart.isBefore(bEnd) && slotEnd.isAfter(bStart);
          }
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
        if (hour != _selectedSlots.first && hour != _selectedSlots.last) {
           UiUtils.showCustomAlert(context, 'Cannot remove a middle slot. If you want to book a split time, you need to make a new booking.', isError: true);
           return;
        }
        _selectedSlots.remove(hour);
      } else {
        if (_selectedSlots.isNotEmpty) {
           _selectedSlots.sort();
           if (hour != _selectedSlots.first - 1 && hour != _selectedSlots.last + 1) {
              UiUtils.showCustomAlert(context, 'If you want to book a split time, you need to make a new booking.', isError: true);
              return;
           }
        }
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

  bool _isRangeAvailable(int startHour, int duration) {
    for (int i = 0; i < duration; i++) {
      if (_isSlotBlocked(startHour + i) || (startHour + i) >= _endHour) {
        return false;
      }
    }
    return true;
  }

  void _confirmBooking() async {
    setState(() {
      _fieldErrors.clear();
    });
    bool hasError = false;

    if (_houseNoController.text.isEmpty) { _fieldErrors['houseNo'] = 'Required'; hasError = true; }
    if (_streetController.text.isEmpty) { _fieldErrors['street'] = 'Required'; hasError = true; }
    if (_villageController.text.isEmpty) { _fieldErrors['village'] = 'Required'; hasError = true; }
    if (_mandalController.text.isEmpty) { _fieldErrors['mandal'] = 'Required'; hasError = true; }
    if (_districtController.text.isEmpty) { _fieldErrors['district'] = 'Required'; hasError = true; }
    if (_stateController.text.isEmpty) { _fieldErrors['state'] = 'Required'; hasError = true; }
    if (_pincodeController.text.isEmpty) { _fieldErrors['pincode'] = 'Required'; hasError = true; }

    if (_selectedDate == null) { _fieldErrors['date'] = 'Required'; hasError = true; }
    
    final bool isDailyTrolley = widget.equipmentType.contains('Trolley') && !_isTrolleyHalfDay;
    if (_selectedSlots.isEmpty && !isDailyTrolley) { _fieldErrors['slots'] = 'Required'; hasError = true; }

    if (widget.equipmentType.contains('Sprayer') && _selectedEquipments.isEmpty) {
      _fieldErrors['sprayerTypes'] = 'Required';
      hasError = true;
      UiUtils.showCenteredToast(context, 'Please select at least one sprayer type', isError: true);
    }
    
    if (widget.equipmentType.contains('Trolley') && _selectedEquipments.isEmpty && widget.attachedEquipments != null && widget.attachedEquipments!.isNotEmpty) {
      _fieldErrors['trolleyTypes'] = 'Required';
      hasError = true;
      UiUtils.showCenteredToast(context, 'Please select a trolley type', isError: true);
    }

    if (hasError) {
      if ((!widget.equipmentType.contains('Sprayer') && !widget.equipmentType.contains('Trolley')) || _selectedEquipments.isNotEmpty) {
        UiUtils.showCenteredToast(context, 'Please fill all required fields', isError: true);
      }
      return;
    }
    
    if (_totalPrice <= 0) {
       UiUtils.showCenteredToast(context, 'Invalid pricing (0 amount). Cannot proceed with booking.', isError: true);
       return;
    }

    final String fullAddress = [
      _houseNoController.text,
      _streetController.text,
      _villageController.text,
      _mandalController.text,
      _districtController.text,
      _stateController.text,
      _countryController.text,
      _pincodeController.text
    ].where((part) => part.isNotEmpty).join(', ');

    bool hasValidPrice = _totalPrice > 0;

    if ((_selectedSlots.isNotEmpty || isDailyTrolley) && _selectedDate != null && fullAddress.isNotEmpty && hasValidPrice) {
      setState(() {
        _isSubmitting = true;
      });
      // Save address in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_address', fullAddress);
      await prefs.setString('user_houseNo', _houseNoController.text);
      await prefs.setString('user_street', _streetController.text);
      await prefs.setString('user_village', _villageController.text);
      await prefs.setString('user_district', _districtController.text);
      await prefs.setString('user_state', _stateController.text);
      await prefs.setString('user_country', _countryController.text);
      await prefs.setString('user_pincode', _pincodeController.text);
      if (_detectedLat != null) await prefs.setDouble('user_latitude', _detectedLat!);
      if (_detectedLng != null) await prefs.setDouble('user_longitude', _detectedLng!);

      // Format duration text
      String durationText;
      if (isDailyTrolley) {
        durationText = 'Full Day (9 AM - 6 PM)';
      } else if (_selectedSlots.length == 1) {
        durationText = '${_formatTime(_selectedSlots.first)} - ${_formatTime(_selectedSlots.first + 1)}';
      } else {
         durationText = '${_formatTime(_selectedSlots.first)} - ${_formatTime(_selectedSlots.last + 1)}';
      }

      final String? userId = prefs.getString('user_id');
      final String? userName = prefs.getString('user_name');

      final Map<String, dynamic> notesMap = {
        'Booked By': userName ?? 'Unknown User',
        'Provider': widget.providerName,
        'Equipment': widget.equipmentType,
        'Location': fullAddress,
        'Duration': durationText,
        'Operator Required': _includeOperator ? 'Yes' : 'No',
        'Attached Equipments': _selectedEquipments.isNotEmpty ? _selectedEquipments.join(', ') : 'None',
        'slots_list': _selectedSlots,
        'Notes': _notesController.text,
      };

      DateTime start = isDailyTrolley
          ? DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 9)
          : DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedSlots.first);
      DateTime end = isDailyTrolley
          ? DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 18)
          : DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedSlots.last + 1);

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
        addressText: fullAddress,
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
              bookingTitle: '${widget.equipmentType} Rental',
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
      if (_selectedSlots.isNotEmpty && _selectedDate != null && fullAddress.isNotEmpty && !hasValidPrice) {
        UiUtils.showCenteredToast(context, 'Total price cannot be zero. Cannot book without cost info.', isError: true);
        return;
      }
      setState(() {
        _fieldErrors.clear();
        if (_houseNoController.text.isEmpty) _fieldErrors['houseNo'] = 'Required';
        if (_streetController.text.isEmpty) _fieldErrors['street'] = 'Required';
        if (_villageController.text.isEmpty) _fieldErrors['village'] = 'Required';
        if (_mandalController.text.isEmpty) _fieldErrors['mandal'] = 'Required';
        if (_districtController.text.isEmpty) _fieldErrors['district'] = 'Required';
        if (_stateController.text.isEmpty) _fieldErrors['state'] = 'Required';
        if (_pincodeController.text.isEmpty) _fieldErrors['pincode'] = 'Required';
        if (_selectedDate == null) {
          _fieldErrors['date'] = 'Select a start date';
        }
        if (_selectedSlots.isEmpty) {
          _fieldErrors['slots'] = 'Select at least one time slot';
        }
      });

      // Scroll to first error
      final addressFields = ['houseNo', 'street', 'village', 'mandal', 'district', 'state', 'pincode'];
      if (addressFields.any((f) => _fieldErrors.containsKey(f))) {
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
        title: Text('${l10n.rentNow} ${widget.equipmentType}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1B5E20), fontSize: 18)),
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
                             ? const Icon(Icons.agriculture_rounded, color: Color(0xFF00AA55), size: 32)
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
                             '₹${widget.rate.toStringAsFixed(0)} / ${widget.equipmentType.contains('Sprayer') ? 'litre' : 'hr'}',
                             style: const TextStyle(color: Color(0xFF00AA55), fontSize: 12, fontWeight: FontWeight.w800),
                           ),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            _buildListingDetailsCard(widget.description, widget.serialNumber, widget.equipmentType),
            if (widget.equipmentType.contains('Trolley')) ...[
              const SizedBox(height: 24),
              _buildSectionCard(
                title: 'Pricing Mode',
                icon: Icons.payments_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select how you want to be billed:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isTrolleyHalfDay = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: !_isTrolleyHalfDay ? const Color(0xFF00AA55) : Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: !_isTrolleyHalfDay ? const Color(0xFF00AA55) : const Color(0xFFE8F5E9),
                                  width: 2,
                                ),
                                boxShadow: !_isTrolleyHalfDay
                                    ? [BoxShadow(color: const Color(0xFF00AA55).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Full Day\n(₹${widget.rate.toStringAsFixed(0)})',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !_isTrolleyHalfDay ? Colors.white : const Color(0xFF2C3E50),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isTrolleyHalfDay = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _isTrolleyHalfDay ? const Color(0xFF00AA55) : Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: _isTrolleyHalfDay ? const Color(0xFF00AA55) : const Color(0xFFE8F5E9),
                                  width: 2,
                                ),
                                boxShadow: _isTrolleyHalfDay
                                    ? [BoxShadow(color: const Color(0xFF00AA55).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Half Day\n(₹${(widget.pricePerHalfDay ?? 0.0).toStringAsFixed(0)})',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isTrolleyHalfDay ? Colors.white : const Color(0xFF2C3E50),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (widget.equipmentType.contains('Tractor') || widget.equipmentType.contains('Sprayer') || widget.equipmentType.contains('Trolley')) ...[
              const SizedBox(height: 24),
              _buildSectionCard(
              title: widget.equipmentType.contains('Sprayer') ? 'Sprayer Types' : (widget.equipmentType.contains('Trolley') ? 'Trolley Types' : 'Attached Equipments'),
              icon: widget.equipmentType.contains('Sprayer') ? Icons.water_drop_rounded : (widget.equipmentType.contains('Trolley') ? Icons.rv_hookup_rounded : Icons.agriculture_rounded),
              isError: (widget.equipmentType.contains('Sprayer') && _fieldErrors.containsKey('sprayerTypes')) || (widget.equipmentType.contains('Trolley') && _fieldErrors.containsKey('trolleyTypes')),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.attachedEquipments != null && widget.attachedEquipments!.isNotEmpty) ...[
                    Text(widget.equipmentType.contains('Sprayer') ? 'Select the sprayer types you need:' : (widget.equipmentType.contains('Trolley') ? 'Select the trolley type you need:' : 'Select the included equipments you need:'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: (widget.equipmentType.contains('Sprayer') ? _displaySprayerTypes : widget.attachedEquipments!).map((eq) {
                        final isSelected = _selectedEquipments.contains(eq);
                        return FilterChip(
                          label: Text(eq),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedEquipments.add(eq);
                              } else {
                                _selectedEquipments.remove(eq);
                              }
                            });
                          },
                          selectedColor: const Color(0xFFE8F5E9),
                          checkmarkColor: const Color(0xFF00AA55),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF1B5E20) : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF00AA55) : Colors.grey[300]!,
                            ),
                          ),
                          backgroundColor: Colors.white,
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    const Text('No attached equipments offered by this provider.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
                  ]
                ],
              ),
            ),
            ],
            const SizedBox(height: 24),
             // Location Section
            _buildSectionCard(
              key: _addressSectionKey,
              title: 'Lush Delivery Location',
              icon: Icons.location_on_rounded,
              isError: ['houseNo', 'street', 'village', 'mandal', 'district', 'state', 'pincode'].any((f) => _fieldErrors.containsKey(f)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'FARM ADDRESS DETAILS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF546E7A), letterSpacing: 1.0),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.home_rounded, color: Color(0xFF00AA55)),
                            tooltip: 'Use Profile Address',
                            onPressed: _useProfileAddress,
                          ),
                          _isFetchingLocation
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00AA55)))
                            : IconButton(
                                icon: const Icon(Icons.my_location_rounded, color: Color(0xFF00AA55)),
                                tooltip: 'Auto Detect GPS Location',
                                onPressed: _fetchCurrentLocation,
                              ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAddressInputField(
                          controller: _houseNoController,
                          label: 'House No / Door No',
                          hint: 'e.g. 123',
                          icon: Icons.home_outlined,
                          errorKey: 'houseNo',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAddressInputField(
                          controller: _streetController,
                          label: 'Street / Area Name',
                          hint: 'Street details...',
                          icon: Icons.add_road_rounded,
                          errorKey: 'street',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAddressInputField(
                          controller: _villageController,
                          label: 'Village / Suburb',
                          hint: 'Village name...',
                          icon: Icons.landscape_rounded,
                          errorKey: 'village',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAddressInputField(
                          controller: _mandalController,
                          label: 'Mandal',
                          hint: 'Mandal name...',
                          icon: Icons.map_rounded,
                          errorKey: 'mandal',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAddressInputField(
                          controller: _districtController,
                          label: 'District',
                          hint: 'District name...',
                          icon: Icons.location_city_rounded,
                          errorKey: 'district',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAddressInputField(
                          controller: _stateController,
                          label: 'State',
                          hint: 'State name...',
                          icon: Icons.map_outlined,
                          errorKey: 'state',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAddressInputField(
                          controller: _pincodeController,
                          label: 'Pincode',
                          hint: 'Pincode...',
                          icon: Icons.pin_drop_rounded,
                          keyboardType: TextInputType.number,
                          errorKey: 'pincode',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildAddressInputField(
                    controller: _countryController,
                    label: 'Country',
                    hint: 'India',
                    icon: Icons.public_rounded,
                    enabled: false,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (_detectedLat != null && _detectedLng != null)
                        Expanded(
                          child: Container(
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
                                    "Coords: ${_detectedLat!.toStringAsFixed(6)}, ${_detectedLng!.toStringAsFixed(6)}",
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: Container(
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
                                    "No Coordinates Set",
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange[800]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      _isGeocodingAddress
                        ? const SizedBox(width: 32, height: 32, child: Padding(padding: EdgeInsets.all(6), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00AA55))))
                        : ElevatedButton.icon(
                            onPressed: _geocodeManualAddress,
                            icon: const Icon(Icons.pin_drop_rounded, size: 16),
                            label: TranslatedText('Get Coordinates', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00AA55),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 0,
                            ),
                          ),
                    ],
                  ),
                ],
              ),
            ),

            // Schedule Section
            _buildSectionCard(
              key: _dateSectionKey,
              title: 'Rental Schedule',
              icon: Icons.calendar_today_rounded,
              isError: _fieldErrors.containsKey('date') || _fieldErrors.containsKey('slots'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText('Select Rental Date', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Start Time',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)),
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
                          child: TranslatedText(
                            'Clear All',
                            style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  if (_selectedDate == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TranslatedText('Select a date first to view availability', style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                    )
                  else if (widget.equipmentType.contains('Trolley') && !_isTrolleyHalfDay)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wb_sunny_rounded, color: Color(0xFF00AA55), size: 24),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Full Day selected. The vehicle will be booked for the entire day.',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    if (widget.equipmentType.contains('Trolley') && _isTrolleyHalfDay)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFFFFECB3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.wb_twilight_rounded, color: Color(0xFFFFA000), size: 24),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Half Day selected. Please select your preferred slots below.',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFFF8F00)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                  ],

                  if (_selectedSlots.isNotEmpty && !(widget.equipmentType.contains('Trolley') && !_isTrolleyHalfDay)) ...[
                    const SizedBox(height: 24),
                    TranslatedText('Selected Slots Details', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
                    const SizedBox(height: 12),
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
                                    child: TranslatedText(
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
              ),
            ),

            // Options Section
            _buildSectionCard(
              title: 'Rental Options',
              icon: Icons.checklist_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.operatorAvailable ? const Color(0xFFF9FBF9) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: widget.operatorAvailable ? null : Border.all(color: Colors.grey[300]!),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: TranslatedText('Include Operator', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: widget.operatorAvailable ? const Color(0xFF1B5E20) : Colors.grey[600])),
                      subtitle: widget.operatorAvailable
                          ? TranslatedText('+ ₹${(widget.operatorPrice ?? 200.0).toStringAsFixed(0)} / hr extra charge', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600))
                          : TranslatedText('Operator not provided by owner', style: TextStyle(fontSize: 12, color: Colors.orange[800], fontWeight: FontWeight.w700)),
                      value: _includeOperator, 
                      activeColor: const Color(0xFF00AA55),
                      onChanged: widget.operatorAvailable 
                          ? (val) => setState(() => _includeOperator = val)
                          : (val) {
                              UiUtils.showCenteredToast(context, 'Operator is not available from owner for this listing.', isError: true);
                            },
                    ),
                  ),
                  if (!widget.operatorAvailable)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE0B2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.orange[800], size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TranslatedText(
                              'Operator not available for this equipment. Machine can be rented without operator.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            _buildSectionCard(
              title: 'Additional Notes',
              icon: Icons.notes_rounded,
              child: _buildTextField(
                controller: _notesController,
                label: 'Notes',
                hint: 'Any special instructions for the owner...',
                maxLines: 2,
                errorKey: 'notes',
                icon: Icons.edit_note_rounded,
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
                      Text(widget.equipmentType.contains('Sprayer') ? 'Price (per litre)' : l10n.totalEstimate, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF546E7A))),
                      Text(
                        widget.equipmentType.contains('Sprayer') ? '₹${widget.rate.toStringAsFixed(0)}' : '₹${_totalPrice.toStringAsFixed(0)}',
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
                            l10n.rentNow,
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
                TranslatedText(
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
    return TranslationBuilder(
      texts: [label, hint],
      builder: (context, translatedTexts) {
        final translatedHint = translatedTexts[1];
        return TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: (_) { if (hasError) setState(() => _fieldErrors.remove(errorKey)); },
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF2C3E50)),
          decoration: InputDecoration(
            hintText: translatedHint,
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
 
  String _formatTime(int hour) {
      if (hour == 12) return '12 PM';
      if (hour > 12) return '${hour - 12} PM';
      return '$hour AM';
  }

  String _formatTimeRange(int hour) {
    return '${_formatTime(hour)} - ${_formatTime(hour + 1)}';
  }

  Widget _buildAddressInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    String? errorKey,
  }) {
    final bool hasError = errorKey != null && _fieldErrors.containsKey(errorKey);
    final String? errorText = hasError ? _fieldErrors[errorKey] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: hasError ? Colors.red : const Color(0xFF2C3E50)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF9FBF9) : Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: hasError ? Colors.red : (enabled ? const Color(0xFFE8F5E9) : Colors.grey[300]!)),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            onChanged: (_) {
              if (hasError && errorKey != null) {
                setState(() => _fieldErrors.remove(errorKey));
              }
            },
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: enabled ? const Color(0xFF2C3E50) : Colors.grey[700]),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500, fontSize: 13),
              prefixIcon: Icon(icon, color: hasError ? Colors.red : (enabled ? const Color(0xFF00AA55) : Colors.grey[500]), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        if (hasError && errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4),
            child: Text(errorText, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
      ],
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

  Widget _buildListingDetailsCard(String? description, String? number, String? equipmentName) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 14),
              const Text(
                'LISTING DETAILS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20), letterSpacing: -0.2),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (equipmentName != null && equipmentName.isNotEmpty) ...[
            Text(
              'EQUIPMENT NAME',
              style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
            const SizedBox(height: 4),
            Text(
              equipmentName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey[100], height: 1),
            const SizedBox(height: 16),
          ],
          if (number != null && number.trim().isNotEmpty) ...[
            Text(
              'SERIAL/REGISTRATION NUMBER',
              style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
            const SizedBox(height: 4),
            Text(
              number,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey[100], height: 1),
            const SizedBox(height: 16),
          ],
          Text(
            'DESCRIPTION',
            style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w800, letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          Text(
            description ?? 'High-quality agricultural listing details.',
            style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600, height: 1.5),
          ),
        ],
      ),
    );
  }
}

