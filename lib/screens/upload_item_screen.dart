import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:agriculture/l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../services/geocoding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../utils/provider_manager.dart';
import '../data/vehicle_data.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../utils/ui_utils.dart';

class UploadItemScreen extends StatefulWidget {
  final String category; // 'Transport', 'Equipment', 'Farm Workers', 'Ploughing' (future)

  const UploadItemScreen({super.key, required this.category});

  @override
  State<UploadItemScreen> createState() => _UploadItemScreenState();
}

class _UploadItemScreenState extends State<UploadItemScreen> {
  XFile? _selectedImage;
  bool _isUploading = false;
  bool _isSubmitting = false;
  bool _isFetchingLocation = false;
  double _selectedLatitude = 0.0;
  double _selectedLongitude = 0.0;
  
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  final Map<String, String?> _fieldErrors = {};
  

  Future<bool> _requestMediaPermission() async {
    if (kIsWeb) return true;
    PermissionStatus status;
    if (Platform.isAndroid) {
      // In Android 13+ (API 33+), READ_EXTERNAL_STORAGE is deprecated.
      // Use Permission.photos. For older Androids, Permission.storage.
      // permission_handler makes it easy by requesting both or the relevant one.
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.photos,
      ].request();
      
      bool photosGranted = statuses[Permission.photos]?.isGranted ?? false;
      bool photosLimited = statuses[Permission.photos]?.isLimited ?? false;
      bool storageGranted = statuses[Permission.storage]?.isGranted ?? false;

      if (photosGranted || photosLimited || storageGranted) {
        return true;
      }
      return false;
    } else if (Platform.isIOS) {
       status = await Permission.photos.request();
       return status.isGranted || status.isLimited;
    }
    return true; // Default for web/desktop
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text("Media/Photo access is required to upload asset images. Please allow it in the app settings to proceed."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00AA55)),
            child: const Text("Open Settings", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    bool hasPermission = await _requestMediaPermission();
    if (!hasPermission) {
      _showPermissionDeniedDialog();
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
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
      
      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
      });

      String? village;
      String? district;

      // Try cross-platform geocoding (nominatim)
      try {
        final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json');
        final responseData = await http.get(url, headers: {'User-Agent': 'AgriFarmsApp/1.0'});
        final response = json.decode(responseData.body);
        if (response != null && response['address'] != null) {
          village = response['address']['suburb'] ?? response['address']['village'] ?? response['address']['neighbourhood'] ?? response['address']['city_district'];
          district = response['address']['district'] ?? response['address']['city'] ?? response['address']['county'];
        }
      } catch (e) {
        debugPrint("Reverse geocoding failed: $e");
      }

      // Fallback to mobile-specific if on Android/iOS and previous failed
      if (village == null && !kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          final placemarks = await geo.placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            final place = placemarks[0];
            village = place.subLocality ?? place.locality;
            district = place.subAdministrativeArea ?? place.administrativeArea;
          }
        } catch (e) {}
      }

      village ??= 'Unknown Village';
      district ??= 'District';

      setState(() {
        _locationController.text = "$village, $district";
        _villageController.text = village!;
        _districtController.text = district!;
      });
      
      if (mounted) {
        UiUtils.showCenteredToast(context, 'Location detected: $village, $district');
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

  Future<String?> _uploadSelectedImage() async {
    if (_selectedImage == null) return null;
    setState(() => _isUploading = true);
    try {
      final response = await ApiService().uploadImage(_selectedImage!);
      final String? relativeUrl = response['url'];
      if (relativeUrl != null) {
        return relativeUrl;
      }
      return null;
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
  // Common Controllers
  final TextEditingController _nameController = TextEditingController(); // Name / Title
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Address Detail Controllers
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(text: 'India');
  final TextEditingController _pincodeController = TextEditingController();

  // Transport Specific
  String? _selectedTransportType;
  String? _selectedVehicleMake; // New
  String? _selectedVehicleModel; // New
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _vehicleNumberController = TextEditingController(); // New
  final TextEditingController _serviceAreaController = TextEditingController(); // New
  bool _driverIncluded = true;

  // Equipment Specific
  String? _selectedEquipmentType; 
  String? _selectedMake; // New
  String? _selectedModel; // New
  final TextEditingController _brandModelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController(); // New
  bool _operatorAvailable = false;
  String _condition = 'Good';

  // Farm Worker Specific
  final TextEditingController _maleCountController = TextEditingController();
  final TextEditingController _femaleCountController = TextEditingController();
  final TextEditingController _malePriceController = TextEditingController();
  final TextEditingController _femalePriceController = TextEditingController();
  final TextEditingController _malePriceHourlyController = TextEditingController();
  final TextEditingController _femalePriceHourlyController = TextEditingController();
  // Role Distribution
  final List<String> _roleDistributions = [];
  final TextEditingController _roleCountController = TextEditingController();
  // String? _selectedRoleTask; // Removed
  String _roleGender = 'Male';
  // Skills handled by _selectedSkills list now
  
  // Service Specific (Ploughing, etc.)
  final TextEditingController _equipmentUsedController = TextEditingController(); // e.g., "John Deere 5310"
  bool _operatorIncludedService = true;
  String? _selectedServiceType; // New for generic Services category

  // Mock Lists
  final List<String> _transportTypes = ['Mini Truck', 'Tractor Trolley', 'Full Truck', 'Tempo', 'Pickup Van', 'Container'];
  final List<String> _equipmentCategories = ['Tractors', 'Harvesters', 'Sprayers', 'Trolleys', 'JCB']; 
  final List<String> _serviceCategories = ['Ploughing', 'Harvesting', 'Drone Spraying', 'Irrigation', 'Soil Testing', 'Vet Care', 'Electricians', 'Mechanics', 'Farm Workers']; // Added Farm Workers
  
  final List<String> _conditions = ['New', 'Good', 'Average', 'Poor'];

  final List<String> _farmSkills = [
    'Harvesting', 'Sowing', 'Plowing', 'Fertilizer Application', 
    'Pesticide Spraying', 'Weeding', 'Irrigation', 'Pruning', 
    'Grading & Sorting', 'Loading & Unloading', 'Cattle Management', 'Others'
  ];
  final List<String> _selectedSkills = [];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _vehicleNumberController.dispose();
    _serviceAreaController.dispose();
    _brandModelController.dispose();
    _yearController.dispose();
    _maleCountController.dispose();
    _femaleCountController.dispose();
    _malePriceController.dispose();
    _femalePriceController.dispose();
    _roleCountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  
  Future<void> _updateCoordinatesFromAddress() async {
    try {
      String fullAddress = "${_houseNoController.text}, ${_streetController.text}, ${_villageController.text}, ${_districtController.text}, ${_stateController.text}, ${_countryController.text}, ${_pincodeController.text}";
      
      double? lat, lng;
      // Local geocoding
      try {
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          List<geo.Location> locations = await geo.locationFromAddress(fullAddress);
          if (locations.isNotEmpty) {
            lat = locations.first.latitude;
            lng = locations.first.longitude;
          }
        }
      } catch (e) {}

      
      // OS geocoding fallback
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
          _selectedLatitude = lat!;
          _selectedLongitude = lng!;
        });
      }
    } catch (e) {
      debugPrint("Geocoding failed: $e");
    }
  }

  Future<void> _submit() async {
    await _updateCoordinatesFromAddress();
    setState(() => _isSubmitting = true);
    try {
      // If we are in 'Services' generic category and the selected dropdown item is 'Farm Workers'
      if (widget.category == 'Farm Workers' || (widget.category == 'Services' && _selectedServiceType == 'Farm Workers')) {
        await _submitFarmWorker();
      } else if (widget.category == 'Transport') {
        await _submitTransport();
      } else if (widget.category == 'Equipment') {
        await _submitEquipment();
      } else {
        // Treat as generic service if not specific
        await _submitService();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitFarmWorker() async {
    setState(() => _fieldErrors.clear());
    bool hasError = false;

    if (_nameController.text.isEmpty) {
      _fieldErrors['name'] = 'Please enter group name';
      hasError = true;
    }
    if (_maleCountController.text.isEmpty && _femaleCountController.text.isEmpty) {
      _fieldErrors['maleCount'] = 'Enter at least one';
      _fieldErrors['femaleCount'] = 'Enter at least one';
      hasError = true;
    }
    if (_roleDistributions.isEmpty) {
      _fieldErrors['roles'] = AppLocalizations.of(context)!.selectSkillError;
      hasError = true;
    }

    if (hasError) {
      _showError(AppLocalizations.of(context)!.fillRequiredFields);
      return;
    }

    // Derive skills from the added roles
    final derivedSkills = _roleDistributions
        .map((e) => e.split('-')[1].trim())
        .expand((e) => e.split(',').map((s) => s.trim()))
        .toSet()
        .toList();

    try {
      final prefs = await SharedPreferences.getInstance();
      final ownerId = prefs.getString('user_id') ?? 'unknown_owner';

      // Parse _roleDistributions (e.g. "5 Male - Sowing, Harvesting") into List of maps for DTO
      List<Map<String, dynamic>> rolesPayload = [];
      for (String roleStr in _roleDistributions) {
        // e.g. "5 Male - Sowing, Weeding"
        final parts = roleStr.split('-');
        if (parts.length == 2) {
          final countAndGender = parts[0].trim().split(' '); // ["5", "Male"]
          final tasks = parts[1].trim(); // "Sowing, Weeding"
          
          if (countAndGender.length >= 2) {
            int count = int.tryParse(countAndGender[0]) ?? 0;
            String gender = countAndGender[1];
            rolesPayload.add({
              'gender': gender,
              'count': count,
              'taskName': tasks
            });
          }
        }
      }

      final Map<String, dynamic> workerGroupData = {
        'ownerId': ownerId,
        'groupName': _nameController.text,
        'maleCount': int.tryParse(_maleCountController.text) ?? 0,
        'femaleCount': int.tryParse(_femaleCountController.text) ?? 0,
        'pricePerMale': double.tryParse(_malePriceController.text) ?? 0.0,
        'pricePerFemale': double.tryParse(_femalePriceController.text) ?? 0.0,
        'pricePerMaleHourly': double.tryParse(_malePriceHourlyController.text) ?? 0.0,
        'pricePerFemaleHourly': double.tryParse(_femalePriceHourlyController.text) ?? 0.0,
        'skills': derivedSkills.join(', '),
        'location': _locationController.text.isNotEmpty ? _locationController.text : 'Local',
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
        'serviceRangeKm': 50, // default or add field later
        'isAvailable': true,
        'rating': 5.0,
        'approvalStatus': 'Pending',
        'imageUrl': await _uploadSelectedImage() ?? 'https://placehold.co/600x400?text=Workers',
        'roles': rolesPayload
      };

      await ApiService().addWorkerGroup(workerGroupData);

      final newProvider = FarmWorkerListing(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text, // Group Name
        serviceName: 'Farm Workers',
        distance: '0.5 km', // Mock
        rating: 5.0,
        approvalStatus: 'Pending',
        location: _locationController.text.isNotEmpty ? _locationController.text : 'Local',
        maleCount: int.tryParse(_maleCountController.text) ?? 0,
        femaleCount: int.tryParse(_femaleCountController.text) ?? 0,
        malePrice: int.tryParse(_malePriceController.text) ?? 0,
        femalePrice: int.tryParse(_femalePriceController.text) ?? 0,
        malePriceHourly: int.tryParse(_malePriceHourlyController.text) ?? 0,
        femalePriceHourly: int.tryParse(_femalePriceHourlyController.text) ?? 0,
        skills: derivedSkills.join(', '),
        roleDistribution: _roleDistributions,
        groupName: _nameController.text,
        image: 'https://placehold.co/600x400?text=Workers',
      );

      ProviderManager().addProvider(newProvider);
      _completeSubmission();
    } catch (e) {
      _showError('Failed to save worker group to server: $e');
    }
  }



  Future<void> _submitEquipment() async {
    setState(() => _fieldErrors.clear());
    bool hasError = false;

    if (_selectedEquipmentType == null) {
      _fieldErrors['category'] = 'Select category';
      hasError = true;
    }
    if (_brandModelController.text.isEmpty) {
      _fieldErrors['brandModel'] = 'Enter brand/model';
      hasError = true;
    }
    if (_priceController.text.isEmpty) {
      _fieldErrors['price'] = 'Enter price';
      hasError = true;
    }

    if (hasError) {
      _showError(AppLocalizations.of(context)!.fillRequiredFields);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final ownerId = prefs.getString('user_id') ?? 'unknown_owner';
      double parsedPrice = double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

      final Map<String, dynamic> equipmentData = {
        'ownerId': ownerId,
        'category': _selectedEquipmentType,
        'brandModel': _brandModelController.text,
        'conditionStatus': _condition,
        'pricePerHour': parsedPrice,
        'operatorAvailable': _operatorAvailable,
        'location': _locationController.text,
        'houseNo': _houseNoController.text,
        'street': _streetController.text,
        'village': _villageController.text,
        'district': _districtController.text,
        'state': _stateController.text,
        'country': _countryController.text,
        'pincode': _pincodeController.text,
        'houseNo': _houseNoController.text,
        'street': _streetController.text,
        'village': _villageController.text,
        'district': _districtController.text,
        'state': _stateController.text,
        'country': _countryController.text,
        'pincode': _pincodeController.text,
        'houseNo': _houseNoController.text,
        'street': _streetController.text,
        'village': _villageController.text,
        'district': _districtController.text,
        'state': _stateController.text,
        'country': _countryController.text,
        'pincode': _pincodeController.text,
        'houseNo': _houseNoController.text,
        'street': _streetController.text,
        'village': _villageController.text,
        'district': _districtController.text,
        'state': _stateController.text,
        'country': _countryController.text,
        'pincode': _pincodeController.text,
        'houseNo': _houseNoController.text,
        'street': _streetController.text,
        'village': _villageController.text,
        'district': _districtController.text,
        'state': _stateController.text,
        'country': _countryController.text,
        'pincode': _pincodeController.text,
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
        'isAvailable': true,
        'rating': 5.0,
        'approvalStatus': 'Pending',
        'imageUrl': await _uploadSelectedImage() ?? 'https://placehold.co/600x400?text=Equipment',
      };

      await ApiService().addEquipment(equipmentData);

      final newProvider = EquipmentListing(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.isNotEmpty ? _nameController.text : 'Owner', // Owner name usually
        serviceName: _selectedEquipmentType!, // 'Tractors', 'Harvesters'
        distance: '1 km',
        rating: 5.0,
        approvalStatus: 'Pending',
        location: _locationController.text,
        brandModel: _brandModelController.text,
        price: _priceController.text,
        operatorAvailable: _operatorAvailable,
        condition: _condition,
        yearOfManufacture: _yearController.text.isNotEmpty ? _yearController.text : null,
        image: 'https://placehold.co/600x400?text=Equipment',
      );

      ProviderManager().addProvider(newProvider);
      _completeSubmission();
    } catch (e) {
      _showError('Failed to save equipment to server: $e');
    }
  }

  void _completeSubmission() {
    _upgradeUserToProvider();
    Navigator.pop(context);
    UiUtils.showCustomAlert(
      context, 
      AppLocalizations.of(context)!.listingUploaded,
      isError: false
    );
  }

  void _showError(String message) {
    UiUtils.showCenteredToast(context, message, isError: true);
  }

  Future<void> _upgradeUserToProvider() async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.setString('user_role', 'Owner');
  }

  String _getScreenTitle() {
    if (widget.category == 'Transport') return AppLocalizations.of(context)!.addVehicle;
    if (widget.category == 'Equipment') return AppLocalizations.of(context)!.addEquipment;
    if (widget.category == 'Farm Workers') return AppLocalizations.of(context)!.addGroup;
    return '${AppLocalizations.of(context)!.addListing} ${widget.category}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        title: Text(_getScreenTitle(), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1B5E20))),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
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
            // Photo Upload Section Card
            _buildSectionCard(
              title: AppLocalizations.of(context)!.addPhotos,
              icon: Icons.camera_alt_rounded,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE8F5E9), width: 2),
                  ),
                  child: _selectedImage != null 
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          kIsWeb 
                            ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                            : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                          Container(
                             color: Colors.black38,
                             alignment: Alignment.center,
                             child: const Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Icon(Icons.edit_rounded, color: Colors.white, size: 32),
                                 SizedBox(height: 8),
                                 Text('Change Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                               ],
                             ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Container(
                             padding: const EdgeInsets.all(16),
                             decoration: BoxDecoration(
                               color: Colors.white,
                               shape: BoxShape.circle,
                               boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10)],
                             ),
                             child: const Icon(Icons.add_a_photo_rounded, size: 40, color: Color(0xFF00AA55)),
                           ),
                           const SizedBox(height: 16),
                           Text(
                             'Click to upload high quality photos', 
                             style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500, fontSize: 13),
                           ),
                        ],
                      ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (widget.category == 'Farm Workers') _buildFarmWorkerForm(),
            if (widget.category == 'Transport') _buildTransportForm(),
            if (widget.category == 'Equipment') _buildEquipmentForm(),
            if (!['Farm Workers', 'Transport', 'Equipment'].contains(widget.category)) _buildServicesForm(),

            if (!(widget.category == 'Farm Workers' || (widget.category == 'Services' && _selectedServiceType == 'Farm Workers'))) ...[
               _buildSectionCard(
                 title: 'Extra Details', 
                 icon: Icons.info_outline_rounded,
                 child: Column(
                   children: [
                      _buildTextField(
                        AppLocalizations.of(context)!.locationLabel, 
                        _locationController, 
                        'e.g. Rampur, Nagpur',
                        icon: Icons.location_on_rounded,
                        suffixIcon: _isFetchingLocation 
                          ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                          : IconButton(
                              icon: const Icon(Icons.my_location_rounded, color: Color(0xFF00AA55)),
                              onPressed: _fetchCurrentLocation,
                            ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('H.No', _houseNoController, 'e.g. 123', icon: Icons.home_rounded)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Street', _streetController, 'Street Name', icon: Icons.map_rounded)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Village', _villageController, 'Village Name', icon: Icons.location_city_rounded)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('District', _districtController, 'District Name')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('State', _stateController, 'State Name')),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Pincode', _pincodeController, '6-digit code', keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField('Country', _countryController, 'Country Name'),
                      const SizedBox(height: 20),
                      const SizedBox(height: 20),
                      _buildTextField(
                        AppLocalizations.of(context)!.descriptionLabel, 
                        _descriptionController, 
                        'Any extra info...', 
                        icon: Icons.description_rounded,
                        maxLines: 3,
                      ),
                   ],
                 ),
               ),
            ],

            const SizedBox(height: 40),
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
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AA55),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: _isSubmitting 
                  ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)))
                  : Text(AppLocalizations.of(context)!.submitListing, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- FORMS ---

  Widget _buildFarmWorkerForm() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          title: 'Group Identity',
          icon: Icons.groups_rounded,
          child: _buildTextField(
            'Group Name / Leader Name', 
            _nameController, 
            l10n.groupNameHint, 
            errorKey: 'name',
            icon: Icons.badge_rounded,
          ),
        ),
        
        _buildSectionCard(
          title: 'Staffing & Wages',
          icon: Icons.payments_rounded,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildTextField(l10n.maleWorkers, _maleCountController, 'Count', keyboardType: TextInputType.number, errorKey: 'maleCount', icon: Icons.male_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(l10n.priceMale, _malePriceController, l10n.dailyWage, keyboardType: TextInputType.number, errorKey: 'malePrice', icon: Icons.currency_rupee_rounded)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                 children: [
                  Expanded(child: _buildTextField(l10n.femaleWorkers, _femaleCountController, 'Count', keyboardType: TextInputType.number, errorKey: 'femaleCount', icon: Icons.female_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(l10n.priceFemale, _femalePriceController, l10n.dailyWage, keyboardType: TextInputType.number, errorKey: 'femalePrice', icon: Icons.currency_rupee_rounded)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildTextField('Hourly Rate (Male)', _malePriceHourlyController, 'e.g. 50/hr', keyboardType: TextInputType.number, errorKey: 'malePriceHourly')),
                  const SizedBox(width: 16),
                   Expanded(child: _buildTextField('Hourly Rate (Female)', _femalePriceHourlyController, 'e.g. 40/hr', keyboardType: TextInputType.number, errorKey: 'femalePriceHourly')),
                ],
              ),
            ],
          ),
        ),

        _buildSectionCard(
          title: 'Role Allocation',
          icon: Icons.assignment_ind_rounded,
          child: _buildRoleDistributionForm(),
        ),
      ],
    );
  }


  Widget _buildTransportForm() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          title: l10n.vehicleDetails,
          icon: Icons.local_shipping_rounded,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedTransportType,
                decoration: _inputDecoration(l10n.vehicleType, icon: Icons.category_rounded),
                items: _transportTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedTransportType = v;
                    _selectedVehicleMake = null;
                    _selectedVehicleModel = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // MAKE & MODEL SELECTION
              Builder(
                builder: (context) {
                   List<String> makes = [];
                   if (_selectedTransportType != null) {
                     makes = VehicleData.getMakes(_selectedTransportType!);
                   }
                   
                   List<String> models = [];
                   if (_selectedTransportType != null && _selectedVehicleMake != null) {
                     models = VehicleData.getModels(_selectedTransportType!, _selectedVehicleMake!);
                   }
                   
                   return Column(
                     children: [
                       if (makes.isNotEmpty) ...[
                          DropdownButtonFormField<String>(
                            value: _selectedVehicleMake,
                            decoration: _inputDecoration('Select Make', icon: Icons.branding_watermark_rounded),
                            items: makes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedVehicleMake = v;
                                _selectedVehicleModel = null;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                       ],
                       if (models.isNotEmpty) ...[
                          DropdownButtonFormField<String>(
                            value: _selectedVehicleModel,
                            decoration: _inputDecoration('Select Model', icon: Icons.model_training_rounded),
                            items: models.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedVehicleModel = v;
                                if (v != 'Other' && _selectedVehicleMake != null) {
                                   _nameController.text = "${_selectedVehicleMake} $v";
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                       ],
                     ],
                   );
                }
              ),

              _buildTextField('Vehicle Name / Title', _nameController, l10n.vehicleNameHint, errorKey: 'name', icon: Icons.title_rounded),
              const SizedBox(height: 16),
              _buildTextField(l10n.vehicleNumber, _vehicleNumberController, 'e.g. MH 40 AB 1234', errorKey: 'number', icon: Icons.numbers_rounded),
              const SizedBox(height: 16),
              _buildTextField(l10n.loadCapacity, _capacityController, 'e.g. 1.5 Ton', errorKey: 'capacity', icon: Icons.line_weight_rounded),
              const SizedBox(height: 16),
              _buildTextField(l10n.serviceArea, _serviceAreaController, 'e.g. Within 50km', icon: Icons.map_rounded),
            ],
          ),
        ),

        _buildSectionCard(
          title: 'Pricing & Options',
          icon: Icons.sell_rounded,
          child: Column(
            children: [
              _buildTextField(l10n.priceLabel, _priceController, 'e.g. ₹20/km or ₹1000/trip', keyboardType: TextInputType.text, errorKey: 'price', icon: Icons.payments_rounded),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: Text(l10n.driverIncluded, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                value: _driverIncluded,
                onChanged: (v) => setState(() => _driverIncluded = v!),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF00AA55),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submitTransport() async {
    setState(() => _fieldErrors.clear());
    bool hasError = false;

    if (_selectedTransportType == null) {
      _fieldErrors['type'] = 'Select vehicle type';
      hasError = true;
    }
    if (_nameController.text.isEmpty) {
      _fieldErrors['name'] = 'Enter vehicle name';
      hasError = true;
    }
    if (_priceController.text.isEmpty) {
      _fieldErrors['price'] = 'Enter price';
      hasError = true;
    }

    if (hasError) {
      _showError(AppLocalizations.of(context)!.fillRequiredFields);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userRole = prefs.getString('user_role');

      if (userId == null) {
        _showError('User ID not found. Please log in again.');
        return;
      }

      if (userRole != 'Owner' && userRole != 'Provider') { // Allowing Provider just in case
        _showError('Only an Owner can upload vehicles.');
        return;
      }

      // Parse price to double e.g., '1500 per trip' -> 1500.0
      double parsedPrice = 0.0;
      try {
        parsedPrice = double.parse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
      } catch (e) {
         _showError('Please enter a valid numeric price');
         return;
      }

      final apiService = ApiService();
      await apiService.addVehicle({
        'ownerId': userId,
        'vehicleType': _selectedTransportType,
        'vehicleNumber': _vehicleNumberController.text.isNotEmpty ? _vehicleNumberController.text : null,
        'loadCapacity': _capacityController.text.isNotEmpty ? _capacityController.text : 'Unknown',
        'pricePerKmOrTrip': parsedPrice,
        'driverIncluded': _driverIncluded,
        'serviceArea': _serviceAreaController.text.isNotEmpty ? _serviceAreaController.text : null,
        'location': _locationController.text.isNotEmpty ? _locationController.text : 'Unknown',
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
        'isAvailable': true,
        'rating': 5.0, // Default for new
        'approvalStatus': 'Pending',
        'imageUrl': await _uploadSelectedImage() ?? 'https://placehold.co/600x400?text=Vehicle', // Mock image
      });

      _completeSubmission();
    } catch (e) {
      _showError('Failed to upload vehicle: $e');
    }
  }

  Future<void> _submitService() async {
    setState(() => _fieldErrors.clear());
    bool hasError = false;

    if (_nameController.text.isEmpty) {
      _fieldErrors['name'] = 'Enter provider name';
      hasError = true;
    }
    if (_priceController.text.isEmpty) {
      _fieldErrors['price'] = 'Enter price';
      hasError = true;
    }

    if (hasError) {
       _showError('Please provide service details');
       return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final ownerId = prefs.getString('user_id') ?? 'unknown_owner';
      double parsedPrice = double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

      final Map<String, dynamic> serviceData = {
        'ownerId': ownerId,
        'serviceType': _selectedServiceType ?? widget.category,
        'businessName': _nameController.text,
        'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : 'No description provided',
        'equipmentUsed': _equipmentUsedController.text.isNotEmpty ? _equipmentUsedController.text : 'Standard Equipment',
        'priceRate': parsedPrice,
        'operatorIncluded': _operatorIncludedService,
        'location': _locationController.text.isNotEmpty ? _locationController.text : 'Local',
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
        'isAvailable': true,
        'rating': 5.0,
        'approvalStatus': 'Pending',
        'imageUrl': await _uploadSelectedImage() ?? 'https://placehold.co/600x400?text=Service',
      };

      await ApiService().addService(serviceData);

      final newProvider = ServiceListing(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text, // Provider Name
        serviceName: _selectedServiceType ?? widget.category, // e.g. 'Ploughing' passed from home screen or selected
        distance: '1 km',
        rating: 5.0,
        approvalStatus: 'Pending',
        location: _locationController.text,
        equipmentUsed: _equipmentUsedController.text.isNotEmpty ? _equipmentUsedController.text : 'Standard Equipment',
        price: _priceController.text,
        operatorIncluded: _operatorIncludedService,
        jobsCompleted: 0,
        isAvailable: true,
        image: 'https://placehold.co/600x400?text=Service', 
      );

      ProviderManager().addProvider(newProvider);
      _completeSubmission();
    } catch (e) {
      _showError('Failed to save service to server: $e');
    }
  }

  // ... (existing _submitEquipment ...)

  Widget _buildServicesForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          title: 'Service Scope',
          icon: Icons.work_rounded,
          child: Column(
            children: [
              // If category is generic 'Services', show dropdown
              if (widget.category == 'Services') 
                 DropdownButtonFormField<String>(
                   value: null, 
                   decoration: _inputDecoration('Select Service Type', icon: Icons.category_rounded),
                   items: _serviceCategories.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                   onChanged: (val) {
                      setState(() => _selectedServiceType = val);
                   },
                 )
              else
                 Row(
                   children: [
                     const Icon(Icons.check_circle_rounded, color: Color(0xFF00AA55), size: 18),
                     const SizedBox(width: 8),
                     Text('Category: ${widget.category}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20))),
                   ],
                 ), 
              
              // If Farm Workers is selected, show Farm Workers form instead of generic service form
              if (_selectedServiceType == 'Farm Workers') ...[
                 const SizedBox(height: 24),
                 _buildFarmWorkerForm(),
              ] else ...[
                 const SizedBox(height: 20),
                 _buildTextField('Provider / Business Name', _nameController, 'e.g. Ramesh Services', errorKey: 'name', icon: Icons.business_rounded),
                 const SizedBox(height: 20),
                 _buildTextField('Equipment Used', _equipmentUsedController, 'e.g. John Deere Tractor + Plough', icon: Icons.handyman_rounded),
              ],
            ],
          ),
        ),

        if (_selectedServiceType != 'Farm Workers')
          _buildSectionCard(
            title: 'Pricing & Details',
            icon: Icons.sell_rounded,
            child: Column(
              children: [
                _buildTextField(
                  'Your Rate', 
                  _priceController, 
                  (_selectedServiceType == 'Electricians' || _selectedServiceType == 'Vet Care' || _selectedServiceType == 'Mechanics') 
                    ? 'e.g. ₹200 / visit' 
                    : (_selectedServiceType == 'Harvesting' || _selectedServiceType == 'Drone Spraying' || widget.category == 'Harvesting')
                      ? 'e.g. ₹2000 / hour'
                      : 'e.g. ₹1200 / acre', 
                  errorKey: 'price',
                  icon: Icons.payments_rounded,
                ),
                
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Operator Included?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  value: _operatorIncludedService,
                  onChanged: (v) => setState(() => _operatorIncludedService = v),
                  activeColor: const Color(0xFF00AA55),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEquipmentForm() {
    final l10n = AppLocalizations.of(context)!;
    List<String> makes = [];
    if (_selectedEquipmentType != null) {
      makes = VehicleData.getMakes(_selectedEquipmentType!);
    }

    List<String> models = [];
    if (_selectedEquipmentType != null && _selectedMake != null) {
      models = VehicleData.getModels(_selectedEquipmentType!, _selectedMake!);
    }

    bool showManualMake = makes.isEmpty || _selectedMake == 'Other';
    bool showManualModel = models.isEmpty || _selectedModel == 'Other';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          title: l10n.equipmentInfo,
          icon: Icons.settings_rounded,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedEquipmentType,
                decoration: _inputDecoration('Category', icon: Icons.category_rounded),
                items: _equipmentCategories.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedEquipmentType = v;
                    _selectedMake = null;
                    _selectedModel = null;
                    _brandModelController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildTextField('Owner / Business Name', _nameController, l10n.ownerNameHint, icon: Icons.person_rounded),
              const SizedBox(height: 20),
              
              // MAKE SELECTION
              if (makes.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: _selectedMake,
                  decoration: _inputDecoration('Select Make', icon: Icons.branding_watermark_rounded),
                  items: makes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedMake = v;
                      _selectedModel = null;
                      _brandModelController.clear();
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // MODEL SELECTION
              if (models.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: _selectedModel,
                  decoration: _inputDecoration('Select Model', icon: Icons.model_training_rounded),
                  items: models.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedModel = v;
                      if (v != 'Other') {
                         _brandModelController.text = "${_selectedMake} $v"; 
                      } else {
                         _brandModelController.clear();
                      }
                    });
                  },
                ),
                 const SizedBox(height: 16),
              ],
              
              // Manual Entry Fallback
              if (showManualMake || showManualModel) 
                 _buildTextField(l10n.brandModel, _brandModelController, 'e.g. John Deere 5310', icon: Icons.edit_note_rounded),

              if (showManualMake || showManualModel) 
                 const SizedBox(height: 20),

              _buildTextField(l10n.yearManufacture, _yearController, 'e.g. 2021', keyboardType: TextInputType.number, icon: Icons.calendar_today_rounded),
            ],
          ),
        ),

        _buildSectionCard(
          title: 'Rental Terms & Condition',
          icon: Icons.fact_check_rounded,
          child: Column(
            children: [
              _buildTextField(l10n.rentalPrice, _priceController, 'e.g. ₹500 / hour', icon: Icons.payments_rounded),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _condition,
                decoration: _inputDecoration(l10n.condition, icon: Icons.info_outline_rounded),
                items: _conditions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _condition = v!),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(l10n.operatorAvailable, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(l10n.operatorAvailableSubtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                value: _operatorAvailable,
                onChanged: (v) => setState(() => _operatorAvailable = v),
                activeColor: const Color(0xFF00AA55),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- HELPERS ---

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
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

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text, String? errorKey, Widget? suffixIcon, IconData? icon}) {
    bool hasError = errorKey != null && _fieldErrors.containsKey(errorKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w700, 
            color: hasError ? Colors.red : const Color(0xFF2C3E50),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: (_) {
            if (hasError) setState(() => _fieldErrors.remove(errorKey));
          },
          decoration: _inputDecoration(hint, isError: hasError, icon: icon).copyWith(suffixIcon: suffixIcon),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        if (hasError && _fieldErrors[errorKey] != null)
           Padding(
             padding: const EdgeInsets.only(top: 6.0, left: 4),
             child: Text(_fieldErrors[errorKey]!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500)),
           ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, {bool isError = false, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: const Color(0xFF00AA55)) : null,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
  // Multi-select skills
  List<String> _selectedRoleSkills = [];

  void _addRoleDistribution() {
    final count = _roleCountController.text.trim();
    if (count.isNotEmpty && _selectedRoleSkills.isNotEmpty) {
      int newCount = int.tryParse(count) ?? 0;
      if (newCount <= 0) {
        UiUtils.showCenteredToast(context, 'Please enter a valid count greater than 0', isError: true);
        return;
      }
      
      int currentAllocated = 0;
      for (String roleStr in _roleDistributions) {
        final parts = roleStr.split('-');
        if (parts.length == 2) {
          final countAndGender = parts[0].trim().split(' ');
          if (countAndGender.length >= 2 && countAndGender[1] == _roleGender) {
            currentAllocated += int.tryParse(countAndGender[0]) ?? 0;
          }
        }
      }

      int maxAllowed = _roleGender == 'Male' 
          ? (int.tryParse(_maleCountController.text) ?? 0)
          : (int.tryParse(_femaleCountController.text) ?? 0);

      if (currentAllocated + newCount > maxAllowed) {
        UiUtils.showCenteredToast(context, 'Cannot allocate $newCount $_roleGender workers. Max allowed is $maxAllowed, already allocated is $currentAllocated.', isError: true);
        return;
      }

      setState(() {
        _roleDistributions.add('$count $_roleGender - ${_selectedRoleSkills.join(", ")}');
        _roleCountController.clear();
        _selectedRoleSkills = []; // Reset list
      });
    } else {
       UiUtils.showCenteredToast(context, 'Please enter count and select at least one skill', isError: true);
    }
  }

  Future<void> _showMultiSelectDialog() async {
    final List<String> tempSelectedSkills = List.from(_selectedRoleSkills);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Select Skills'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: _farmSkills.map((skill) {
                    return CheckboxListTile(
                      value: tempSelectedSkills.contains(skill),
                      title: Text(skill),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF00AA55),
                      onChanged: (bool? checked) {
                        setStateDialog(() {
                          if (checked == true) {
                            tempSelectedSkills.add(skill);
                          } else {
                            tempSelectedSkills.remove(skill);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedRoleSkills = tempSelectedSkills;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Done', style: TextStyle(color: Color(0xFF00AA55))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRoleDistributionForm() {
      return Column(
          children: [
                const SizedBox(height: 20),
                _buildSectionTitle('Role Distribution (Optional)'),
                const SizedBox(height: 8),
                Text('Specify who does what (e.g. 5 Men - Sowing)', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 12),
                
                Row(
                children: [
                    SizedBox(
                    width: 80,
                    child: _buildTextField('Count', _roleCountController, 'Num', keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                    width: 100,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        const Text('Gender', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                            value: _roleGender,
                            decoration: _inputDecoration('').copyWith(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            ),
                            items: ['Male', 'Female'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14)))).toList(),
                            onChanged: (v) => setState(() => _roleGender = v!),
                        ),
                        ],
                    ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           const Text('Task', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                           const SizedBox(height: 8),
                           InkWell(
                             onTap: _showMultiSelectDialog,
                             child: InputDecorator(
                               decoration: _inputDecoration('Select Tasks').copyWith(
                                 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                               ),
                               child: Text(
                                 _selectedRoleSkills.isEmpty ? 'Select Skills' : _selectedRoleSkills.join(', '),
                                 style: TextStyle(
                                   color: _selectedRoleSkills.isEmpty ? Colors.grey[400] : Colors.black87,
                                   fontSize: 14,
                                 ),
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                           ),
                        ],
                      ),
                    ),
                ],
                ),
                const SizedBox(height: 8),
                Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                    onPressed: _addRoleDistribution,
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text('Add', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AA55),
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                ),
                ),

                const SizedBox(height: 12),
                if (_roleDistributions.isNotEmpty)
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _roleDistributions.map((item) {
                        return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6.0),
                              child: Icon(Icons.circle, size: 8, color: Colors.green),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item, style: const TextStyle(fontSize: 14))),
                            InkWell(
                                onTap: () {
                                setState(() {
                                    _roleDistributions.remove(item);
                                });
                                },
                                child: const Icon(Icons.close, size: 16, color: Colors.red),
                            )
                            ],
                        ),
                        );
                    }).toList(),
                    ),
                ),
          ],
      );
  }
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Color(0xFF1B5E20),
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
