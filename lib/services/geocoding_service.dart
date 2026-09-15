import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/location_filter_model.dart';

class GeocodingService {
  static Future<Map<String, double>?> getCoordinates(String address, {String? fallbackAddress}) async {
    if (address.isEmpty) return null;
    
    Map<String, double>? coords = await _fetchFromNominatim(address);
    
    // If full address fails, try the fallback (less specific) address
    if (coords == null && fallbackAddress != null && fallbackAddress.isNotEmpty) {
      debugPrint("Full address geocoding failed, trying fallback: $fallbackAddress");
      coords = await _fetchFromNominatim(fallbackAddress);
    }
    
    return coords;
  }

  static Future<Map<String, double>?> _fetchFromNominatim(String query) async {
    try {
      final encodedAddress = Uri.encodeComponent(query);
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&limit=1&countrycodes=in');
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'AgriFarmsApp/1.0',
        },
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat']?.toString() ?? '');
          final lon = double.tryParse(data[0]['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            return {'latitude': lat, 'longitude': lon};
          }
        }
      }
    } catch (e) {
      debugPrint('Nominatim error: $e');
    }
    return null;
  }

  /// Searches locations, villages, mandals, and cities with real-time suggestions
  static Future<List<LocationFilterModel>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    try {
      final encoded = Uri.encodeComponent(trimmed);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=6&addressdetails=1&countrycodes=in',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'AgriFarmsApp/1.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<LocationFilterModel> results = [];

        for (var item in data) {
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat == null || lon == null) continue;

          final address = item['address'] as Map<String, dynamic>? ?? {};
          final village = address['suburb'] ?? address['village'] ?? address['town'] ?? address['neighbourhood'] ?? address['city'];
          final mandal = address['subdistrict'] ?? address['county'] ?? address['mandal'];
          final district = address['district'] ?? address['state_district'] ?? address['city'];
          final state = address['state'];
          final pincode = address['postcode'];

          // Build a readable short title
          final parts = <String>[];
          if (village != null && village.toString().isNotEmpty) parts.add(village.toString());
          if (district != null && district.toString().isNotEmpty && district.toString() != village.toString()) {
            parts.add(district.toString());
          }
          if (state != null && state.toString().isNotEmpty && !parts.contains(state.toString())) {
            parts.add(state.toString());
          }

          String displayName = parts.isNotEmpty ? parts.join(', ') : (item['display_name'] ?? trimmed);

          results.add(LocationFilterModel.custom(
            name: village?.toString() ?? district?.toString() ?? displayName,
            displayName: displayName,
            latitude: lat,
            longitude: lon,
            village: village?.toString(),
            mandal: mandal?.toString(),
            district: district?.toString(),
            state: state?.toString(),
            pincode: pincode?.toString(),
          ));
        }

        return results;
      }
    } catch (e) {
      debugPrint('Geocoding search error: $e');
    }

    return [];
  }

  static Future<Map<String, double>?> getCoordinatesFromAddress(String address) => getCoordinates(address);
}
