import 'package:flutter/material.dart';
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

class EditRegisteredItemScreen extends StatefulWidget {
  final String category; // 'Vehicle', 'Equipment', 'Service', 'WorkerGroup'
  final Map<String, dynamic> itemData;

  const EditRegisteredItemScreen({
    Key? key,
    required this.category,
    required this.itemData,
  }) : super(key: key);

  @override
  State<EditRegisteredItemScreen> createState() => _EditRegisteredItemScreenState();
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

  // Specifics
  late TextEditingController _secondaryController; // e.g., brandModel, type, groupName
  bool _boolFlag = false; // operatorAvailable, driverIncluded
  String? _condition; // Equipment
  late TextEditingController _capacityController; // Vehicle
  late TextEditingController _operatorPriceController;
  bool _isFetchingLocation = false;

  final List<String> _availableAttachedEquipments = [
    'Mouldboard Plow', 'Disc Plow', 'Chisel Plow', 'Rotavator', 'Disc Harrow', 'Other'
  ];
  List<String> _selectedAttachedEquipments = [];
  final TextEditingController _otherAttachedEquipmentController = TextEditingController();

  final List<String> _defaultSprayerTypes = [
    'Handheld sprayers', 'Knapsack (backpack) sprayers', 'Foot and rocker sprayers',
    'Portable power/HTP sprayers', 'Mist blowers/dusters', 'Knapsack power sprayers', 'Other'
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
    _locationController = TextEditingController(text: widget.itemData['location']?.toString() ?? '');
    _secondaryController = TextEditingController();
    _capacityController = TextEditingController();
    _ownerBusinessNameController = TextEditingController(text: widget.itemData['ownerBusinessName']?.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.itemData['description']?.toString() ?? '');
    _imageUrl = widget.itemData['imageUrl']?.toString();
    _operatorPriceController = TextEditingController(text: widget.itemData['operatorPrice']?.toString() ?? '');
    _currentOtherSprayerTypeController = TextEditingController();
    _currentSprayerCapacityController = TextEditingController();
    if (widget.category == 'Vehicle') {
      _nameController.text = widget.itemData['vehicleNumber']?.toString() ?? '';
      _priceController.text = widget.itemData['pricePerKmOrTrip']?.toString() ?? '';
      _pricePerKmController.text = widget.itemData['pricePerKm']?.toString() ?? '';
      _secondaryController.text = widget.itemData['vehicleType']?.toString() ?? '';
      _capacityController.text = widget.itemData['loadCapacity']?.toString() ?? '';
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
            attachedList = clean.split(RegExp(r',\s*(?![^()]*\))')).where((e) => e.isNotEmpty).toList();
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
                   caps = match.group(1)!.split(',').map((e) => e.replaceAll('L', '').trim()).where((e) => e.isNotEmpty).toList();
                }
             }
             if (caps.isNotEmpty) {
               _sprayerCapacitiesMap[typeName] = caps;
             } else {
               _sprayerCapacitiesMap[typeName] = [];
             }
             if (!_availableSprayerTypes.contains(typeName)) {
                 _availableSprayerTypes.insert(_availableSprayerTypes.length - 1, typeName);
             }
          }
        }
        _nameController.text = widget.itemData['brandModel']?.toString() ?? '';
        // Remove global capacity parsing logic
        if (attachedStr != null && attachedStr.isNotEmpty) {
          _selectedAttachedEquipments = attachedStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
      }
    } else if (widget.category == 'Service') {
      _nameController.text = widget.itemData['businessName']?.toString() ?? '';
      _priceController.text = widget.itemData['priceRate']?.toString() ?? '';
      _secondaryController.text = widget.itemData['serviceType']?.toString() ?? '';
      _boolFlag = widget.itemData['operatorIncluded'] ?? false;
    } else if (widget.category == 'WorkerGroup') {
      _nameController.text = widget.itemData['groupName']?.toString() ?? '';
      _priceController.text = widget.itemData['pricePerMale']?.toString() ?? '';
      _secondaryController.text = widget.itemData['pricePerFemale']?.toString() ?? ''; // Using secondary for female price
      // Can add more fields if needed
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
    _operatorPriceController.dispose();
    _otherAttachedEquipmentController.dispose();
    _currentOtherSprayerTypeController.dispose();
    _currentSprayerCapacityController.dispose();
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
        UiUtils.showCenteredToast(context, 'Location permissions are permanently denied');
        setState(() => _isFetchingLocation = false);
        return;
      }

      
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // Use helper for cross-platform reverse geocoding
      final addressData = await LocationHelper.getAddressFromCoordinates(position.latitude, position.longitude);
      final String village = addressData['village']!;
      final String district = addressData['district']!;
      final String exactAddress = addressData['exactAddress']!;
      
      if (mounted) {
        setState(() {
           _locationController.text = exactAddress;
        });
        
        UiUtils.showCenteredToast(
          context, 
          'Location detected: $exactAddress\nCoords: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'
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
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
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
        updatedData['vehicleNumber'] = _nameController.text;
        updatedData['pricePerKmOrTrip'] = double.tryParse(_priceController.text) ?? 0.0;
        updatedData['pricePerKm'] = double.tryParse(_pricePerKmController.text) ?? 0.0;
        updatedData['vehicleType'] = _secondaryController.text;
        updatedData['loadCapacity'] = _capacityController.text;
        updatedData['driverIncluded'] = _boolFlag;
        updatedData['operatorPrice'] = _boolFlag ? (double.tryParse(_operatorPriceController.text) ?? 0.0) : 0.0;
        updatedData['location'] = _locationController.text;
        await _apiService.updateVehicle(widget.itemData['vehicleId'], updatedData);
      } else if (widget.category == 'Equipment') {
        if (_secondaryController.text == 'Sprayers') {
          updatedData['brandModel'] = _nameController.text.trim();
          
          List<String> finalEquipments = [];
          List<String> allCaps = [];
          
          for (var entry in _sprayerCapacitiesMap.entries) {
            String type = entry.key;
            List<String> caps = entry.value;
            
            if (_currentSelectedSprayerType == type && _currentSprayerCapacityController.text.isNotEmpty) {
               if (!caps.contains(_currentSprayerCapacityController.text.trim())) {
                 caps.add(_currentSprayerCapacityController.text.trim());
               }
            }
            
            if (caps.isNotEmpty) {
              finalEquipments.add('$type (Capacities: ${caps.join(', ')}L)');
              allCaps.addAll(caps);
            } else {
              finalEquipments.add(type);
            }
          }
          
          if (_currentSelectedSprayerType != null && _currentSprayerCapacityController.text.isNotEmpty) {
             String pendingType = _currentSelectedSprayerType!;
             if (pendingType == 'Other') {
               pendingType = _currentOtherSprayerTypeController.text.trim();
             }
             if (pendingType.isNotEmpty && !_sprayerCapacitiesMap.containsKey(pendingType)) {
                 finalEquipments.add('$pendingType (Capacities: ${_currentSprayerCapacityController.text.trim()}L)');
                 allCaps.add(_currentSprayerCapacityController.text.trim());
             }
          }
          
          updatedData['attachedEquipments'] = finalEquipments.join(', ');
          updatedData['sprayerTypes'] = finalEquipments;
          updatedData['sprayerCapacities'] = allCaps.toSet().toList();
        } else {
          updatedData['brandModel'] = _nameController.text;
          
          List<String> finalAttached = List.from(_selectedAttachedEquipments);
          finalAttached.remove('Other');
          if (finalAttached.isNotEmpty) {
            updatedData['attachedEquipments'] = finalAttached.join(', ');
          } else {
            updatedData['attachedEquipments'] = '';
          }
        }

        updatedData['ownerBusinessName'] = _ownerBusinessNameController.text.isNotEmpty ? _ownerBusinessNameController.text : null;
        updatedData['description'] = _descriptionController.text.isNotEmpty ? _descriptionController.text : null;
        
        final parts = _nameController.text.trim().split(' ');
        if (parts.length > 1) {
          updatedData['brand'] = parts[0];
          if (_secondaryController.text == 'Sprayers') {
             updatedData['model'] = updatedData['brandModel']?.toString().replaceFirst(parts[0], '').trim() ?? '';
          } else {
             updatedData['model'] = parts.sublist(1).join(' ');
          }
        } else {
          updatedData['brand'] = _nameController.text;
          updatedData['model'] = _secondaryController.text == 'Sprayers' ? updatedData['brandModel'] : '';
        }

        updatedData['pricePerHour'] = double.tryParse(_priceController.text) ?? 0.0;
        updatedData['category'] = _secondaryController.text;
        updatedData['operatorAvailable'] = _boolFlag;
        updatedData['operatorPrice'] = _boolFlag ? (double.tryParse(_operatorPriceController.text) ?? 0.0) : 0.0;
        updatedData['conditionStatus'] = _condition;
        updatedData['location'] = _locationController.text;

        await _apiService.updateEquipment(widget.itemData['equipmentId'], updatedData);
      } else if (widget.category == 'Service') {
        updatedData['businessName'] = _nameController.text;
        updatedData['priceRate'] = double.tryParse(_priceController.text) ?? 0.0;
        updatedData['serviceType'] = _secondaryController.text;
        final bool isElectrOrVet = _secondaryController.text == 'Electricians' || _secondaryController.text == 'Vet Care';
        updatedData['operatorIncluded'] = isElectrOrVet ? false : _boolFlag;
        updatedData['operatorPrice'] = (isElectrOrVet || !_boolFlag) ? 0.0 : (double.tryParse(_operatorPriceController.text) ?? 0.0);
        updatedData['location'] = _locationController.text;
        await _apiService.updateService(widget.itemData['serviceId'], updatedData);
      } else if (widget.category == 'WorkerGroup') {
        updatedData['groupName'] = _nameController.text;
        updatedData['pricePerMale'] = double.tryParse(_priceController.text) ?? 0.0;
        updatedData['pricePerFemale'] = double.tryParse(_secondaryController.text) ?? 0.0;
        updatedData['location'] = _locationController.text;
        await _apiService.updateWorkerGroup(widget.itemData['groupId'], updatedData);
      }

      UiUtils.showCenteredToast(context, 'Item updated successfully!');
      Navigator.pop(context, true); // Return true to indicate change
    } catch (e) {
      UiUtils.showCustomAlert(context, 'Failed to update: $e', isError: true);
    }
  }

  Future<void> _deleteListing() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this listing? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancel', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red, elevation: 0),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      final id = widget.itemData['equipmentId'] ?? widget.itemData['vehicleId'] ?? widget.itemData['serviceId'] ?? widget.itemData['groupId'];
      
      if (widget.category == 'Vehicle') await _apiService.deleteVehicle(id);
      else if (widget.category == 'Equipment') await _apiService.deleteEquipment(id);
      else if (widget.category == 'Service') await _apiService.deleteService(id);
      else if (widget.category == 'WorkerGroup') await _apiService.deleteWorkerGroup(id);

      if (mounted) {
        UiUtils.showCenteredToast(context, '${widget.category} deleted successfully');
        Navigator.pop(context, true); // Return true to signal deletion
      }
    } catch (e) {
      if (mounted) UiUtils.showCustomAlert(context, 'Failed to delete: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        title: Text('Edit ${widget.category}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1B5E20), fontSize: 18)),
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
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_imageFile != null || (_imageUrl != null && _imageUrl!.isNotEmpty))
                         _imageFile != null
                            ? (kIsWeb 
                                ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                                : Image.file(File(_imageFile!.path), fit: BoxFit.cover))
                            : Image.network(
                                ApiConfig.getFullImageUrl(_imageUrl), 
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFFF9FBF9),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.05),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.broken_image_rounded, size: 40, color: Colors.red),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Failed to load image', 
                                        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w700, fontSize: 14)
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
                                  color: const Color(0xFF00AA55).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_a_photo_rounded, size: 40, color: Color(0xFF00AA55)),
                              ),
                              const SizedBox(height: 12),
                              Text('Add High Quality Photo', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w700, fontSize: 14)),
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
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
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
                    _buildTextField('Vehicle Type', _secondaryController, Icons.category_rounded, hint: 'e.g., Tractor, Trolley'),
                    const SizedBox(height: 20),
                    _buildTextField('Vehicle Number', _nameController, Icons.badge_outlined, hint: 'e.g., TS 01 AB 1234'),
                  ] else if (widget.category == 'Equipment') ...[
                    _buildTextField('Owner / Business Name', _ownerBusinessNameController, Icons.person_rounded, hint: 'e.g., Baldev Singh Farms'),
                    const SizedBox(height: 20),
                    _buildTextField('Category', _secondaryController, Icons.category_rounded, hint: 'e.g., Tractor, Harvester'),
                    const SizedBox(height: 20),
                    _buildTextField('Brand & Model', _nameController, Icons.branding_watermark_outlined, hint: 'e.g., Mahindra 575 DI'),
                    const SizedBox(height: 20),
                    _buildTextField('Description (Optional)', _descriptionController, Icons.description_rounded, hint: 'e.g., Accessories included, good condition', maxLines: 3),
                  ] else if (widget.category == 'Service') ...[
                    _buildTextField('Service Type', _secondaryController, Icons.category_rounded, hint: 'e.g., Electrical, Plumbing'),
                    const SizedBox(height: 20),
                    _buildTextField('Business Name', _nameController, Icons.business_rounded, hint: 'e.g., Precision Services'),
                  ] else if (widget.category == 'WorkerGroup') ...[
                    _buildTextField('Group Name', _nameController, Icons.group_work_rounded, hint: 'e.g., Evergreen Workers'),
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
                    _buildTextField('Load Capacity', _capacityController, Icons.line_weight_rounded, hint: 'e.g., 5 Tons'),
                    const SizedBox(height: 20),
                    _buildTextField('Daily Rate / Flat Price', _priceController, Icons.currency_rupee_rounded, keyboardType: TextInputType.number),
                    const SizedBox(height: 20),
                    _buildTextField('KM-wise Rate', _pricePerKmController, Icons.speed_rounded, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    _buildSwitchTile('Driver Included', _boolFlag, (v) => setState(() {
                      _boolFlag = v;
                      if (!v) _operatorPriceController.clear();
                    })),
                    if (_boolFlag) ...[
                      const SizedBox(height: 12),
                      _buildTextField('Driver Price', _operatorPriceController, Icons.currency_rupee_rounded, keyboardType: TextInputType.number, hint: 'Driver charge per day/trip'),
                    ],
                  ] else if (widget.category == 'Equipment') ...[
                    _buildTextField('Price Per Hour', _priceController, Icons.currency_rupee_rounded, keyboardType: TextInputType.number),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Condition Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
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
                              decoration: const InputDecoration(border: InputBorder.none),
                              icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF00AA55)),
                              items: ['New', 'Good', 'Average', 'Poor'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                              onChanged: (v) => setState(() => _condition = v),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSwitchTile('Operator Available', _boolFlag, (v) => setState(() {
                      _boolFlag = v;
                      if (!v) _operatorPriceController.clear();
                    })),
                    if (_boolFlag) ...[
                      const SizedBox(height: 12),
                      _buildTextField('Operator Price', _operatorPriceController, Icons.currency_rupee_rounded, keyboardType: TextInputType.number, hint: 'Operator charge per day/hour'),
                    ],
                  ] else if (widget.category == 'Service') ...[
                    _buildTextField('Price / Rate', _priceController, Icons.currency_rupee_rounded, keyboardType: TextInputType.number),
                    if (_secondaryController.text != 'Electricians' && _secondaryController.text != 'Vet Care') ...[
                      const SizedBox(height: 12),
                      _buildSwitchTile('Operator Included', _boolFlag, (v) => setState(() {
                        _boolFlag = v;
                        if (!v) _operatorPriceController.clear();
                      })),
                      if (_boolFlag) ...[
                        const SizedBox(height: 12),
                        _buildTextField('Operator Price', _operatorPriceController, Icons.currency_rupee_rounded, keyboardType: TextInputType.number, hint: 'Operator charge'),
                      ],
                    ],
                  ] else if (widget.category == 'WorkerGroup') ...[
                    _buildTextField('Price Per Male', _priceController, Icons.man_rounded, keyboardType: TextInputType.number, hint: 'Rate for male workers'),
                    const SizedBox(height: 20),
                    _buildTextField('Price Per Female', _secondaryController, Icons.woman_rounded, keyboardType: TextInputType.number, hint: 'Rate for female workers'),
                  ],
                ],
              ),
            ),

            if (widget.category == 'Equipment' && _secondaryController.text == 'Tractors')
              _buildSectionCard(
                title: 'Attached Equipments',
                icon: Icons.agriculture_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select included equipments:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: [
                        ..._availableAttachedEquipments.map((eq) {
                          final isSelected = _selectedAttachedEquipments.contains(eq);
                          return InputChip(
                            label: Text(eq),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedAttachedEquipments.add(eq);
                                } else {
                                  _selectedAttachedEquipments.remove(eq);
                                  if (eq == 'Other') _otherAttachedEquipmentController.clear();
                                }
                              });
                            },
                            onDeleted: isSelected ? () {
                              setState(() {
                                _selectedAttachedEquipments.remove(eq);
                                if (eq == 'Other') _otherAttachedEquipmentController.clear();
                              });
                            } : null,
                            deleteIconColor: const Color(0xFF00AA55),
                            showCheckmark: false,
                            selectedColor: const Color(0xFFE8F5E9),
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
                        }),
                        ..._selectedAttachedEquipments
                            .where((eq) => !_availableAttachedEquipments.contains(eq))
                            .map((eq) => InputChip(
                                  label: Text(eq),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedAttachedEquipments.remove(eq);
                                    });
                                  },
                                  deleteIconColor: const Color(0xFF00AA55),
                                  backgroundColor: const Color(0xFFE8F5E9),
                                  labelStyle: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w700),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(color: Color(0xFF00AA55)),
                                  ),
                                )),
                      ],
                    ),
                    if (_selectedAttachedEquipments.contains('Other')) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField('Custom Equipment', _otherAttachedEquipmentController, Icons.add_circle_outline_rounded, hint: 'e.g. Paddy Cultivator'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final text = _otherAttachedEquipmentController.text.trim();
                              if (text.isNotEmpty && !_selectedAttachedEquipments.contains(text)) {
                                setState(() {
                                  _selectedAttachedEquipments.add(text);
                                  _otherAttachedEquipmentController.clear();
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00AA55),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            if (widget.category == 'Equipment' && _secondaryController.text == 'Sprayers')
              _buildSectionCard(
                title: 'Sprayer Types',
                icon: Icons.water_drop_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add sprayers and their capacities:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _currentSelectedSprayerType,
                      decoration: InputDecoration(
                        labelText: 'Sprayer Type',
                        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50)),
                        prefixIcon: const Icon(Icons.grass_rounded, color: Color(0xFF00AA55)),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[300]!)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF00AA55))),
                      ),
                      items: _availableSprayerTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _currentSelectedSprayerType = v),
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
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            hint: 'e.g. 150',
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (_currentSelectedSprayerType == null) return;
                            
                            String type = _currentSelectedSprayerType!;
                            if (type == 'Other') {
                              final customType = _currentOtherSprayerTypeController.text.trim();
                              if (customType.isEmpty) return;
                              type = customType;
                              
                              if (!_availableSprayerTypes.contains(type)) {
                                setState(() {
                                  _availableSprayerTypes.insert(_availableSprayerTypes.length - 1, type);
                                });
                              }
                            }
                            
                            final capText = _currentSprayerCapacityController.text.trim();
                            if (capText.isNotEmpty) {
                              setState(() {
                                if (!_sprayerCapacitiesMap.containsKey(type)) {
                                  _sprayerCapacitiesMap[type] = [];
                                }
                                if (!_sprayerCapacitiesMap[type]!.contains(capText)) {
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            minimumSize: const Size(0, 54),
                          ),
                          child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    if (_sprayerCapacitiesMap.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text('Added Sprayers:', style: TextStyle(fontSize: 13, color: Color(0xFF1B5E20), fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _sprayerCapacitiesMap.entries.expand((entry) {
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
                              )
                            ];
                          }
                          return entry.value.map((capacity) {
                            return Chip(
                              label: Text('${entry.key} - $capacity L'),
                              deleteIconColor: const Color(0xFF00AA55),
                              backgroundColor: const Color(0xFFE8F5E9),
                              onDeleted: () {
                                setState(() {
                                  _sprayerCapacitiesMap[entry.key]!.remove(capacity);
                                  if (_sprayerCapacitiesMap[entry.key]!.isEmpty) {
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
              child: _buildTextField(
                'Deployment Location', 
                _locationController,
                Icons.map_rounded,
                hint: 'Village, District...',
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

            const SizedBox(height: 12),

            // Update Button
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
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AA55),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Update Listing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
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
                  BoxShadow(color: Colors.red.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: ElevatedButton(
                onPressed: _deleteListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Delete Listing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
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
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF1B5E20).withOpacity(0.6), letterSpacing: 1.2),
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

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text, Widget? suffixIcon, String? hint, int maxLines = 1, List<TextInputFormatter>? inputFormatters}) {
    final displayHint = hint ?? '';
    return TranslationBuilder(
      texts: [label, displayHint],
      builder: (context, translatedTexts) {
        final translatedLabel = translatedTexts[0];
        final translatedHint = translatedTexts[1];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(translatedLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBF9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE8F5E9)),
              ),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                maxLines: maxLines,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF2C3E50)),
                decoration: InputDecoration(
                  hintText: hint != null ? translatedHint : null,
                  hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
                  prefixIcon: Icon(icon, color: const Color(0xFF00AA55), size: 20),
                  suffixIcon: suffixIcon,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF2C3E50))),
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
}
