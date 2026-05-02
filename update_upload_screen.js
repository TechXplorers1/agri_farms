const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\upload_item_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

// Add import
if (!content.includes("../services/geocoding_service.dart")) {
    content = content.replace("import 'package:geocoding/geocoding.dart';", "import 'package:geocoding/geocoding.dart' as geo;\nimport '../services/geocoding_service.dart';");
}

// Add helper method
const helperMethod = `
  Future<void> _updateCoordinatesFromAddress() async {
    try {
      String fullAddress = "\${_houseNoController.text}, \${_streetController.text}, \${_villageController.text}, \${_districtController.text}, \${_stateController.text}, \${_countryController.text}, \${_pincodeController.text}";
      
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
        final coords = await GeocodingService.getCoordinates(fullAddress);
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
      debugPrint("Geocoding failed: \$e");
    }
  }
`;

if (!content.includes("_updateCoordinatesFromAddress")) {
    content = content.replace("Future<void> _submit() async {", helperMethod + "\n  Future<void> _submit() async {");
}

// Call helper in _submit
content = content.replace("Future<void> _submit() async {", "Future<void> _submit() async {\n    await _updateCoordinatesFromAddress();");

fs.writeFileSync(filePath, content);
