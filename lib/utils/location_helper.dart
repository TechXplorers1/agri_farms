import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationHelper {
  static Future<Map<String, String>> getAddressFromCoordinates(double lat, double lng) async {
    String village = 'Unknown Village';
    String district = 'District';

    // 1. Try Nominatim (Cross-platform)
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json');
      final response = await http.get(url, headers: {'User-Agent': 'AgriFarmsApp/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['address'] != null) {
          final addr = data['address'];
          village = addr['suburb'] ?? addr['village'] ?? addr['neighbourhood'] ?? addr['city_district'] ?? 'Unknown Village';
          district = addr['district'] ?? addr['city'] ?? addr['county'] ?? 'District';
          return {'village': village, 'district': district};
        }
      }
    } catch (e) {
      debugPrint("Nominatim reverse geocoding failed: $e");
    }

    // 2. Fallback to native geocoding (Android/iOS only)
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final placemarks = await geo.placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks[0];
          village = p.subLocality ?? p.locality ?? 'Unknown Village';
          district = p.subAdministrativeArea ?? p.administrativeArea ?? 'District';
        }
      } catch (e) {
        debugPrint("Native reverse geocoding failed: $e");
      }
    }

    return {'village': village, 'district': district};
  }
}
