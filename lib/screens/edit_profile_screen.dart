import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../services/geocoding_service.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../utils/ui_utils.dart';
import 'package:geolocator/geolocator.dart';

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
  final TextEditingController _emailController = TextEditingController();
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
  bool _isFetchingLocation = false;
  double? _detectedLat;
  double? _detectedLng;
  bool _isGeocodingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
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
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
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

      // 2. Fallback to mobile-specific if on Android/iOS safely
      final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
      if (isMobile) {
        try {
          List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            geo.Placemark place = placemarks.first;
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
    } catch (e) {
      if (mounted) UiUtils.showCustomAlert(context, 'Failed to get location: $e', isError: true);
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
      // 1. Try mobile native geocoding first
      try {
        final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
        if (isMobile) {
          List<geo.Location> locations = await geo.locationFromAddress(fullAddress);
          if (locations.isNotEmpty) {
            lat = locations.first.latitude;
            lng = locations.first.longitude;
          }
        }
      } catch (e) {
        debugPrint("Native geocoding failed: $e");
      }

      // 2. Try Nominatim/Fallback geocoding (Works beautifully on Web!)
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
        throw Exception("Could not find coordinates for the entered address. Please verify your address fields.");
      }
    } catch (e) {
      if (mounted) {
        UiUtils.showCustomAlert(context, 'Geocoding failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isGeocodingAddress = false);
    }
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Instantly load from local preferences to show immediate feedback
    setState(() {
      _userId = prefs.getString('user_id');
      _nameController.text = prefs.getString('user_name') ?? '';
      _villageController.text = prefs.getString('user_village') ?? '';
      _districtController.text = prefs.getString('user_district') ?? '';
      _phoneController.text = prefs.getString('user_phone') ?? '';
      _emailController.text = prefs.getString('user_email') ?? '';
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

    // 2. Fetch the absolute latest records from the remote database and sync
    if (_userId != null) {
      try {
        final apiService = ApiService();
        final userData = await apiService.getUser(_userId!);
        if (userData != null && userData is Map<String, dynamic>) {
          if (mounted) {
            setState(() {
              _nameController.text = userData['fullName'] ?? _nameController.text;
              _villageController.text = userData['village'] ?? _villageController.text;
              _districtController.text = userData['district'] ?? _districtController.text;
              _phoneController.text = userData['phoneNumber'] ?? _phoneController.text;
              _emailController.text = userData['email'] ?? _emailController.text;
              _houseNoController.text = userData['houseNo'] ?? _houseNoController.text;
              _streetController.text = userData['street'] ?? _streetController.text;
              _stateController.text = userData['state'] ?? _stateController.text;
              _countryController.text = userData['country'] ?? _countryController.text;
              _pincodeController.text = userData['pincode'] ?? _pincodeController.text;
              _profileImageUrl = userData['profileImageUrl'] ?? _profileImageUrl;
              if (userData['latitude'] != null) {
                _detectedLat = (userData['latitude'] as num).toDouble();
              }
              if (userData['longitude'] != null) {
                _detectedLng = (userData['longitude'] as num).toDouble();
              }
            });
          }

          // Sync database values back to SharedPreferences to keep the entire app coherent
          await prefs.setString('user_name', _nameController.text);
          await prefs.setString('user_phone', _phoneController.text);
          await prefs.setString('user_email', _emailController.text);
          await prefs.setString('user_village', _villageController.text);
          await prefs.setString('user_district', _districtController.text);
          await prefs.setString('user_houseNo', _houseNoController.text);
          await prefs.setString('user_street', _streetController.text);
          await prefs.setString('user_state', _stateController.text);
          await prefs.setString('user_country', _countryController.text);
          await prefs.setString('user_pincode', _pincodeController.text);
          if (_profileImageUrl != null) {
            await prefs.setString('user_profile_image', _profileImageUrl!);
          }
          if (_detectedLat != null) {
            await prefs.setDouble('user_latitude', _detectedLat!);
          }
          if (_detectedLng != null) {
            await prefs.setDouble('user_longitude', _detectedLng!);
          }
        }
      } catch (e) {
        debugPrint('Error syncing profile settings with DB: $e');
      }
    }
  }

  Future<void> _saveProfileData() async {
    setState(() => _isLoading = true);
    
    try {
      final apiService = ApiService();
      if (_userId == null) {
        final phone = _phoneController.text.trim();
        
        try {
          final user = await apiService.getUserByPhone(phone);
          if (user['userId'] != null) {
            _userId = user['userId'].toString();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_id', _userId!);
          } else {
             throw Exception('User fetched but userId is still null');
          }
        } catch (e) {
             throw Exception('Failed to fetch user by phone ($phone): $e');
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
          } finally {
            setState(() => _isUploading = false);
          }
        }

        // Automatic Geocoding from Address
        double? lat, lng;
        try {
          String fullAddress = "${_houseNoController.text}, ${_streetController.text}, ${_villageController.text}, ${_districtController.text}, ${_stateController.text}, ${_countryController.text}, ${_pincodeController.text}";
          
          try {
            final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
            if (isMobile) {
               List<geo.Location> locations = await geo.locationFromAddress(fullAddress);
               if (locations.isNotEmpty) {
                 lat = locations.first.latitude;
                 lng = locations.first.longitude;
               }
            }
          } catch (e) {
            debugPrint("Local geocoding not supported or failed: $e");
          }

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
          }
        } catch (e) {
          debugPrint("All geocoding methods failed: $e");
        }

        await apiService.updateUser(_userId!, {
          'fullName': _nameController.text,
          'phoneNumber': _phoneController.text,
          'email': _emailController.text,
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
        await prefs.setString('user_name', _nameController.text);
        await prefs.setString('user_phone', _phoneController.text);
        await prefs.setString('user_email', _emailController.text);
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
        if (lat != null) await prefs.setDouble('user_latitude', lat);
        if (lng != null) await prefs.setDouble('user_longitude', lng);

        if (mounted) {
          setState(() => _isLoading = false);
          UiUtils.showCenteredToast(context, 'Profile updated successfully!');
          Navigator.pop(context, true);
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
    _emailController.dispose();
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
                                        ? Image.network(
                                            ApiConfig.getFullImageUrl(_profileImageUrl), 
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(
                                              Icons.person_rounded, 
                                              size: 60, 
                                              color: Color(0xFFB0BEC5),
                                            ),
                                          )
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            _isFetchingLocation 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00AA55)))
                              : IconButton(
                                  icon: const Icon(Icons.my_location_rounded, color: Color(0xFF00AA55)),
                                  tooltip: 'Get Current Location',
                                  onPressed: _fetchCurrentLocation,
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
                        
                        const SizedBox(height: 10),
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
                                  label: const Text('Get Coordinates', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                        const SizedBox(height: 20),
                        _buildTextField(_countryController, 'Country', 'Country name...', Icons.public_rounded),
                        const SizedBox(height: 20),
                        _buildTextField(_phoneController, 'Mobile Number', '', Icons.phone_android_rounded, enabled: false),
                        const SizedBox(height: 20),
                        _buildTextField(_emailController, 'Email Address', 'Enter your email...', Icons.email_outlined),
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
