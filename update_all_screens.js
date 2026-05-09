const fs = require('fs');
const files = [
    "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\book_workers_screen.dart",
    "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\book_transport_detail_screen.dart",
    "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\book_service_detail_screen.dart",
    "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\edit_registered_item_screen.dart"
];

const newFetchLogic = `
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // Use helper for cross-platform reverse geocoding
      final addressData = await LocationHelper.getAddressFromCoordinates(position.latitude, position.longitude);
      final String village = addressData['village']!;
      final String district = addressData['district']!;
      final String address = "\$village, \$district";

      if (mounted) {
        setState(() => _addressController.text = address);
        // Save to prefs if needed (check file context)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_address', address);
        if (_fieldErrors.containsKey('address')) setState(() => _fieldErrors.remove('address'));
      }
`;

files.forEach(filePath => {
    let content = fs.readFileSync(filePath, 'utf8');
    
    // Add import
    if (!content.includes("import '../utils/location_helper.dart';")) {
        content = content.replace("import 'package:geocoding/geocoding.dart';", "import 'package:geocoding/geocoding.dart';\nimport '../utils/location_helper.dart';");
    }

    // Replace fetch logic
    // The pattern needs to be generic enough for all these files
    content = content.replace(/final position = await Geolocator\.getCurrentPosition\([\s\S]*?placemarkFromCoordinates\([\s\S]*?setState\(\(\) => _fieldErrors\.remove\('address'\)\);\s*\}\s*\}/, newFetchLogic + "\n    }");

    fs.writeFileSync(filePath, content);
});
