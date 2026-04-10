import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
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

  String? _userId;
  String? _profileImageUrl;
  XFile? _selectedImage;
  bool _isLoading = true;
  bool _isUploading = false;

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
      _profileImageUrl = prefs.getString('user_profile_image');
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

        await apiService.updateUser(_userId!, {
          'fullName': _nameController.text,
          'village': _villageController.text,
          'district': _districtController.text,
          'profileImageUrl': finalImageUrl,
        });
        
        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', _nameController.text);
        await prefs.setString('user_village', _villageController.text);
        await prefs.setString('user_district', _districtController.text);
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.normal),
        ),
        elevation: 0,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                              image: _selectedImage != null 
                                ? (kIsWeb 
                                    ? DecorationImage(image: NetworkImage(_selectedImage!.path), fit: BoxFit.cover)
                                    : DecorationImage(image: FileImage(File(_selectedImage!.path)), fit: BoxFit.cover))
                                : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(ApiConfig.getFullImageUrl(_profileImageUrl)), fit: BoxFit.cover)
                                  : null),
                            ),
                            child: (_selectedImage == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty))
                                ? const Icon(Icons.person_outline, size: 40, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF00AA55), // Green
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
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
                  ),
                  const SizedBox(height: 30),

                  // Name
                  _buildLabel('Full Name'),
                  _buildTextField(_nameController, 'Enter User Name'),
                  const SizedBox(height: 20),

                  // Village & District Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Village'),
                            _buildTextField(_villageController, 'Your Village'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('District'),
                            _buildTextField(_districtController, 'Your District'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Phone
                  _buildLabel('Phone Number'),
                  _buildTextField(_phoneController, '', enabled: false), // Usually phone is not editable directly
                ],
              ),
            ),
          ),
          
          // Save Button (Fixed at bottom)
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: _saveProfileData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C1020), // Dark color from screenshot
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool enabled = true, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100], // Light grey background
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
