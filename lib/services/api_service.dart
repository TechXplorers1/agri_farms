import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = ApiConfig.baseUrl});

  // Generic GET method
  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  // Generic POST method
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to post data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error posting data: $e');
    }
  }

  // Specific API methods (examples based on identified endpoints)

  // Users
  Future<dynamic> createUser(Map<String, dynamic> userData) async {
    return await post(ApiConfig.users, userData);
  }

  Future<dynamic> getUser(String userId) async {
    return await get('${ApiConfig.users}/$userId');
  }

  // Bookings
  Future<dynamic> createBooking(Map<String, dynamic> bookingData) async {
    return await post(ApiConfig.bookings, bookingData);
  }

  Future<dynamic> getFarmerBookings(String farmerId) async {
    return await get('${ApiConfig.bookings}/farmer/$farmerId');
  }

  // Inventory - Equipment
  Future<dynamic> getEquipment({String? category}) async {
    String endpoint = ApiConfig.inventoryEquipment;
    if (category != null && category.isNotEmpty) {
      endpoint += '?category=$category';
    }
    return await get(endpoint);
  }

  Future<dynamic> addEquipment(Map<String, dynamic> equipmentData) async {
    return await post(ApiConfig.inventoryEquipment, equipmentData);
  }

  // Inventory - Vehicles
  Future<dynamic> getVehicles({String? type}) async {
    String endpoint = ApiConfig.inventoryVehicles;
    if (type != null && type.isNotEmpty) {
      endpoint += '?type=$type';
    }
    return await get(endpoint);
  }

  // Inventory - Services
  Future<dynamic> getServices({String? type}) async {
    String endpoint = ApiConfig.inventoryServices;
    if (type != null && type.isNotEmpty) {
      endpoint += '?type=$type';
    }
    return await get(endpoint);
  }
}
