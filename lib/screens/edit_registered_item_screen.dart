import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io' show File;
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../utils/ui_utils.dart';

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
  late TextEditingController _locationController;

  // Specifics
  late TextEditingController _secondaryController; // e.g., brandModel, type, groupName
  bool _boolFlag = false; // operatorAvailable, driverIncluded
  String? _condition; // Equipment
  late TextEditingController _capacityController; // Vehicle
  bool _isFetchingLocation = false;

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
    _locationController = TextEditingController(text: widget.itemData['location']?.toString() ?? '');
    _secondaryController = TextEditingController();
    _capacityController = TextEditingController();
    _imageUrl = widget.itemData['imageUrl']?.toString();

    if (widget.category == 'Vehicle') {
      _nameController.text = widget.itemData['vehicleNumber']?.toString() ?? '';
      _priceController.text = widget.itemData['pricePerKmOrTrip']?.toString() ?? '';
      _secondaryController.text = widget.itemData['vehicleType']?.toString() ?? '';
      _capacityController.text = widget.itemData['loadCapacity']?.toString() ?? '';
      _boolFlag = widget.itemData['driverIncluded'] ?? false;
    } else if (widget.category == 'Equipment') {
      _nameController.text = widget.itemData['brandModel']?.toString() ?? '';
      _priceController.text = widget.itemData['pricePerHour']?.toString() ?? '';
      _secondaryController.text = widget.itemData['category']?.toString() ?? '';
      _boolFlag = widget.itemData['operatorAvailable'] ?? false;
      _condition = widget.itemData['conditionStatus']?.toString() ?? 'Good';
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
    _locationController.dispose();
    _secondaryController.dispose();
    _capacityController.dispose();
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

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        String village = place.subLocality ?? place.locality ?? 'Unknown Village';
        String district = place.subAdministrativeArea ?? place.administrativeArea ?? 'Unknown District';
        
        setState(() {
           _locationController.text = "$village, $district";
        });
        
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
        updatedData['vehicleType'] = _secondaryController.text;
        updatedData['loadCapacity'] = _capacityController.text;
        updatedData['driverIncluded'] = _boolFlag;
        updatedData['location'] = _locationController.text;
        await _apiService.updateVehicle(widget.itemData['vehicleId'], updatedData);
      } else if (widget.category == 'Equipment') {
        updatedData['brandModel'] = _nameController.text;
        updatedData['pricePerHour'] = double.tryParse(_priceController.text) ?? 0.0;
        updatedData['category'] = _secondaryController.text;
        updatedData['operatorAvailable'] = _boolFlag;
        updatedData['conditionStatus'] = _condition;
        updatedData['location'] = _locationController.text;
        await _apiService.updateEquipment(widget.itemData['equipmentId'], updatedData);
      } else if (widget.category == 'Service') {
        updatedData['businessName'] = _nameController.text;
        updatedData['priceRate'] = double.tryParse(_priceController.text) ?? 0.0;
        updatedData['serviceType'] = _secondaryController.text;
        updatedData['operatorIncluded'] = _boolFlag;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.category}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  image: _imageFile != null
                      ? (kIsWeb 
                          ? DecorationImage(image: NetworkImage(_imageFile!.path), fit: BoxFit.cover)
                          : DecorationImage(image: FileImage(File(_imageFile!.path)), fit: BoxFit.cover))
                      : (_imageUrl != null && _imageUrl!.isNotEmpty
                          ? DecorationImage(image: NetworkImage(ApiConfig.getFullImageUrl(_imageUrl)), fit: BoxFit.cover)
                          : null),
                ),
                child: (_imageFile == null && (_imageUrl == null || _imageUrl!.isEmpty))
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text('Add Photo', style: TextStyle(color: Colors.grey[600])),
                        ],
                      )
                    : Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 20),
                        ),
                      ),
              ),
            ),
            if (widget.category == 'Vehicle') ...[
              _buildTextField('Vehicle Type', _secondaryController),
              _buildTextField('Vehicle Number', _nameController),
              _buildTextField('Load Capacity', _capacityController),
              _buildTextField('Price Per Km/Trip', _priceController, keyboardType: TextInputType.number),
              SwitchListTile(
                title: const Text('Driver Included'),
                value: _boolFlag,
                onChanged: (v) => setState(() => _boolFlag = v),
              ),
            ] else if (widget.category == 'Equipment') ...[
              _buildTextField('Category', _secondaryController),
              _buildTextField('Brand & Model', _nameController),
              _buildTextField('Price Per Hour', _priceController, keyboardType: TextInputType.number),
              DropdownButtonFormField<String>(
                value: _condition,
                decoration: const InputDecoration(labelText: 'Condition'),
                items: ['New', 'Good', 'Average', 'Poor'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _condition = v),
              ),
              SwitchListTile(
                title: const Text('Operator Available'),
                value: _boolFlag,
                onChanged: (v) => setState(() => _boolFlag = v),
              ),
            ] else if (widget.category == 'Service') ...[
              _buildTextField('Service Type', _secondaryController),
              _buildTextField('Business Name', _nameController),
              _buildTextField('Price / Rate', _priceController, keyboardType: TextInputType.number),
              SwitchListTile(
                title: const Text('Operator Included'),
                value: _boolFlag,
                onChanged: (v) => setState(() => _boolFlag = v),
              ),
            ] else if (widget.category == 'WorkerGroup') ...[
              _buildTextField('Group Name', _nameController),
              _buildTextField('Price Per Male', _priceController, keyboardType: TextInputType.number),
              _buildTextField('Price Per Female', _secondaryController, keyboardType: TextInputType.number),
            ],

            const SizedBox(height: 16),
            _buildTextField(
              'Location', 
              _locationController,
              suffixIcon: _isFetchingLocation 
                ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(
                    icon: const Icon(Icons.my_location, color: Color(0xFF00AA55)),
                    onPressed: _fetchCurrentLocation,
                  ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AA55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text, Widget? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
