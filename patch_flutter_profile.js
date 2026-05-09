const fs = require('fs');
const path = require('path');

const file = 'c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\edit_profile_screen.dart';
let content = fs.readFileSync(file, 'utf8');

// Add controllers
content = content.replace('final TextEditingController _phoneController = TextEditingController();', `final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();`);

// Add to loadProfileData
content = content.replace("_phoneController.text = prefs.getString('user_mobile') ?? '+919188528855';", `_phoneController.text = prefs.getString('user_mobile') ?? '+919188528855';
      _houseNoController.text = prefs.getString('user_houseNo') ?? '';
      _streetController.text = prefs.getString('user_street') ?? '';
      _stateController.text = prefs.getString('user_state') ?? '';
      _countryController.text = prefs.getString('user_country') ?? '';
      _pincodeController.text = prefs.getString('user_pincode') ?? '';`);

// Add to saveProfileData
content = content.replace("'district': _districtController.text,", `'houseNo': _houseNoController.text,
          'street': _streetController.text,
          'village': _villageController.text,
          'district': _districtController.text,
          'state': _stateController.text,
          'country': _countryController.text,
          'pincode': _pincodeController.text,`);

content = content.replace("await prefs.setString('user_district', _districtController.text);", `await prefs.setString('user_district', _districtController.text);
        await prefs.setString('user_houseNo', _houseNoController.text);
        await prefs.setString('user_street', _streetController.text);
        await prefs.setString('user_state', _stateController.text);
        await prefs.setString('user_country', _countryController.text);
        await prefs.setString('user_pincode', _pincodeController.text);`);

// Add to dispose
content = content.replace("_phoneController.dispose();", `_phoneController.dispose();
    _houseNoController.dispose();
    _streetController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();`);

// Update UI
const oldUi = `                        Row(
                          children: [
                            Expanded(child: _buildTextField(_villageController, 'Village', 'Village name...', Icons.landscape_rounded)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(_districtController, 'District', 'District name...', Icons.location_city_rounded)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        _buildTextField(_phoneController, 'Phone Number', '', Icons.phone_android_rounded, enabled: false),`;

const newUi = `                        _buildTextField(_phoneController, 'Phone Number', '', Icons.phone_android_rounded, enabled: false),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF00AA55)),
                            const SizedBox(width: 12),
                            Text(
                              'ADDRESS DETAILS',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF1B5E20).withOpacity(0.6), letterSpacing: 1.2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(flex: 1, child: _buildTextField(_houseNoController, 'H.No', 'House No.', Icons.home_rounded)),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: _buildTextField(_streetController, 'Street', 'Street Name', Icons.signpost_rounded)),
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
                            Expanded(child: _buildTextField(_stateController, 'State', 'State...', Icons.map_rounded)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(_pincodeController, 'Pincode', 'Pincode', Icons.pin_drop_rounded)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        _buildTextField(_countryController, 'Country', 'Country', Icons.public_rounded),`;

content = content.replace(oldUi, newUi);

fs.writeFileSync(file, content);
console.log('Fixed edit_profile_screen.dart');
