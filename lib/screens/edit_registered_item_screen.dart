import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:agriculture/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/location_helper.dart';
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

      
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // Use helper for cross-platform reverse geocoding
      final addressData = await LocationHelper.getAddressFromCoordinates(position.latitude, position.longitude);
      final String village = addressData['village']!;
      final String district = addressData['district']!;
      
      if (mounted) {
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
                            : Image.network(ApiConfig.getFullImageUrl(_imageUrl), fit: BoxFit.cover)
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
                    _buildTextField('Category', _secondaryController, Icons.category_rounded, hint: 'e.g., Harvester, Tools'),
                    const SizedBox(height: 20),
                    _buildTextField('Brand & Model', _nameController, Icons.branding_watermark_outlined, hint: 'e.g., Mahindra 575 DI'),
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
                    _buildTextField('Price Per Km/Trip', _priceController, Icons.currency_rupee_rounded, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    _buildSwitchTile('Driver Included', _boolFlag, (v) => setState(() => _boolFlag = v)),
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
                    _buildSwitchTile('Operator Available', _boolFlag, (v) => setState(() => _boolFlag = v)),
                  ] else if (widget.category == 'Service') ...[
                    _buildTextField('Price / Rate', _priceController, Icons.currency_rupee_rounded, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    _buildSwitchTile('Operator Included', _boolFlag, (v) => setState(() => _boolFlag = v)),
                  ] else if (widget.category == 'WorkerGroup') ...[
                    _buildTextField('Price Per Male', _priceController, Icons.man_rounded, keyboardType: TextInputType.number, hint: 'Rate for male workers'),
                    const SizedBox(height: 20),
                    _buildTextField('Price Per Female', _secondaryController, Icons.woman_rounded, keyboardType: TextInputType.number, hint: 'Rate for female workers'),
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
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
              children: [
                Icon(icon, size: 20, color: const Color(0xFF00AA55)),
                const SizedBox(width: 12),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF1B5E20).withOpacity(0.6), letterSpacing: 1.2),
                ),
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

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text, Widget? suffixIcon, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
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
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF2C3E50)),
            decoration: InputDecoration(
              hintText: hint,
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
