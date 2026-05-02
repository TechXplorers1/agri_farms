const fs = require('fs');
const filePath = "c:\\Users\\csc\\Desktop\\Agri Farms\\agri_farms\\lib\\screens\\upload_item_screen.dart";
let content = fs.readFileSync(filePath, 'utf8');

// Add imports
if (!content.includes("import 'package:http/http.dart'")) {
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:http/http.dart' as http;\nimport 'dart:convert';");
}

// Update _fetchCurrentLocation logic
const newFetchLogic = `
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
      });

      String? village;
      String? district;

      // Try cross-platform geocoding (nominatim)
      try {
        final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=\${position.latitude}&lon=\${position.longitude}&format=json');
        final responseData = await http.get(url, headers: {'User-Agent': 'AgriFarmsApp/1.0'});
        final response = json.decode(responseData.body);
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

      setState(() {
        _locationController.text = "\$village, \$district";
        _villageController.text = village!;
        _districtController.text = district!;
      });
      
      if (mounted) {
        UiUtils.showCenteredToast(context, 'Location detected: \$village, \$district');
      }
`;

// Replace the old block (lines 139-160 approx)
content = content.replace(/Position position = await Geolocator\.getCurrentPosition\([\s\S]*?UiUtils\.showCenteredToast\(context, 'Location detected: \$village, \$district'\);[\s\S]*?}/, newFetchLogic + "\n    }");

fs.writeFileSync(filePath, content);
