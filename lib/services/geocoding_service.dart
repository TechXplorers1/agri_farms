import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&limit=1');
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'AgriFarmsApp/1.0',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          return {'latitude': lat, 'longitude': lon};
        }
      }
    } catch (e) {
      debugPrint('Nominatim error: $e');
    }
    return null;
  }
}
