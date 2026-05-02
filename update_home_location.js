const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\home_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

// Add imports
if (!content.includes("../services/geocoding_service.dart")) {
    content = content.replace("import 'package:geocoding/geocoding.dart';", "import 'package:geocoding/geocoding.dart' as geo;\nimport '../services/geocoding_service.dart';\nimport 'package:flutter/foundation.dart' show kIsWeb;");
}

// Update _fetchCurrentLocation logic
const newFetchLogic = `
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      String? village;
      String? district;

      // Try cross-platform geocoding (nominatim)
      try {
        final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=\${position.latitude}&lon=\${position.longitude}&format=json');
        final response = await ApiService().getRaw(url.toString()); // Using raw get if available or standard http
        if (response != null && response['address'] != null) {
          village = response['address']['suburb'] ?? response['address']['village'] ?? response['address']['neighbourhood'] ?? response['address']['city_district'];
          district = response['address']['district'] ?? response['address']['city'] ?? response['address']['county'];
        }
      } catch (e) {
        debugPrint("Reverse geocoding failed: \$e");
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

      setState(() => _userLocation = '\$village, \$district');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_village', village!);
      await prefs.setString('user_district', district!);
      await prefs.setDouble('user_latitude', position.latitude);
      await prefs.setDouble('user_longitude', position.longitude);
      
      if (mounted) {
        UiUtils.showCenteredToast(context, 'Location detected: \$village, \$district');
      }
`;

// Replace the old try block content (lines 224-235 approx)
content = content.replace(/Position position = await Geolocator\.getCurrentPosition\(desiredAccuracy: LocationAccuracy\.high\);[\s\S]*?UiUtils\.showCenteredToast\(context, 'Location detected: \$village, \$district'\);/, newFetchLogic);

fs.writeFileSync(filePath, content);
