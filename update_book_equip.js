const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\book_equipment_detail_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

// Add import
if (!content.includes("import '../utils/location_helper.dart';")) {
    content = content.replace("import 'package:geocoding/geocoding.dart';", "import 'package:geocoding/geocoding.dart';\nimport '../utils/location_helper.dart';");
}

// Update _fetchCurrentLocation
const newFetchLogic = `
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // Use helper for cross-platform reverse geocoding
      final addressData = await LocationHelper.getAddressFromCoordinates(position.latitude, position.longitude);
      final String village = addressData['village']!;
      final String district = addressData['district']!;
      final String address = "\$village, \$district";

      if (mounted) {
        setState(() => _addressController.text = address);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_address', address);
        if (_fieldErrors.containsKey('address')) setState(() => _fieldErrors.remove('address'));
      }
`;

content = content.replace(/final position = await Geolocator\.getCurrentPosition\(desiredAccuracy: LocationAccuracy\.high\);[\s\S]*?if \(_fieldErrors\.containsKey\('address'\)\) setState\(\(\) => _fieldErrors\.remove\('address'\)\);\s*\}\s*\}/, newFetchLogic + "\n    }");

fs.writeFileSync(filePath, content);
