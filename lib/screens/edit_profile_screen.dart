import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../services/geocoding_service.dart';
import 'dart:io';
import '../config/api_config.dart';
import '../utils/ui_utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  String? _userId;
  String? _profileImageUrl;
  XFile? _selectedImage;
  bool _isLoading = true;
  bool _isUploading = false;
  double? _detectedLat;
  double? _detectedLng;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
      _nameController.text = prefs.getString('user_name') ?? 'User';
      _villageController.text = prefs.getString('user_village') ?? '';
      _districtController.text = prefs.getString('user_district') ?? '';
      _phoneController.text = prefs.getString('user_mobile') ?? '+919188528855';
      _houseNoController.text = prefs.getString('user_houseNo') ?? '';
      _streetController.text = prefs.getString('user_street') ?? '';
      _stateController.text = prefs.getString('user_state') ?? '';
      _countryController.text = prefs.getString('user_country') ?? '';
      _pincodeController.text = prefs.getString('user_pincode') ?? ''; 
      _profileImageUrl = prefs.getString('user_profile_image');
      _detectedLat = prefs.getDouble('user_latitude');
      _detectedLng = prefs.getDouble('user_longitude');
      _isLoading = false;
    });
  }

  Future<void> _saveProfileData() async {
    setState(() => _isLoading = true);
    
    try {
      final apiService = ApiService();
      if (_userId == null) {
        final phone = _phoneController.text;
        // The backend expects the exact number as stored.
        // We ensure we only search by the numeric part or encode properly.
        final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
        final encodedPhone = Uri.encodeComponent(cleanPhone);
        
        try {
          final user = await apiService.getUserByPhone(encodedPhone);
          if (user['userId'] != null) {
            _userId = user['userId'].toString();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_id', _userId!);
          } else {
             throw Exception('User fetched but userId is still null');
          }
        } catch (e) {
             throw Exception('Failed to fetch user by phone ($cleanPhone): $e');
        }
      }

      if (_userId != null) {
        String? finalImageUrl = _profileImageUrl;
        
        // Upload image if a new one was selected
        if (_selectedImage != null) {
          setState(() => _isUploading = true);
          try {
            final uploadResponse = await apiService.uploadImage(_selectedImage!);
            finalImageUrl = uploadResponse['url'];
          } catch (e) {
            debugPrint("Error uploading image: $e");
            // Optionally handle upload error, but we'll try to proceed with other changes
          } finally {
            setState(() => _isUploading = false);
          }
        }

        // Automatic Geocoding from Address (Cross-platform support)
        double? lat, lng;
        try {
          String fullAddress = "${_houseNoController.text}, ${_streetController.text}, ${_villageController.text}, ${_districtController.text}, ${_stateController.text}, ${_countryController.text}, ${_pincodeController.text}";
          
          // Try local geocoding first (if supported)
          try {
            if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
               List<geo.Location> locations = await geo.locationFromAddress(fullAddress);
               if (locations.isNotEmpty) {
                 lat = locations.first.latitude;
                 lng = locations.first.longitude;
               }
            }
          } catch (e) {
            debugPrint("Local geocoding not supported or failed: $e");
          }

          
          // Fallback to OpenStreetMap for Windows/Web or if local fails
          if (lat == null || lng == null) {
            String fallbackAddress = "${_villageController.text}, ${_districtController.text}, ${_stateController.text}, ${_countryController.text}";
            final coords = await GeocodingService.getCoordinates(fullAddress, fallbackAddress: fallbackAddress);
            if (coords != null) {
              lat = coords['latitude'];
              lng = coords['longitude'];
            }
          }


          if (lat != null && lng != null) {
            debugPrint("Geocoding success: $lat, $lng");
            setState(() {
              _detectedLat = lat;
              _detectedLng = lng;
            });
          }
        } catch (e) {
          debugPrint("All geocoding methods failed: $e");
        }

        await apiService.updateUser(_userId!, {
          'fullName': _nameController.text,
          'village': _villageController.text,
          'houseNo': _houseNoController.text,
          'street': _streetController.text,
          'district': _districtController.text,
          'state': _stateController.text,
          'country': _countryController.text,
          'pincode': _pincodeController.text,
          'profileImageUrl': finalImageUrl,
          'latitude': lat,
          'longitude': lng,
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_village', _villageController.text);
        await prefs.setString('user_district', _districtController.text);
        await prefs.setString('user_houseNo', _houseNoController.text);
        await prefs.setString('user_street', _streetController.text);
        await prefs.setString('user_state', _stateController.text);
        await prefs.setString('user_country', _countryController.text);
        await prefs.setString('user_pincode', _pincodeController.text);
        if (finalImageUrl != null) {
          await prefs.setString('user_profile_image', finalImageUrl);
        }

        if (mounted) {
          setState(() => _isLoading = false);
          UiUtils.showCenteredToast(context, 'Profile updated successfully!');
          Navigator.pop(context, true); // Return true to indicate update
        }
      } else {
        throw Exception('Could not find user ID to update back-end.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UiUtils.showCustomAlert(context, 'Failed to update profile: $e', isError: true);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _phoneController.dispose();
    _houseNoController.dispose();
    _streetController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7F2),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00AA55))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B5E20), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Color(0xFF1B5E20), fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF00AA55).withOpacity(0.2), width: 3),
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFF00AA55).withOpacity(0.1), blurRadius: 20),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Container(
                                    color: const Color(0xFFF5F7F2),
                                    child: _selectedImage != null 
                                      ? (kIsWeb 
                                          ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                                          : Image.file(File(_selectedImage!.path), fit: BoxFit.cover))
                                      : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                        ? Image.network(ApiConfig.getFullImageUrl(_profileImageUrl), fit: BoxFit.cover)
                                        : const Icon(Icons.person_rounded, size: 60, color: Color(0xFFB0BEC5))),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00AA55),
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: const Color(0xFF00AA55).withOpacity(0.4), blurRadius: 10)],
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                                ),
                              ),
                              if (_isUploading)
                                const Positioned.fill(
                                  child: Center(
                                    child: CircularProgressIndicator(color: Color(0xFF00AA55)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Upload Profile Photo',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap the icon to change your photo',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF00AA55)),
                            const SizedBox(width: 12),
                            Text(
                              'PERSONAL INFO',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF1B5E20).withOpacity(0.6), letterSpacing: 1.2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(_nameController, 'Full Name', 'Enter your name...', Icons.badge_outlined),
                        const SizedBox(height: 20),
                        
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_houseNoController, 'House No', 'H.No...', Icons.home_outlined)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(_streetController, 'Street', 'Street name...', Icons.add_road_rounded)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_villageController, 'Village', 'Village name...', Icons.landscape_rounded)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(_districtController, 'District', 'District name...', Icons.location_city_rounded)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_stateController, 'State', 'State name...', Icons.map_outlined)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(_pincodeController, 'Pincode', 'Zip code...', Icons.pin_drop_rounded)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        if (_detectedLat != null && _detectedLng != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.gps_fixed_rounded, size: 14, color: Color(0xFF2E7D32)),
                                const SizedBox(width: 8),
                                Text(
                                  "Coordinates: ${_detectedLat!.toStringAsFixed(6)}, ${_detectedLng!.toStringAsFixed(6)}",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        _buildTextField(_countryController, 'Country', 'Country name...', Icons.public_rounded),
                        const SizedBox(height: 20),
                        const SizedBox(height: 20),
                        
                        _buildTextField(_phoneController, 'Phone Number', '', Icons.phone_android_rounded, enabled: false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Save Button (Fixed at bottom)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -4)),
              ],
            ),
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00AA55).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: ElevatedButton(
                onPressed: _saveProfileData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AA55),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)),
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
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF2C3E50)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
              prefixIcon: Icon(icon, color: const Color(0xFF00AA55), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
