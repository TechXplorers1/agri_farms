import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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

  // Generic PUT method
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        // Handle empty response body mapping
        return response.body.isNotEmpty ? json.decode(response.body) : {};
      } else {
        throw Exception('Failed to update data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating data: $e');
    }
  }

  // Generic DELETE method
  Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty ? json.decode(response.body) : {};
      } else {
        throw Exception('Failed to delete data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting data: $e');
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

  Future<dynamic> getUserByPhone(String phoneNumber) async {
    return await get('${ApiConfig.users}/phone/$phoneNumber');
  }

  Future<dynamic> updateUser(String userId, Map<String, dynamic> userData) async {
    return await put('${ApiConfig.users}/$userId', userData);
  }

  Future<dynamic> getUserStats(String userId) async {
    return await get('${ApiConfig.users}/$userId/stats');
  }

  // Bookings
  Future<dynamic> createBooking(Map<String, dynamic> bookingData) async {
    return await post(ApiConfig.bookings, bookingData);
  }

  Future<dynamic> getFarmerBookings(String farmerId) async {
    return await get('${ApiConfig.bookings}/farmer/$farmerId');
  }

  Future<dynamic> getProviderBookings(String providerId) async {
    return await get('${ApiConfig.bookings}/provider/$providerId');
  }

  Future<dynamic> getAssetBookings(String assetId) async {
    return await get('${ApiConfig.bookings}/asset/$assetId');
  }

  Future<dynamic> putStatus(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.put(url);
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        return response.body.isNotEmpty ? json.decode(response.body) : {};
      } else {
        throw Exception('Failed to update data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating data: $e');
    }
  }

  Future<dynamic> updateBookingStatus(String bookingId, String status) async {
    return await putStatus('${ApiConfig.bookings}/$bookingId/status?status=$status');
  }

  // Inventory - Equipment
  Future<dynamic> getEquipment({String? category, String? ownerId}) async {
    String endpoint = ApiConfig.inventoryEquipment;
    List<String> queryParams = [];
    if (category != null && category.isNotEmpty) {
      queryParams.add('category=$category');
    }
    if (ownerId != null && ownerId.isNotEmpty) {
      queryParams.add('ownerId=$ownerId');
    }
    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }
    return await get(endpoint);
  }

  Future<dynamic> addEquipment(Map<String, dynamic> equipmentData) async {
    return await post(ApiConfig.inventoryEquipment, equipmentData);
  }

  Future<dynamic> updateEquipment(String id, Map<String, dynamic> equipmentData) async {
    return await put('${ApiConfig.inventoryEquipment}/$id', equipmentData);
  }

  Future<dynamic> deleteEquipment(String id) async {
    return await delete('${ApiConfig.inventoryEquipment}/$id');
  }

  // Inventory - Vehicles
  Future<dynamic> getVehicles({String? type, String? ownerId}) async {
    String endpoint = ApiConfig.inventoryVehicles;
    List<String> queryParams = [];
    if (type != null && type.isNotEmpty) {
      queryParams.add('type=$type');
    }
    if (ownerId != null && ownerId.isNotEmpty) {
      queryParams.add('ownerId=$ownerId');
    }
    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }
    return await get(endpoint);
  }

  Future<dynamic> addVehicle(Map<String, dynamic> vehicleData) async {
    return await post(ApiConfig.inventoryVehicles, vehicleData);
  }

  Future<dynamic> updateVehicle(String id, Map<String, dynamic> vehicleData) async {
    return await put('${ApiConfig.inventoryVehicles}/$id', vehicleData);
  }

  Future<dynamic> deleteVehicle(String id) async {
    return await delete('${ApiConfig.inventoryVehicles}/$id');
  }

  // Inventory - Services
  Future<dynamic> getServices({String? type, String? ownerId}) async {
    String endpoint = ApiConfig.inventoryServices;
    List<String> queryParams = [];
    if (type != null && type.isNotEmpty) {
      queryParams.add('type=$type');
    }
    if (ownerId != null && ownerId.isNotEmpty) {
      queryParams.add('ownerId=$ownerId');
    }
    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }
    return await get(endpoint);
  }

  Future<dynamic> addService(Map<String, dynamic> serviceData) async {
    return await post(ApiConfig.inventoryServices, serviceData);
  }

  Future<dynamic> updateService(String id, Map<String, dynamic> serviceData) async {
    return await put('${ApiConfig.inventoryServices}/$id', serviceData);
  }

  Future<dynamic> deleteService(String id) async {
    return await delete('${ApiConfig.inventoryServices}/$id');
  }

  // Inventory - Worker Groups
  Future<dynamic> getWorkerGroups({String? location, String? ownerId}) async {
    String endpoint = ApiConfig.inventoryWorkerGroups;
    List<String> queryParams = [];
    if (location != null && location.isNotEmpty) {
      queryParams.add('location=$location');
    }
    if (ownerId != null && ownerId.isNotEmpty) {
      queryParams.add('ownerId=$ownerId');
    }
    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }
    return await get(endpoint);
  }

  Future<dynamic> addWorkerGroup(Map<String, dynamic> workerGroupData) async {
    return await post(ApiConfig.inventoryWorkerGroups, workerGroupData);
  }

  Future<dynamic> updateWorkerGroup(String id, Map<String, dynamic> workerGroupData) async {
    return await put('${ApiConfig.inventoryWorkerGroups}/$id', workerGroupData);
  }

  Future<dynamic> deleteWorkerGroup(String id) async {
    return await delete('${ApiConfig.inventoryWorkerGroups}/$id');
  }

  // Notifications
  Future<dynamic> getUserNotifications(String userId) async {
    return await get('${ApiConfig.notifications}/user/$userId');
  }

  Future<dynamic> markNotificationAsRead(String notificationId) async {
    return await putStatus('${ApiConfig.notifications}/$notificationId/read');
  }

  Future<dynamic> markAllNotificationsAsRead(String userId) async {
    return await putStatus('${ApiConfig.notifications}/user/$userId/read-all');
  }

  // Media Upload
  Future<Map<String, String>> uploadImage(XFile imageFile) async {
    final url = Uri.parse('$baseUrl/api/media/upload');
    try {
      var request = http.MultipartRequest('POST', url);
      final bytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: imageFile.name,
      ));
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return Map<String, String>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }
}
