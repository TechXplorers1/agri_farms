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
import '../utils/translated_text.dart';
import '../services/geocoding_service.dart';
import '../data/ploughing_data.dart';
import '../data/harvesting_data.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:async';


class BookServiceDetailScreen extends StatefulWidget {
  final String providerName;
  final String serviceName;
  final String providerId;
  final String assetId;
  final String priceInfo;
  final String? ownerProfileImage;
  final String? description;
  final String? serialNumber;
  final String? equipmentName;
  final bool? operatorIncluded;

  const BookServiceDetailScreen({
    super.key,
    required this.providerName,
    required this.serviceName,
    required this.providerId,
    required this.assetId,
    required this.priceInfo,
    this.ownerProfileImage,
    this.description,
    this.serialNumber,
    this.equipmentName,
    this.operatorIncluded,
  });

  @override
  State<BookServiceDetailScreen> createState() => _BookServiceDetailScreenState();
}

class _BookServiceDetailScreenState extends State<BookServiceDetailScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _mandalController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(text: 'India');
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, String?> _fieldErrors = {};
  
  // GlobalKeys for scrolling
  final GlobalKey _qtySectionKey = GlobalKey();
  final GlobalKey _addressSectionKey = GlobalKey();
  final GlobalKey _dateSectionKey = GlobalKey();
  final GlobalKey _timeSectionKey = GlobalKey();
  final GlobalKey _notesSectionKey = GlobalKey();
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

  // Vet Care Specific Fields
  final List<String> _vetAnimalTypes = [
    'Cow',
    'Buffalo',
    'Sheep/Goat',
    'Poultry',
    'Dog/Cat',
    'Others'
  ];
  String? _selectedAnimalType;

  // Mechanic Specific Fields
  final List<String> _mechanicMachineryTypes = [
    'Tractor',
    'Harvester',
    'Rotavator/Cultivator',
    'Power Tiller',
    'Water Pump Engine',
    'Others'
  ];
  String? _selectedMachineryType;

  // Ploughing Specific Fields
  String? _selectedPloughEquipmentType;
  String? _selectedPloughCapacity;
  final TextEditingController _customPloughEquipmentTypeController = TextEditingController();
  final TextEditingController _customPloughCapacityController = TextEditingController();

  // Harvesting Specific Fields
  String? _selectedHarvestEquipmentType;
  String? _selectedHarvestCapacity;
  final TextEditingController _customHarvestEquipmentTypeController = TextEditingController();
  final TextEditingController _customHarvestCapacityController = TextEditingController();

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
    _houseNoController.dispose();
    _streetController.dispose();
    _villageController.dispose();
    _mandalController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();
    _quantityController.dispose();
    _customPurposeController.dispose();
    _customAssetController.dispose();
    _customPloughEquipmentTypeController.dispose();
    _customPloughCapacityController.dispose();
    _customHarvestEquipmentTypeController.dispose();
    _customHarvestCapacityController.dispose();
    _scrollController.dispose();
    _geocodeDebounce?.cancel();
    super.dispose();
  }

  void _clearAddressErrors() {
    _fieldErrors.remove('houseNo');
    _fieldErrors.remove('street');
    _fieldErrors.remove('village');
    _fieldErrors.remove('mandal');
    _fieldErrors.remove('district');
    _fieldErrors.remove('state');
    _fieldErrors.remove('pincode');
    _fieldErrors.remove('address');
  }

  String _buildFullAddress() {
    List<String> parts = [];
    if (_houseNoController.text.trim().isNotEmpty) parts.add(_houseNoController.text.trim());
    if (_streetController.text.trim().isNotEmpty) parts.add(_streetController.text.trim());
    if (_villageController.text.trim().isNotEmpty) parts.add(_villageController.text.trim());
    if (_mandalController.text.trim().isNotEmpty) parts.add(_mandalController.text.trim());
    if (_districtController.text.trim().isNotEmpty) parts.add(_districtController.text.trim());
    if (_stateController.text.trim().isNotEmpty) parts.add(_stateController.text.trim());
    if (_pincodeController.text.trim().isNotEmpty) parts.add(_pincodeController.text.trim());
    if (_countryController.text.trim().isNotEmpty) parts.add(_countryController.text.trim());
    return parts.join(', ');
  }

  Future<void> _loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _detectedLat = prefs.getDouble('user_latitude');
      _detectedLng = prefs.getDouble('user_longitude');
    });
    await _useProfileAddress();
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
      
      final addressData = await LocationHelper.getAddressFromCoordinates(position.latitude, position.longitude);
      final String village = addressData['village'] ?? '';
      final String district = addressData['district'] ?? '';
      final String fullAddr = addressData['address'] ?? '';

      if (mounted) {
        setState(() {
          _villageController.text = village;
          _districtController.text = district;
          if (fullAddr.isNotEmpty) {
            final parts = fullAddr.split(',').map((e) => e.trim()).toList();
            if (parts.length > 2) _streetController.text = parts[0];
            if (parts.isNotEmpty) {
              final lastPart = parts.last;
              if (RegExp(r'^\d{6}$').hasMatch(lastPart)) {
                _pincodeController.text = lastPart;
              }
            }
          }
          _detectedLat = position.latitude;
          _detectedLng = position.longitude;
          _clearAddressErrors();
        });
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_address', _buildFullAddress());
        await prefs.setDouble('user_latitude', position.latitude);
        await prefs.setDouble('user_longitude', position.longitude);
        UiUtils.showCenteredToast(context, 'Current location loaded');
      }
    } catch (e) {
      if (mounted) UiUtils.showCenteredToast(context, 'Could not fetch location. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
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
            _mandalController.text = parts[3];
            _districtController.text = parts[4];
            _stateController.text = parts[5];
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
          _clearAddressErrors();
        });
        _debounceGeocoding();
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
    final mandal = prefs.getString('user_mandal') ?? '';
    final district = prefs.getString('user_district') ?? '';
    final state = prefs.getString('user_state') ?? '';
    final country = prefs.getString('user_country') ?? 'India';
    final pincode = prefs.getString('user_pincode') ?? '';

    if (houseNo.isNotEmpty || street.isNotEmpty || village.isNotEmpty || district.isNotEmpty || state.isNotEmpty || pincode.isNotEmpty) {
      setState(() {
        _houseNoController.text = houseNo;
        _streetController.text = street;
        _villageController.text = village;
        _mandalController.text = mandal;
        _districtController.text = district;
        _stateController.text = state;
        _countryController.text = country;
        _pincodeController.text = pincode;
        _clearAddressErrors();
      });
      _debounceGeocoding();
      UiUtils.showCenteredToast(context, 'Profile address loaded');
    } else {
      final userAddress = prefs.getString('user_address') ?? '';
      if (userAddress.isNotEmpty) {
        final parts = userAddress.split(',').map((e) => e.trim()).toList();
        setState(() {
          if (parts.length >= 7) {
            _houseNoController.text = parts[0];
            _streetController.text = parts[1];
            _villageController.text = parts[2];
            _mandalController.text = parts[3];
            _districtController.text = parts[4];
            _stateController.text = parts[5];
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
          _clearAddressErrors();
        });
        _debounceGeocoding();
        UiUtils.showCenteredToast(context, 'Profile address loaded');
      } else {
        UiUtils.showCenteredToast(context, 'No profile address saved. Please update in profile page.', isError: true);
      }
    }
  }

  void _debounceGeocoding() {
    if (_geocodeDebounce?.isActive ?? false) _geocodeDebounce!.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && _buildFullAddress().isNotEmpty) {
        _geocodeManualAddress();
      }
    });
  }

  Future<void> _geocodeManualAddress() async {
    final String address = _buildFullAddress().trim();
    if (address.isEmpty) return;
    setState(() => _isGeocodingAddress = true);
    try {
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
    final serviceLower = widget.serviceName.toLowerCase();
    bool isElectrician = serviceLower.contains('electrician');
    bool isVetCare = serviceLower.contains('vet') || serviceLower.contains('animal') || serviceLower.contains('paw') || serviceLower.contains('pet');
    bool isMechanic = serviceLower.contains('mechanic');
    bool isSoilTesting = serviceLower.contains('soil') || serviceLower.contains('test');
    bool isPloughing = serviceLower.contains('plough') || serviceLower.contains('plow');
    bool isHarvesting = serviceLower.contains('harvest');

    bool isQtyValid = false;
    if (isElectrician) {
      isQtyValid = (_selectedPurpose != null && (_selectedPurpose != 'Others' || _customPurposeController.text.isNotEmpty)) &&
                   (_selectedAssetType != null && (_selectedAssetType != 'Others' || _customAssetController.text.isNotEmpty));
    } else if (isVetCare) {
      isQtyValid = _selectedAnimalType != null && _quantityController.text.isNotEmpty;
    } else if (isMechanic) {
      isQtyValid = _selectedMachineryType != null && _quantityController.text.isNotEmpty;
    } else {
      isQtyValid = _quantityController.text.isNotEmpty;
    }

    bool addressValid = true;
    if (_houseNoController.text.trim().isEmpty) { _fieldErrors['houseNo'] = 'Required'; addressValid = false; }
    if (_streetController.text.trim().isEmpty) { _fieldErrors['street'] = 'Required'; addressValid = false; }
    if (_villageController.text.trim().isEmpty) { _fieldErrors['village'] = 'Required'; addressValid = false; }
    if (_mandalController.text.trim().isEmpty) { _fieldErrors['mandal'] = 'Required'; addressValid = false; }
    if (_districtController.text.trim().isEmpty) { _fieldErrors['district'] = 'Required'; addressValid = false; }
    if (_stateController.text.trim().isEmpty) { _fieldErrors['state'] = 'Required'; addressValid = false; }
    if (_pincodeController.text.trim().isEmpty) { _fieldErrors['pincode'] = 'Required'; addressValid = false; }
    final String fullAddress = _buildFullAddress();

    if (_selectedDate != null && isQtyValid && addressValid && _selectedSlots.isNotEmpty) {
      setState(() {
        _isSubmitting = true;
      });
      // Save address for future use if it changed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_houseNo', _houseNoController.text);
      await prefs.setString('user_street', _streetController.text);
      await prefs.setString('user_village', _villageController.text);
      await prefs.setString('user_mandal', _mandalController.text);
      await prefs.setString('user_district', _districtController.text);
      await prefs.setString('user_state', _stateController.text);
      await prefs.setString('user_pincode', _pincodeController.text);
      await prefs.setString('user_address', fullAddress);

      // Format time slots by joining individual formatted slots
      String timeStr = _selectedSlots.map((hour) => _formatTimeRange(hour)).join(', ');

      final String? userId = prefs.getString('user_id');
      final String? userName = prefs.getString('user_name');

      final Map<String, dynamic> notesMap = {
        'Booked By': userName ?? 'Unknown User',
        'Provider': widget.providerName,
        'Service': (widget.equipmentName != null && widget.equipmentName!.isNotEmpty) 
            ? '${widget.serviceName} - ${widget.equipmentName}' 
            : widget.serviceName,
        'Location': fullAddress,
        'Preferred Time': timeStr,
        'slots_list': _selectedSlots,
        'Notes': _notesController.text,
      };

      if (isElectrician) {
        notesMap['Purpose of Visit'] = _selectedPurpose == 'Others' ? _customPurposeController.text : _selectedPurpose;
        notesMap['Asset to Repair'] = _selectedAssetType == 'Others' ? _customAssetController.text : _selectedAssetType;
      } else if (isVetCare) {
        notesMap['Animal Type'] = _selectedAnimalType;
        notesMap['Number of Animals'] = _quantityController.text;
      } else if (isMechanic) {
        notesMap['Machinery Type'] = _selectedMachineryType;
        notesMap['Model/Brand'] = _quantityController.text;
      } else if (isSoilTesting) {
        notesMap['Number of Samples'] = _quantityController.text;
      } else {
        notesMap['Number of Acres'] = _quantityController.text;
      }

      if (isPloughing) {
        if (_selectedPloughEquipmentType != null) {
          notesMap['Ploughing Equipment Type'] = (_selectedPloughEquipmentType == 'Others' && _customPloughEquipmentTypeController.text.isNotEmpty)
              ? _customPloughEquipmentTypeController.text
              : _selectedPloughEquipmentType;
        }
        if (_selectedPloughCapacity != null) {
          notesMap['Equipment Capacity'] = (_selectedPloughCapacity == 'Custom / Other Capacity' && _customPloughCapacityController.text.isNotEmpty)
              ? _customPloughCapacityController.text
              : _selectedPloughCapacity;
        }
      } else if (isHarvesting) {
        if (_selectedHarvestEquipmentType != null) {
          notesMap['Harvesting Equipment Type'] = (_selectedHarvestEquipmentType == 'Others' && _customHarvestEquipmentTypeController.text.isNotEmpty)
              ? _customHarvestEquipmentTypeController.text
              : _selectedHarvestEquipmentType;
        }
        if (_selectedHarvestCapacity != null) {
          notesMap['Equipment Capacity'] = (_selectedHarvestCapacity == 'Custom / Other Specification' && _customHarvestCapacityController.text.isNotEmpty)
              ? _customHarvestCapacityController.text
              : _selectedHarvestCapacity;
        }
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
        addressText: fullAddress,
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

        Navigator.pushReplacement(
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
        } else if (isVetCare) {
          if (_selectedAnimalType == null) _fieldErrors['purpose'] = 'Please select animal type';
          if (_quantityController.text.isEmpty) _fieldErrors['qty'] = 'Please enter number of animals';
        } else if (isMechanic) {
          if (_selectedMachineryType == null) _fieldErrors['purpose'] = 'Please select machinery type';
          if (_quantityController.text.isEmpty) _fieldErrors['qty'] = 'Please enter model or brand name';
        } else if (isSoilTesting) {
          if (_quantityController.text.isEmpty) _fieldErrors['qty'] = 'Please enter number of soil samples';
        } else {
          if (_quantityController.text.isEmpty) {
            _fieldErrors['qty'] = 'Please enter number of acres';
          }
        }
        
        if (_houseNoController.text.trim().isEmpty) _fieldErrors['houseNo'] = 'Required';
        if (_streetController.text.trim().isEmpty) _fieldErrors['street'] = 'Required';
        if (_villageController.text.trim().isEmpty) _fieldErrors['village'] = 'Required';
        if (_mandalController.text.trim().isEmpty) _fieldErrors['mandal'] = 'Required';
        if (_districtController.text.trim().isEmpty) _fieldErrors['district'] = 'Required';
        if (_stateController.text.trim().isEmpty) _fieldErrors['state'] = 'Required';
        if (_pincodeController.text.trim().isEmpty) _fieldErrors['pincode'] = 'Required';
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
      } else if (!addressValid) {
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
    final serviceLower = widget.serviceName.toLowerCase();
    bool isElectrician = serviceLower.contains('electrician');
    bool isVetCare = serviceLower.contains('vet') || serviceLower.contains('animal') || serviceLower.contains('paw') || serviceLower.contains('pet');
    bool isMechanic = serviceLower.contains('mechanic');
    bool isSoilTesting = serviceLower.contains('soil') || serviceLower.contains('test');
    bool isPloughing = serviceLower.contains('plough') || serviceLower.contains('plow');
    bool isHarvesting = serviceLower.contains('harvest');
    
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
            _buildListingDetailsCard(widget.description, widget.serialNumber, widget.equipmentName),
             const SizedBox(height: 24),

            // Requirement Details Card
            _buildSectionCard(
              key: _qtySectionKey,
              title: 'Requirement Details',
              icon: Icons.list_alt_rounded,
              isError: (_fieldErrors.containsKey('qty') || _fieldErrors.containsKey('purpose') || _fieldErrors.containsKey('asset')),
              child: isElectrician
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                    )
                  : isVetCare
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDropdownField(
                              label: 'Animal Type',
                              hint: 'Choose animal type',
                              value: _selectedAnimalType,
                              items: _vetAnimalTypes,
                              errorKey: 'purpose',
                              icon: Icons.pets_rounded,
                              onChanged: (val) => setState(() => _selectedAnimalType = val),
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _quantityController,
                              label: 'Number of Animals',
                              hint: 'e.g. 5 Animals',
                              keyboardType: TextInputType.number,
                              errorKey: 'qty',
                              icon: Icons.numbers_rounded,
                              onChanged: (_) {
                                if (_fieldErrors.containsKey('qty')) setState(() => _fieldErrors.remove('qty'));
                              },
                            ),
                          ],
                        )
                      : isMechanic
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDropdownField(
                                  label: 'Machinery / Vehicle Type',
                                  hint: 'Choose machinery type',
                                  value: _selectedMachineryType,
                                  items: _mechanicMachineryTypes,
                                  errorKey: 'purpose',
                                  icon: Icons.precision_manufacturing_rounded,
                                  onChanged: (val) => setState(() => _selectedMachineryType = val),
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  controller: _quantityController,
                                  label: 'Model / Brand Name',
                                  hint: 'e.g. Mahindra 575 DI',
                                  errorKey: 'qty',
                                  icon: Icons.branding_watermark_rounded,
                                  onChanged: (_) {
                                    if (_fieldErrors.containsKey('qty')) setState(() => _fieldErrors.remove('qty'));
                                  },
                                ),
                              ],
                            )
                          : isPloughing
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDropdownField(
                                      label: 'Ploughing Equipment Type',
                                      hint: 'Choose equipment type (e.g. MB, Rotavator)',
                                      value: _selectedPloughEquipmentType,
                                      items: PloughingData.equipmentTypes,
                                      errorKey: 'purpose',
                                      icon: Icons.agriculture_rounded,
                                      onChanged: (val) => setState(() {
                                        _selectedPloughEquipmentType = val;
                                        _selectedPloughCapacity = null;
                                      }),
                                    ),
                                    if (_selectedPloughEquipmentType == 'Others') ...[
                                      const SizedBox(height: 20),
                                      _buildTextField(
                                        controller: _customPloughEquipmentTypeController,
                                        label: 'Custom Equipment Type',
                                        hint: 'Specify equipment type...',
                                        errorKey: 'custom_eq',
                                        icon: Icons.edit_note_rounded,
                                      ),
                                    ],
                                    const SizedBox(height: 20),
                                    _buildDropdownField(
                                      label: 'Equipment Capacity / Specification',
                                      hint: 'Choose capacity (e.g. 3 Bottom, 42 Blades)',
                                      value: _selectedPloughCapacity,
                                      items: PloughingData.getCapacities(_selectedPloughEquipmentType),
                                      errorKey: 'asset',
                                      icon: Icons.straighten_rounded,
                                      onChanged: (val) => setState(() => _selectedPloughCapacity = val),
                                    ),
                                    if (_selectedPloughCapacity == 'Custom / Other Capacity') ...[
                                      const SizedBox(height: 20),
                                      _buildTextField(
                                        controller: _customPloughCapacityController,
                                        label: 'Custom Capacity / Specs',
                                        hint: 'e.g. 5 Bottom Heavy Duty / 75 HP',
                                        errorKey: 'custom_cap',
                                        icon: Icons.tune_rounded,
                                      ),
                                    ],
                                    const SizedBox(height: 20),
                                    _buildTextField(
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
                                  ],
                                )
                          : isHarvesting
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDropdownField(
                                      label: 'Harvesting Equipment Type',
                                      hint: 'Choose equipment type (e.g. Combine, Reaper)',
                                      value: _selectedHarvestEquipmentType,
                                      items: HarvestingData.equipmentTypes,
                                      errorKey: 'purpose',
                                      icon: Icons.agriculture_rounded,
                                      onChanged: (val) => setState(() {
                                        _selectedHarvestEquipmentType = val;
                                        _selectedHarvestCapacity = null;
                                      }),
                                    ),
                                    if (_selectedHarvestEquipmentType == 'Others') ...[
                                      const SizedBox(height: 20),
                                      _buildTextField(
                                        controller: _customHarvestEquipmentTypeController,
                                        label: 'Custom Equipment Type',
                                        hint: 'Specify equipment type...',
                                        errorKey: 'custom_eq',
                                        icon: Icons.edit_note_rounded,
                                      ),
                                    ],
                                    const SizedBox(height: 20),
                                    _buildDropdownField(
                                      label: 'Equipment Capacity / Specification',
                                      hint: 'Choose capacity (e.g. Track Type, 14 Ft Cutter)',
                                      value: _selectedHarvestCapacity,
                                      items: HarvestingData.getCapacities(_selectedHarvestEquipmentType),
                                      errorKey: 'asset',
                                      icon: Icons.straighten_rounded,
                                      onChanged: (val) => setState(() => _selectedHarvestCapacity = val),
                                    ),
                                    if (_selectedHarvestCapacity == 'Custom / Other Specification') ...[
                                      const SizedBox(height: 20),
                                      _buildTextField(
                                        controller: _customHarvestCapacityController,
                                        label: 'Custom Capacity / Specs',
                                        hint: 'e.g. Track Type 14 Feet Cutter Bar',
                                        errorKey: 'custom_cap',
                                        icon: Icons.tune_rounded,
                                      ),
                                    ],
                                    const SizedBox(height: 20),
                                    _buildTextField(
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
                                  ],
                                )
                          : _buildTextField(
                              controller: _quantityController,
                              label: isSoilTesting ? 'Number of Soil Samples' : 'Number of Acres',
                              hint: isSoilTesting ? 'e.g. 3 Samples' : 'e.g. 2 Acres',
                              keyboardType: TextInputType.number,
                              errorKey: 'qty',
                              icon: isSoilTesting ? Icons.science_outlined : Icons.landscape_rounded,
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
              isError: _fieldErrors.keys.any((k) => ['houseNo', 'street', 'village', 'mandal', 'district', 'state', 'pincode', 'address'].contains(k)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: TextButton.icon(
                          onPressed: _useProfileAddress,
                          icon: const Icon(Icons.home_rounded, size: 16, color: Color(0xFF00AA55)),
                          label: const Text('Profile Address', style: TextStyle(color: Color(0xFF00AA55), fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _isFetchingLocation
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00AA55))),
                            )
                          : TextButton.icon(
                              onPressed: _fetchCurrentLocation,
                              icon: const Icon(Icons.my_location_rounded, size: 16, color: Color(0xFF00AA55)),
                              label: const Text('Current Location', style: TextStyle(color: Color(0xFF00AA55), fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            ),
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
                  if (_fieldErrors.containsKey('date'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _fieldErrors['date']!,
                        style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
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
                    if (_fieldErrors.containsKey('slots'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _fieldErrors['slots']!,
                          style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
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
              TranslatedText(
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
        const SizedBox(height: 6),
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
        if (hasError && _fieldErrors[errorKey] != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 4),
            child: Text(
              _fieldErrors[errorKey]!,
              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
            ),
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
    final errorText = hasError ? _fieldErrors[errorKey] : null;

    return TranslationBuilder(
      texts: [label, hint, if (hasError && errorText != null) errorText else ''],
      builder: (context, translatedTexts) {
        final translatedLabel = translatedTexts[0];
        final translatedHint = translatedTexts[1];
        final translatedError = translatedTexts.length > 2 && translatedTexts[2].isNotEmpty ? translatedTexts[2] : errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translatedLabel,
              style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.w700, 
                color: hasError ? Colors.red : const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
              onChanged: (val) {
                if (onChanged != null) onChanged(val);
                if (_fieldErrors.containsKey(errorKey)) setState(() => _fieldErrors.remove(errorKey));
              },
              decoration: _inputDecoration(translatedHint, isError: hasError, icon: icon).copyWith(suffixIcon: suffixIcon),
            ),
            if (hasError && translatedError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6.0, left: 4),
                child: Text(
                  translatedError,
                  style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint, {bool isError = false, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: const Color(0xFF00AA55)) : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 0),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            description ?? 'High-quality agricultural service listing details.',
            style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600, height: 1.5),
          ),
        ],
      ),
    );
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
              _debounceGeocoding();
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
}
