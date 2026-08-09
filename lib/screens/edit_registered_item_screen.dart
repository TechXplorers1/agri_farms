import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:agriculture/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/location_helper.dart';
import 'dart:io' show File;
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../utils/ui_utils.dart';
import '../utils/translated_text.dart';
import '../data/harvesting_data.dart';

class EditRegisteredItemScreen extends StatefulWidget {
  final String category; // 'Vehicle', 'Equipment', 'Service', 'WorkerGroup'
  final Map<String, dynamic> itemData;

  const EditRegisteredItemScreen({
    Key? key,
    required this.category,
    required this.itemData,
  }) : super(key: key);

  @override
  State<EditRegisteredItemScreen> createState() =>
      _EditRegisteredItemScreenState();
}

class _EditRegisteredItemScreenState extends State<EditRegisteredItemScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _pricePerKmController;
  late TextEditingController _locationController;
  late TextEditingController _ownerBusinessNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _serviceAreaController;

  // Specifics
  late TextEditingController
  _secondaryController; // e.g., brandModel, type, groupName
  bool _boolFlag = false; // operatorAvailable, driverIncluded
  String? _condition; // Equipment
  late TextEditingController _capacityController; // Vehicle
  late TextEditingController _operatorPriceController;
  late TextEditingController _equipmentUsedController;
  late TextEditingController _houseNoController;
  late TextEditingController _streetController;
  late TextEditingController _villageController;
  late TextEditingController _mandalController;
  late TextEditingController _districtController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _pincodeController;
  Map<String, List<String>> _equipmentCapacityMap = {};
  String? _selectedEquipmentTypeForCap;
  late TextEditingController _capacityInputController;
  late TextEditingController _customEquipmentTypeController;
  bool _isFetchingLocation = false;

  // Vehicle type-specific
  String? _selectedVehicleType;
  String _selectedCapacityUnit = 'Ton';
  final List<String> _transportTypes = [
    'Mini Truck',
    'Tractor Trolley',
    'Truck',
    'Container',
  ];

  final List<String> _availableAttachedEquipments = [
    'Mouldboard Plow',
    'Disc Plow',
    'Chisel Plow',
    'Rotavator',
    'Disc Harrow',
    'Other',
  ];
  List<String> _selectedAttachedEquipments = [];
  final TextEditingController _otherAttachedEquipmentController =
      TextEditingController();

  final List<String> _defaultSprayerTypes = [
    'Handheld sprayers',
    'Knapsack (backpack) sprayers',
    'Foot and rocker sprayers',
    'Portable power/HTP sprayers',
    'Mist blowers/dusters',
    'Knapsack power sprayers',
    'Other',
  ];
  List<String> _availableSprayerTypes = [];
  String? _currentSelectedSprayerType;
  late TextEditingController _currentOtherSprayerTypeController;
  late TextEditingController _currentSprayerCapacityController;
  final Map<String, List<String>> _sprayerCapacitiesMap = {};

  XFile? _imageFile;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _pricePerKmController = TextEditingController();
    _locationController = TextEditingController(
      text: widget.itemData['location']?.toString() ?? '',
    );
    _secondaryController = TextEditingController();
    _capacityController = TextEditingController();
    _ownerBusinessNameController = TextEditingController(
      text: widget.itemData['ownerBusinessName']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.itemData['description']?.toString() ?? '',
    );
    _serviceAreaController = TextEditingController(
      text: widget.itemData['serviceArea']?.toString() ?? '',
    );
    _imageUrl = widget.itemData['imageUrl']?.toString();
    double opPriceVal = 0.0;
    if (widget.itemData['operatorPrice'] != null) {
      opPriceVal =
          (widget.itemData['operatorPrice'] as num?)?.toDouble() ??
          (double.tryParse(
                widget.itemData['operatorPrice'].toString().replaceAll(
                  RegExp(r'[^0-9.]'),
                  '',
                ),
              ) ??
              0.0);
    }
    _operatorPriceController = TextEditingController(
      text:
          opPriceVal > 0
              ? opPriceVal.toStringAsFixed(0)
              : (widget.itemData['operatorPrice']?.toString() ?? ''),
    );
    _equipmentUsedController = TextEditingController(
      text: widget.itemData['equipmentUsed']?.toString() ?? '',
    );
    _houseNoController = TextEditingController(
      text: widget.itemData['houseNo']?.toString() ?? '',
    );
    _streetController = TextEditingController(
      text: widget.itemData['street']?.toString() ?? '',
    );
    _villageController = TextEditingController(
      text: widget.itemData['village']?.toString() ?? '',
    );
    _mandalController = TextEditingController(
      text: widget.itemData['mandal']?.toString() ?? '',
    );
    _districtController = TextEditingController(
      text: widget.itemData['district']?.toString() ?? '',
    );
    _stateController = TextEditingController(
      text: widget.itemData['state']?.toString() ?? '',
    );
    _countryController = TextEditingController(
      text: widget.itemData['country']?.toString() ?? 'India',
    );
    _pincodeController = TextEditingController(
      text: widget.itemData['pincode']?.toString() ?? '',
    );
    _capacityInputController = TextEditingController();
    _customEquipmentTypeController = TextEditingController();

    String storedEquip =
        widget.itemData['equipmentUsed']?.toString() ??
        widget.itemData['brandModel']?.toString() ??
        '';
    if (storedEquip.isNotEmpty) {
      List<String> parts =
          storedEquip
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
      for (var item in parts) {
        if (item.contains(' - ')) {
          var splitVal = item.split(' - ');
          var type = splitVal[0].trim();
          var cap = splitVal[1].trim();
          if (_equipmentCapacityMap.containsKey(type)) {
            if (!_equipmentCapacityMap[type]!.contains(cap)) {
              _equipmentCapacityMap[type]!.add(cap);
            }
          } else {
            _equipmentCapacityMap[type] = [cap];
          }
        }
      }
    }

    if (widget.category == 'Vehicle') {
      _selectedVehicleType = widget.itemData['vehicleType']?.toString();
      _nameController.text = widget.itemData['vehicleNumber']?.toString() ?? '';
      _priceController.text =
          widget.itemData['pricePerKmOrTrip']?.toString() ?? '';
      _pricePerKmController.text =
          widget.itemData['pricePerKm']?.toString() ?? '';
      _secondaryController.text = _selectedVehicleType ?? '';

      // Parse capacity and unit from stored string e.g. "1.5 Ton" or "500 kg"
      final rawCap = widget.itemData['loadCapacity']?.toString() ?? '';
      if (rawCap.toLowerCase().contains('kg')) {
        _selectedCapacityUnit = 'kg';
        _capacityController.text =
            rawCap
                .toLowerCase()
                .replaceAll('kg', '')
                .replaceAll('kgs', '')
                .trim();
      } else {
        _selectedCapacityUnit = 'Ton';
        _capacityController.text =
            rawCap
                .toLowerCase()
                .replaceAll('tons', '')
                .replaceAll('ton', '')
                .trim();
      }
      _boolFlag = widget.itemData['driverIncluded'] ?? false;
    } else if (widget.category == 'Equipment') {
      _nameController.text = widget.itemData['brandModel']?.toString() ?? '';
      _priceController.text = widget.itemData['pricePerHour']?.toString() ?? '';
      _secondaryController.text = widget.itemData['category']?.toString() ?? '';
      _boolFlag = widget.itemData['operatorAvailable'] ?? false;
      _condition = widget.itemData['conditionStatus']?.toString() ?? 'Good';

      final attachedStr = widget.itemData['attachedEquipments']?.toString();

      if (_secondaryController.text == 'Sprayers') {
        _availableSprayerTypes = List.from(_defaultSprayerTypes);
        if (attachedStr != null && attachedStr.isNotEmpty) {
          dynamic attachedData = widget.itemData['attachedEquipments'];
          List<String> attachedList = [];
          if (attachedData is List) {
            attachedList = attachedData.map((e) => e.toString()).toList();
          } else if (attachedData is String) {
            String clean = attachedData.replaceAll(RegExp(r'^\[|\]$'), '');
            // Split by comma ignoring commas inside parentheses
            attachedList =
                clean
                    .split(RegExp(r',\s*(?![^()]*\))'))
                    .where((e) => e.isNotEmpty)
                    .toList();
          }

          for (var item in attachedList) {
            item = item.trim();
            String typeName = item;
            List<String> caps = [];
            final match = RegExp(r'\(Capacities:(.*?)\)').firstMatch(item);
            if (match != null) {
              typeName = item.split('(Capacities:').first.trim();
              if (match.group(1) != null) {
                // Remove 'L' and trim
                caps =
                    match
                        .group(1)!
                        .split(',')
                        .map((e) => e.replaceAll('L', '').trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
              }
            }
            if (caps.isNotEmpty) {
              _sprayerCapacitiesMap[typeName] = caps;
            } else {
              _sprayerCapacitiesMap[typeName] = [];
            }
            if (!_availableSprayerTypes.contains(typeName)) {
              _availableSprayerTypes.insert(
                _availableSprayerTypes.length - 1,
                typeName,
              );
            }
          }
        }
        _nameController.text = widget.itemData['brandModel']?.toString() ?? '';
        // Remove global capacity parsing logic
        if (attachedStr != null && attachedStr.isNotEmpty) {
          _selectedAttachedEquipments =
              attachedStr
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
        }
      }
    } else if (widget.category == 'Service') {
      _nameController.text = widget.itemData['businessName']?.toString() ?? '';
      _priceController.text = widget.itemData['priceRate']?.toString() ?? '';
      _secondaryController.text =
          widget.itemData['serviceType']?.toString() ?? '';
      _boolFlag = widget.itemData['operatorIncluded'] ?? true;
    } else if (widget.category == 'WorkerGroup') {
      _nameController.text = widget.itemData['groupName']?.toString() ?? '';
      _priceController.text = widget.itemData['pricePerMale']?.toString() ?? '';
      _secondaryController.text =
          widget.itemData['pricePerFemale']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _pricePerKmController.dispose();
    _locationController.dispose();
    _secondaryController.dispose();
    _capacityController.dispose();
    _ownerBusinessNameController.dispose();
    _descriptionController.dispose();
    _serviceAreaController.dispose();
    _operatorPriceController.dispose();
    _equipmentUsedController.dispose();
    _houseNoController.dispose();
    _streetController.dispose();
    _villageController.dispose();
    _mandalController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();
    _capacityInputController.dispose();
    _customEquipmentTypeController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        UiUtils.showCenteredToast(context, 'Location services are disabled.');
        setState(() => _isFetchingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          UiUtils.showCenteredToast(context, 'Location permissions are denied');
          setState(() => _isFetchingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        UiUtils.showCenteredToast(
          context,
          'Location permissions are permanently denied',
        );
        setState(() => _isFetchingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Use helper for cross-platform reverse geocoding
      final addressData = await LocationHelper.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final String village = addressData['village']!;
      final String district = addressData['district']!;
      final String exactAddress = addressData['exactAddress']!;

      if (mounted) {
        setState(() {
          _locationController.text = exactAddress;
          _villageController.text = village;
          _districtController.text = district;
        });

        UiUtils.showCenteredToast(
          context,
          'Location detected: $exactAddress\nCoords: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
        );
      }
    } catch (e) {
      UiUtils.showCenteredToast(context, 'Error fetching location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _submit() async {
    try {
      final updatedData = Map<String, dynamic>.from(widget.itemData);

      if (_imageFile != null) {
        final uploadResult = await _apiService.uploadImage(_imageFile!);
        updatedData['imageUrl'] = uploadResult['url'];
      }

      if (widget.category == 'Vehicle') {
        updatedData['vehicleType'] = _selectedVehicleType;
        updatedData['vehicleNumber'] = _nameController.text;
        // Store capacity with unit e.g. "1.5 Ton" or "500 kg"
        final capNum = _capacityController.text.trim();
        updatedData['loadCapacity'] =
            capNum.isNotEmpty ? '$capNum $_selectedCapacityUnit' : '';
        // Type-specific pricing
        if (_selectedVehicleType == 'Tractor Trolley') {
          updatedData['pricePerKmOrTrip'] =
              double.tryParse(_priceController.text) ?? 0.0;
          updatedData['pricePerKm'] =
              double.tryParse(_pricePerKmController.text) ?? 0.0;
        } else if (_selectedVehicleType == 'Mini Truck' ||
            _selectedVehicleType == 'Truck') {
          updatedData['pricePerKmOrTrip'] = 0.0;
          updatedData['pricePerKm'] =
              double.tryParse(_pricePerKmController.text) ?? 0.0;
        } else {
          updatedData['pricePerKmOrTrip'] =
              double.tryParse(_priceController.text) ?? 0.0;
          updatedData['pricePerKm'] =
              double.tryParse(_pricePerKmController.text) ?? 0.0;
        }
        updatedData['driverIncluded'] = _boolFlag;
        updatedData['operatorPrice'] =
            _boolFlag
                ? (double.tryParse(_operatorPriceController.text) ?? 0.0)
                : 0.0;
        updatedData['serviceArea'] = _serviceAreaController.text;
        updatedData['description'] =
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null;
        updatedData['location'] = _locationController.text;
        await _apiService.updateVehicle(
          widget.itemData['vehicleId'],
          updatedData,
        );
      } else if (widget.category == 'Equipment') {
        if (_secondaryController.text == 'Harvesters' ||
            _secondaryController.text == 'Sprayers' ||
            _secondaryController.text == 'Harvesting') {
          List<String> list = [];
          _equipmentCapacityMap.forEach((type, caps) {
            for (var c in caps) {
              list.add("$type - $c");
            }
          });
          updatedData['brandModel'] =
              list.isNotEmpty ? list.join(', ') : 'Standard Equipment';
        } else {
          updatedData['brandModel'] = _nameController.text;
        }
        updatedData['ownerBusinessName'] =
            _ownerBusinessNameController.text.isNotEmpty
                ? _ownerBusinessNameController.text
                : null;
        updatedData['description'] =
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null;

        final parts = _nameController.text.trim().split(' ');
        if (parts.length > 1) {
          updatedData['brand'] = parts[0];
          if (_secondaryController.text == 'Sprayers') {
            updatedData['model'] =
                updatedData['brandModel']
                    ?.toString()
                    .replaceFirst(parts[0], '')
                    .trim() ??
                '';
          } else {
            updatedData['model'] = parts.sublist(1).join(' ');
          }
        } else {
          updatedData['brand'] = _nameController.text;
          updatedData['model'] =
              _secondaryController.text == 'Sprayers'
                  ? updatedData['brandModel']
                  : '';
        }

        updatedData['pricePerHour'] =
            double.tryParse(_priceController.text) ?? 0.0;
        updatedData['category'] = _secondaryController.text;
        updatedData['operatorAvailable'] = _boolFlag;
        updatedData['operatorPrice'] =
            _boolFlag
                ? (double.tryParse(
                      _operatorPriceController.text.replaceAll(
                        RegExp(r'[^0-9.]'),
                        '',
                      ),
                    ) ??
                    0.0)
                : 0.0;
        updatedData['conditionStatus'] = _condition;
        updatedData['location'] = _locationController.text;

        await _apiService.updateEquipment(
          widget.itemData['equipmentId'],
          updatedData,
        );
      } else if (widget.category == 'Service') {
        updatedData['businessName'] = _nameController.text;
        updatedData['priceRate'] =
            double.tryParse(
              _priceController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
            ) ??
            0.0;
        updatedData['serviceType'] = _secondaryController.text;
        final bool isNoOpPriceService =
            _secondaryController.text == 'Electricians' ||
            _secondaryController.text == 'Vet Care' ||
            _secondaryController.text == 'Drone Spraying';
        bool hasOperator =
            (isNoOpPriceService &&
                    _secondaryController.text != 'Drone Spraying')
                ? false
                : _boolFlag;
        double parsedOpPrice =
            (isNoOpPriceService || !hasOperator)
                ? 0.0
                : (double.tryParse(
                      _operatorPriceController.text.replaceAll(
                        RegExp(r'[^0-9.]'),
                        '',
                      ),
                    ) ??
                    0.0);
        updatedData['operatorIncluded'] = hasOperator;
        updatedData['operatorPrice'] = parsedOpPrice;

        if (_secondaryController.text == 'Harvesting' ||
            _secondaryController.text == 'Drone Spraying') {
          List<String> list = [];
          _equipmentCapacityMap.forEach((type, caps) {
            for (var c in caps) {
              list.add("$type - $c");
            }
          });
          updatedData['equipmentUsed'] =
              list.isNotEmpty ? list.join(', ') : 'Standard Equipment';
        } else {
          updatedData['equipmentUsed'] = _equipmentUsedController.text;
        }
        updatedData['description'] = _descriptionController.text;
        updatedData['location'] = _locationController.text;
        updatedData['houseNo'] = _houseNoController.text;
        updatedData['street'] = _streetController.text;
        updatedData['village'] = _villageController.text;
        updatedData['mandal'] = _mandalController.text;
        updatedData['district'] = _districtController.text;
        updatedData['state'] = _stateController.text;
        updatedData['country'] = _countryController.text;
        updatedData['pincode'] = _pincodeController.text;
        await _apiService.updateService(
          widget.itemData['serviceId'],
          updatedData,
        );
      } else if (widget.category == 'WorkerGroup') {
        updatedData['groupName'] = _nameController.text;
        updatedData['pricePerMale'] =
            double.tryParse(_priceController.text) ?? 0.0;
        updatedData['pricePerFemale'] =
            double.tryParse(_secondaryController.text) ?? 0.0;
        updatedData['location'] = _locationController.text;
        await _apiService.updateWorkerGroup(
          widget.itemData['groupId'],
          updatedData,
        );
      }

      UiUtils.showCenteredToast(context, 'Item updated successfully!');
      Navigator.pop(context, true); // Return true to indicate change
    } catch (e) {
      UiUtils.showCustomAlert(context, 'Failed to update: $e', isError: true);
    }
  }

  Future<void> _deleteListing() async {
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text(
                  'Confirm Delete',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: const Text(
                  'Are you sure you want to delete this listing? This action cannot be undone.',
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red,
                      elevation: 0,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    try {
      final id =
          widget.itemData['equipmentId'] ??
          widget.itemData['vehicleId'] ??
          widget.itemData['serviceId'] ??
          widget.itemData['groupId'];

      if (widget.category == 'Vehicle')
        await _apiService.deleteVehicle(id);
      else if (widget.category == 'Equipment')
        await _apiService.deleteEquipment(id);
      else if (widget.category == 'Service')
        await _apiService.deleteService(id);
      else if (widget.category == 'WorkerGroup')
        await _apiService.deleteWorkerGroup(id);

      if (mounted) {
        UiUtils.showCenteredToast(
          context,
          '${widget.category} deleted successfully',
        );
        Navigator.pop(context, true); // Return true to signal deletion
      }
    } catch (e) {
      if (mounted)
        UiUtils.showCustomAlert(context, 'Failed to delete: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        title: Text(
          'Edit ${widget.category}',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF1B5E20),
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1B5E20),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Image Card
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 220,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_imageFile != null ||
                          (_imageUrl != null && _imageUrl!.isNotEmpty))
                        _imageFile != null
                            ? (kIsWeb
                                ? Image.network(
                                  _imageFile!.path,
                                  fit: BoxFit.cover,
                                )
                                : Image.file(
                                  File(_imageFile!.path),
                                  fit: BoxFit.cover,
                                ))
                            : Image.network(
                              ApiConfig.getFullImageUrl(_imageUrl),
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Container(
                                    color: const Color(0xFFF9FBF9),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.05),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.broken_image_rounded,
                                            size: 40,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Failed to load image',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            )
                      else
                        Container(
                          color: const Color(0xFFF9FBF9),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF00AA55,
                                  ).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_a_photo_rounded,
                                  size: 40,
                                  color: Color(0xFF00AA55),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Add High Quality Photo',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Edit Badge
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00AA55),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Form Sections
            _buildSectionCard(
              title: 'Basic Information',
              icon: Icons.info_outline_rounded,
              child: Column(
                children: [
                  if (widget.category == 'Vehicle') ...[
                    // Vehicle Type Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vehicle Type',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FBF9),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFFE8F5E9)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedVehicleType,
                              isExpanded: true,
                              hint: const Text('Select Vehicle Type'),
                              icon: const Icon(
                                Icons.expand_more_rounded,
                                color: Color(0xFF00AA55),
                              ),
                              items:
                                  _transportTypes
                                      .map(
                                        (t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(
                                            t,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (v) => setState(() {
                                    _selectedVehicleType = v;
                                    // Reset prices when type changes
                                    _priceController.clear();
                                    _pricePerKmController.clear();
                                  }),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      'Vehicle Number',
                      _nameController,
                      Icons.badge_outlined,
                      hint: 'e.g., TS 01 AB 1234',
                    ),
                  ] else if (widget.category == 'Equipment') ...[
                    _buildTextField(
                      'Owner / Business Name',
                      _ownerBusinessNameController,
                      Icons.person_rounded,
                      hint: 'e.g., Baldev Singh Farms',
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      'Category',
                      _secondaryController,
                      Icons.category_rounded,
                      hint: 'e.g., Tractor, Harvester',
                    ),
                    const SizedBox(height: 20),
                    if (_secondaryController.text == 'Harvesters' ||
                        _secondaryController.text == 'Harvesting') ...[
                      _buildEquipmentCapacitySection(
                        categoryTitle: 'HARVESTER TYPES',
                        subtitle: 'Add harvesters and their capacities:',
                        dropdownLabel: 'Harvester Type',
                        dropdownItems: HarvestingData.presetChips,
                        capacityLabel: 'Capacity (HP or Ft)',
                        capacityHint: 'e.g. 75 HP or 14 Ft',
                        defaultUnit: 'HP',
                        icon: Icons.agriculture_rounded,
                      ),
                    ] else if (_secondaryController.text == 'Sprayers' ||
                        _secondaryController.text == 'Drone Spraying') ...[
                      _buildEquipmentCapacitySection(
                        categoryTitle: 'SPRAYER TYPES',
                        subtitle: 'Add sprayers and their capacities:',
                        dropdownLabel: 'Sprayer Type',
                        dropdownItems: SprayerData.sprayerTypes,
                        capacityLabel: 'Capacity (Litres)',
                        capacityHint: 'e.g. 150',
                        defaultUnit: 'L',
                        icon: Icons.water_drop_rounded,
                      ),
                    ] else ...[
                      _buildTextField(
                        'Brand & Model',
                        _nameController,
                        Icons.branding_watermark_outlined,
                        hint: 'e.g., Mahindra 575 DI',
                      ),
                    ],
                  ] else if (widget.category == 'Service') ...[
                    _buildTextField(
                      'Service Type',
                      _secondaryController,
                      Icons.category_rounded,
                      hint: 'e.g., Drone Spraying',
                      enabled: false,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      'Business Name',
                      _nameController,
                      Icons.business_rounded,
                      hint: 'e.g., Precision Services',
                    ),
                    const SizedBox(height: 20),
                    if (_secondaryController.text == 'Harvesting') ...[
                      _buildEquipmentCapacitySection(
                        categoryTitle: 'HARVESTER TYPES',
                        subtitle: 'Add harvesters and their capacities:',
                        dropdownLabel: 'Harvesting Equipment Type',
                        dropdownItems: HarvestingData.presetChips,
                        capacityLabel: 'Capacity (HP or Ft)',
                        capacityHint: 'e.g. 75 HP or 14 Ft',
                        defaultUnit: 'HP',
                        icon: Icons.agriculture_rounded,
                      ),
                    ] else if (_secondaryController.text ==
                        'Drone Spraying') ...[
                      _buildEquipmentCapacitySection(
                        categoryTitle: 'SPRAYER TYPES',
                        subtitle: 'Add sprayers and their capacities:',
                        dropdownLabel: 'Sprayer Type',
                        dropdownItems: SprayerData.sprayerTypes,
                        capacityLabel: 'Capacity (Litres)',
                        capacityHint: 'e.g. 150',
                        defaultUnit: 'L',
                        icon: Icons.water_drop_rounded,
                      ),
                    ] else ...[
                      _buildTextField(
                        _secondaryController.text == 'Drone Spraying'
                            ? 'Drone / Sprayer Details'
                            : 'Equipment Used',
                        _equipmentUsedController,
                        _secondaryController.text == 'Drone Spraying'
                            ? Icons.airplay_rounded
                            : Icons.handyman_rounded,
                        hint:
                            _secondaryController.text == 'Drone Spraying'
                                ? 'e.g., DJI Agras T30 Drone'
                                : 'Standard Equipment',
                      ),
                    ],
                  ] else if (widget.category == 'WorkerGroup') ...[
                    _buildTextField(
                      'Group Name',
                      _nameController,
                      Icons.group_work_rounded,
                      hint: 'e.g., Evergreen Workers',
                    ),
                  ],
                ],
              ),
            ),

            _buildSectionCard(
              title: 'Pricing & Configuration',
              icon: Icons.payments_outlined,
              child: Column(
                children: [
                  if (widget.category == 'Vehicle') ...[
                    // Load Capacity with unit
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            'Load Capacity',
                            _capacityController,
                            Icons.line_weight_rounded,
                            keyboardType: TextInputType.number,
                            hint: 'e.g., 1.5',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Unit',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FBF9),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: const Color(0xFFE8F5E9),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCapacityUnit,
                                    isExpanded: true,
                                    items:
                                        ['Ton', 'kg']
                                            .map(
                                              (u) => DropdownMenuItem(
                                                value: u,
                                                child: Text(
                                                  u,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    onChanged:
                                        (v) => setState(
                                          () => _selectedCapacityUnit = v!,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Type-specific pricing fields
                    if (_selectedVehicleType == 'Tractor Trolley') ...[
                      _buildTextField(
                        'Full Day Price',
                        _priceController,
                        Icons.wb_sunny_rounded,
                        keyboardType: TextInputType.number,
                        hint: 'e.g. 1500',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        'Half Day Price',
                        _pricePerKmController,
                        Icons.wb_twilight_rounded,
                        keyboardType: TextInputType.number,
                        hint: 'e.g. 800',
                      ),
                    ] else if (_selectedVehicleType == 'Mini Truck' ||
                        _selectedVehicleType == 'Truck') ...[
                      _buildTextField(
                        'KM-wise Rate (per KM)',
                        _pricePerKmController,
                        Icons.speed_rounded,
                        keyboardType: TextInputType.number,
                        hint: 'e.g. 20',
                      ),
                    ] else ...[
                      _buildTextField(
                        'Daily Rate / Flat Price',
                        _priceController,
                        Icons.payments_rounded,
                        keyboardType: TextInputType.number,
                        hint: 'e.g. 1500',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        'KM-wise Rate (per KM)',
                        _pricePerKmController,
                        Icons.speed_rounded,
                        keyboardType: TextInputType.number,
                        hint: 'e.g. 20',
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildSwitchTile(
                      'Driver Included',
                      _boolFlag,
                      (v) => setState(() {
                        _boolFlag = v;
                        if (!v) _operatorPriceController.clear();
                      }),
                    ),
                    if (_boolFlag) ...[
                      const SizedBox(height: 12),
                      _buildTextField(
                        'Driver Price',
                        _operatorPriceController,
                        Icons.currency_rupee_rounded,
                        keyboardType: TextInputType.number,
                        hint: 'Driver charge per day/trip',
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildTextField(
                      'Service Area',
                      _serviceAreaController,
                      Icons.map_rounded,
                      hint: 'e.g. Within 50km',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      'Description',
                      _descriptionController,
                      Icons.description_rounded,
                      hint: 'Any extra info about this vehicle...',
                      maxLines: 3,
                    ),
                  ] else if (widget.category == 'Equipment') ...[
                    _buildTextField(
                      'Price Per Hour',
                      _priceController,
                      Icons.currency_rupee_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Condition Status',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FBF9),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFFE8F5E9)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<String>(
                              value: _condition,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              icon: const Icon(
                                Icons.expand_more_rounded,
                                color: Color(0xFF00AA55),
                              ),
                              items:
                                  ['New', 'Good', 'Average', 'Poor']
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(
                                            c,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) => setState(() => _condition = v),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSwitchTile(
                      'Operator Available',
                      _boolFlag,
                      (v) => setState(() {
                        _boolFlag = v;
                        if (!v) _operatorPriceController.clear();
                      }),
                    ),
                    if (_boolFlag) ...[
                      const SizedBox(height: 12),
                      _buildTextField(
                        'Operator Price',
                        _operatorPriceController,
                        Icons.currency_rupee_rounded,
                        keyboardType: TextInputType.number,
                        hint: 'Operator charge per day/hour',
                      ),
                    ],
                  ] else if (widget.category == 'Service') ...[
                    if (_secondaryController.text == 'Harvesting') ...[
                      _buildTextField(
                        'Full Day Charge (₹)',
                        _priceController,
                        Icons.wb_sunny_rounded,
                        keyboardType: TextInputType.number,
                        hint: 'e.g. 5000',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        'Half Day Charge (₹)',
                        _pricePerKmController,
                        Icons.wb_twilight_rounded,
                        keyboardType: TextInputType.number,
                        hint: 'e.g. 3000',
                      ),
                    ] else ...[
                      _buildTextField(
                        _secondaryController.text == 'Ploughing'
                            ? 'Price Rate (per Hour)'
                            : 'Price / Rate',
                        _priceController,
                        Icons.currency_rupee_rounded,
                        keyboardType: TextInputType.number,
                        hint:
                            _secondaryController.text == 'Ploughing'
                                ? 'e.g. ₹1500 / hr'
                                : null,
                      ),
                    ],
                    if (_secondaryController.text != 'Electricians' &&
                        _secondaryController.text != 'Vet Care') ...[
                      const SizedBox(height: 12),
                      _buildSwitchTile(
                        'Operator Included',
                        _boolFlag,
                        (v) => setState(() {
                          _boolFlag = v;
                          if (!v) _operatorPriceController.clear();
                        }),
                      ),
                      if (_boolFlag &&
                          _secondaryController.text != 'Drone Spraying') ...[
                        const SizedBox(height: 12),
                        _buildTextField(
                          'Operator Price',
                          _operatorPriceController,
                          Icons.currency_rupee_rounded,
                          keyboardType: TextInputType.number,
                          hint: 'Operator charge',
                        ),
                      ],
                    ],
                  ] else if (widget.category == 'WorkerGroup') ...[
                    _buildTextField(
                      'Price Per Male',
                      _priceController,
                      Icons.man_rounded,
                      keyboardType: TextInputType.number,
                      hint: 'Rate for male workers',
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      'Price Per Female',
                      _secondaryController,
                      Icons.woman_rounded,
                      keyboardType: TextInputType.number,
                      hint: 'Rate for female workers',
                    ),
                  ],
                ],
              ),
            ),

            if (widget.category == 'Equipment' &&
                _secondaryController.text == 'Tractors')
              _buildSectionCard(
                title: 'Attached Equipments',
                icon: Icons.agriculture_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select included equipments:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: [
                        ..._availableAttachedEquipments.map((eq) {
                          final isSelected = _selectedAttachedEquipments
                              .contains(eq);
                          return InputChip(
                            label: Text(eq),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedAttachedEquipments.add(eq);
                                } else {
                                  _selectedAttachedEquipments.remove(eq);
                                  if (eq == 'Other')
                                    _otherAttachedEquipmentController.clear();
                                }
                              });
                            },
                            onDeleted:
                                isSelected
                                    ? () {
                                      setState(() {
                                        _selectedAttachedEquipments.remove(eq);
                                        if (eq == 'Other')
                                          _otherAttachedEquipmentController
                                              .clear();
                                      });
                                    }
                                    : null,
                            deleteIconColor: const Color(0xFF00AA55),
                            showCheckmark: false,
                            selectedColor: const Color(0xFFE8F5E9),
                            labelStyle: TextStyle(
                              color:
                                  isSelected
                                      ? const Color(0xFF1B5E20)
                                      : Colors.grey[700],
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color:
                                    isSelected
                                        ? const Color(0xFF00AA55)
                                        : Colors.grey[300]!,
                              ),
                            ),
                            backgroundColor: Colors.white,
                          );
                        }),
                        ..._selectedAttachedEquipments
                            .where(
                              (eq) =>
                                  !_availableAttachedEquipments.contains(eq),
                            )
                            .map(
                              (eq) => InputChip(
                                label: Text(eq),
                                onDeleted: () {
                                  setState(() {
                                    _selectedAttachedEquipments.remove(eq);
                                  });
                                },
                                deleteIconColor: const Color(0xFF00AA55),
                                backgroundColor: const Color(0xFFE8F5E9),
                                labelStyle: const TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontWeight: FontWeight.w700,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(
                                    color: Color(0xFF00AA55),
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                    if (_selectedAttachedEquipments.contains('Other')) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              'Custom Equipment',
                              _otherAttachedEquipmentController,
                              Icons.add_circle_outline_rounded,
                              hint: 'e.g. Paddy Cultivator',
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final text =
                                  _otherAttachedEquipmentController.text.trim();
                              if (text.isNotEmpty &&
                                  !_selectedAttachedEquipments.contains(text)) {
                                setState(() {
                                  _selectedAttachedEquipments.add(text);
                                  _otherAttachedEquipmentController.clear();
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00AA55),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            child: const Text(
                              'Add',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            if (widget.category == 'Equipment' &&
                _secondaryController.text == 'Sprayers')
              _buildSectionCard(
                title: 'Sprayer Types',
                icon: Icons.water_drop_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add sprayers and their capacities:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _currentSelectedSprayerType,
                      decoration: InputDecoration(
                        labelText: 'Sprayer Type',
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2C3E50),
                        ),
                        prefixIcon: const Icon(
                          Icons.grass_rounded,
                          color: Color(0xFF00AA55),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFF00AA55),
                          ),
                        ),
                      ),
                      items:
                          _availableSprayerTypes
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                      onChanged:
                          (v) =>
                              setState(() => _currentSelectedSprayerType = v),
                    ),
                    if (_currentSelectedSprayerType == 'Other') ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Custom Sprayer Name',
                        _currentOtherSprayerTypeController,
                        Icons.edit_rounded,
                        hint: 'e.g. Special Sprayer',
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Capacity (Litres)',
                            _currentSprayerCapacityController,
                            Icons.water_rounded,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            hint: 'e.g. 150',
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (_currentSelectedSprayerType == null) return;

                            String type = _currentSelectedSprayerType!;
                            if (type == 'Other') {
                              final customType =
                                  _currentOtherSprayerTypeController.text
                                      .trim();
                              if (customType.isEmpty) return;
                              type = customType;

                              if (!_availableSprayerTypes.contains(type)) {
                                setState(() {
                                  _availableSprayerTypes.insert(
                                    _availableSprayerTypes.length - 1,
                                    type,
                                  );
                                });
                              }
                            }

                            final capText =
                                _currentSprayerCapacityController.text.trim();
                            if (capText.isNotEmpty) {
                              setState(() {
                                if (!_sprayerCapacitiesMap.containsKey(type)) {
                                  _sprayerCapacitiesMap[type] = [];
                                }
                                if (!_sprayerCapacitiesMap[type]!.contains(
                                  capText,
                                )) {
                                  _sprayerCapacitiesMap[type]!.add(capText);
                                }

                                _currentSprayerCapacityController.clear();
                                _currentOtherSprayerTypeController.clear();
                                _currentSelectedSprayerType = null;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00AA55),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            minimumSize: const Size(0, 54),
                          ),
                          child: const Text(
                            'Add',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (_sprayerCapacitiesMap.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Added Sprayers:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children:
                            _sprayerCapacitiesMap.entries.expand((entry) {
                              if (entry.value.isEmpty) {
                                return [
                                  Chip(
                                    label: Text(entry.key),
                                    deleteIconColor: const Color(0xFF00AA55),
                                    backgroundColor: const Color(0xFFE8F5E9),
                                    onDeleted: () {
                                      setState(() {
                                        _sprayerCapacitiesMap.remove(entry.key);
                                      });
                                    },
                                  ),
                                ];
                              }
                              return entry.value.map((capacity) {
                                return Chip(
                                  label: Text('${entry.key} - $capacity L'),
                                  deleteIconColor: const Color(0xFF00AA55),
                                  backgroundColor: const Color(0xFFE8F5E9),
                                  onDeleted: () {
                                    setState(() {
                                      _sprayerCapacitiesMap[entry.key]!.remove(
                                        capacity,
                                      );
                                      if (_sprayerCapacitiesMap[entry.key]!
                                          .isEmpty) {
                                        _sprayerCapacitiesMap.remove(entry.key);
                                      }
                                    });
                                  },
                                );
                              });
                            }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

            _buildSectionCard(
              title: 'Lush Location',
              icon: Icons.location_on_outlined,
              child: Column(
                children: [
                  _buildTextField(
                    'Location (Village -> Mandal -> District)',
                    _locationController,
                    Icons.map_rounded,
                    hint: 'e.g. Rampur, Nagpur',
                    suffixIcon:
                        _isFetchingLocation
                            ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF00AA55),
                                ),
                              ),
                            )
                            : IconButton(
                              icon: const Icon(
                                Icons.my_location_rounded,
                                color: Color(0xFF00AA55),
                              ),
                              onPressed: _fetchCurrentLocation,
                            ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'H.No',
                          _houseNoController,
                          Icons.home_rounded,
                          hint: 'e.g. 123',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          'Street',
                          _streetController,
                          Icons.map_rounded,
                          hint: 'Street Name',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Village',
                          _villageController,
                          Icons.location_city_rounded,
                          hint: 'Village Name',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          'Mandal',
                          _mandalController,
                          Icons.maps_home_work_rounded,
                          hint: 'Mandal Name',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'District',
                          _districtController,
                          Icons.location_city_rounded,
                          hint: 'District Name',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          'State',
                          _stateController,
                          Icons.map_outlined,
                          hint: 'State Name',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Pincode',
                          _pincodeController,
                          Icons.pin_drop_rounded,
                          hint: '6-digit code',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          'Country',
                          _countryController,
                          Icons.public_rounded,
                          hint: 'India',
                          enabled: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    'Description (Optional)',
                    _descriptionController,
                    Icons.description_rounded,
                    hint: 'Any extra info...',
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Update Button
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
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AA55),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Update Listing',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Delete Button
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _deleteListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Delete Listing',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: const Color(0xFF00AA55)),
                    const SizedBox(width: 12),
                    TranslatedText(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1B5E20).withOpacity(0.6),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    String? hint,
    int maxLines = 1,
    bool enabled = true,
  }) {
    final displayHint = hint ?? '';
    return TranslationBuilder(
      texts: [label, displayHint],
      builder: (context, translatedTexts) {
        final translatedLabel = translatedTexts[0];
        final translatedHint = translatedTexts[1];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translatedLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBF9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE8F5E9)),
              ),
              child: TextField(
                controller: controller,
                enabled: enabled,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                maxLines: maxLines,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF2C3E50),
                ),
                decoration: InputDecoration(
                  hintText: hint != null ? translatedHint : null,
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    icon,
                    color: const Color(0xFF00AA55),
                    size: 20,
                  ),
                  suffixIcon: suffixIcon,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8F5E9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF2C3E50),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00AA55),
            activeTrackColor: const Color(0xFF00AA55).withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCapacitySection({
    required String categoryTitle,
    required String subtitle,
    required String dropdownLabel,
    required List<String> dropdownItems,
    required String capacityLabel,
    required String capacityHint,
    required String defaultUnit,
    required IconData icon,
  }) {
    final singularName =
        categoryTitle.replaceAll('TYPES', '').trim().toLowerCase();
    final addedHeaderLabel =
        'Added ${singularName[0].toUpperCase()}${singularName.substring(1)}s:';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
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
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF00AA55), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                categoryTitle.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B5E20),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 14),

          // Dropdown
          DropdownButtonFormField<String>(
            value:
                dropdownItems.contains(_selectedEquipmentTypeForCap)
                    ? _selectedEquipmentTypeForCap
                    : null,
            decoration: InputDecoration(
              labelText: dropdownLabel,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF00AA55), size: 20),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FBF9),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFFE8F5E9)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFF00AA55),
                  width: 2,
                ),
              ),
            ),
            items:
                dropdownItems
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
            onChanged: (val) {
              setState(() {
                _selectedEquipmentTypeForCap = val;
              });
            },
          ),

          if (_selectedEquipmentTypeForCap == 'Others') ...[
            const SizedBox(height: 14),
            _buildTextField(
              'Custom Equipment Name',
              _customEquipmentTypeController,
              Icons.edit_note_rounded,
              hint: 'Specify custom equipment name...',
            ),
          ],

          const SizedBox(height: 16),
          Text(
            capacityLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),

          // Capacity TextField + Green Add Button
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBF9),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFE8F5E9)),
                  ),
                  child: TextField(
                    controller: _capacityInputController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF2C3E50),
                    ),
                    decoration: InputDecoration(
                      hintText: capacityHint,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: const Icon(
                        Icons.waves_rounded,
                        color: Color(0xFF00AA55),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final rawType = _selectedEquipmentTypeForCap;
                    final typeName =
                        (rawType == 'Others' &&
                                _customEquipmentTypeController.text
                                    .trim()
                                    .isNotEmpty)
                            ? _customEquipmentTypeController.text.trim()
                            : rawType;
                    final capVal = _capacityInputController.text.trim();

                    if (typeName == null || typeName.isEmpty) {
                      UiUtils.showCenteredToast(
                        context,
                        'Please select an equipment type',
                        isError: true,
                      );
                      return;
                    }
                    if (capVal.isEmpty) {
                      UiUtils.showCenteredToast(
                        context,
                        'Please enter capacity value',
                        isError: true,
                      );
                      return;
                    }

                    final capFormatted = "$capVal $defaultUnit";
                    setState(() {
                      if (_equipmentCapacityMap.containsKey(typeName)) {
                        if (!_equipmentCapacityMap[typeName]!.contains(
                          capFormatted,
                        )) {
                          _equipmentCapacityMap[typeName]!.add(capFormatted);
                        }
                      } else {
                        _equipmentCapacityMap[typeName] = [capFormatted];
                      }
                      _capacityInputController.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AA55),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Added Equipment Section Chips
          if (_equipmentCapacityMap.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              addedHeaderLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children:
                  _equipmentCapacityMap.entries.expand((entry) {
                    final eqType = entry.key;
                    return entry.value.map((capStr) {
                      final displayLabel = "$eqType - $capStr";
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _equipmentCapacityMap[eqType]!.remove(capStr);
                                  if (_equipmentCapacityMap[eqType]!.isEmpty) {
                                    _equipmentCapacityMap.remove(eqType);
                                  }
                                });
                              },
                              child: const Icon(
                                Icons.cancel,
                                size: 18,
                                color: Color(0xFF00AA55),
                              ),
                            ),
                          ],
                        ),
                      );
                    });
                  }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
