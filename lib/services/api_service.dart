import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  final String baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<String?> _getValidAccessToken() async {
    final accessToken = await _secureStorage.read(key: 'access_token');
    final refreshToken = await _secureStorage.read(key: 'refresh_token');
    final expiryStr = await _secureStorage.read(key: 'access_token_expiry');

    if (accessToken == null) return null;

    if (expiryStr != null) {
      final expiry = DateTime.parse(expiryStr);
      if (expiry.difference(DateTime.now()).inSeconds > 15) {
        return accessToken;
      }
    }

    if (refreshToken != null) {
      // 1. Try refreshing using standard HTTP POST endpoint (cross-platform, works flawlessly on Web & Mobile)
      try {
        final tokenUrl = Uri.parse('${ApiConfig.keycloakIssuer}/protocol/openid-connect/token');
        final response = await http.post(
          tokenUrl,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'grant_type': 'refresh_token',
            'client_id': ApiConfig.keycloakClientId,
            'refresh_token': refreshToken,
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final newAccessToken = data['access_token'];
          final newRefreshToken = data['refresh_token'];
          final expiresIn = data['expires_in'] ?? 300;
          final expiry = DateTime.now().add(Duration(seconds: expiresIn));

          if (newAccessToken != null) {
            await _secureStorage.write(key: 'access_token', value: newAccessToken);
            if (newRefreshToken != null) {
              await _secureStorage.write(key: 'refresh_token', value: newRefreshToken);
            }
            await _secureStorage.write(key: 'access_token_expiry', value: expiry.toIso8601String());
            return newAccessToken;
          }
        } else {
          print('HTTP token refresh failed: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Error refreshing token via HTTP: $e');
      }

      // 2. Fallback to FlutterAppAuth token refresh (primarily for native mobile platforms)
      try {
        final result = await _appAuth.token(TokenRequest(
          ApiConfig.keycloakClientId,
          ApiConfig.keycloakRedirectUri,
          issuer: ApiConfig.keycloakIssuer,
          refreshToken: refreshToken,
          scopes: ApiConfig.keycloakScopes,
        ));
        if (result != null && result.accessToken != null) {
          await _secureStorage.write(key: 'access_token', value: result.accessToken);
          if (result.refreshToken != null) {
            await _secureStorage.write(key: 'refresh_token', value: result.refreshToken);
          }
          if (result.accessTokenExpirationDateTime != null) {
            await _secureStorage.write(
              key: 'access_token_expiry',
              value: result.accessTokenExpirationDateTime!.toIso8601String(),
            );
          }
          return result.accessToken;
        }
      } catch (e) {
        print('Error refreshing token via AppAuth fallback: $e');
        await clearTokens();
      }
    }
    return null;
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'access_token_expiry');
  }

  Future<Map<String, String>> _getHeaders({bool isJson = false}) async {
    final headers = <String, String>{};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    final token = await _getValidAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Generic GET method
  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
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
      final headers = await _getHeaders(isJson: true);
      final response = await http.post(
        url,
        headers: headers,
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
      final headers = await _getHeaders(isJson: true);
      final response = await http.put(
        url,
        headers: headers,
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
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers);
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

  Future<dynamic> getUserByEmail(String email) async {
    return await get('${ApiConfig.users}/email/$email');
  }

  Future<dynamic> updateUser(String userId, Map<String, dynamic> userData) async {
    return await put('${ApiConfig.users}/$userId', userData);
  }

  Future<dynamic> getUserStats(String userId) async {
    return await get('${ApiConfig.users}/$userId/stats');
  }

  /// DEV MODE: Static login — no Firebase required.
  /// Calls /api/auth/static-login with phone + role.
  /// Backend creates user on signup or returns existing user on login.
  Future<Map<String, dynamic>> staticLogin({
    required String mobileNumber,
    required String role,
    required String fullName,
    required bool isLogin,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/static-login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'phoneNumber': mobileNumber,
        'role': role,
        'fullName': fullName.isNotEmpty ? fullName : null,
        'isLogin': isLogin,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (responseData['access_token'] != null) {
        await _secureStorage.write(key: 'access_token', value: responseData['access_token']);
        if (responseData['refresh_token'] != null) {
          await _secureStorage.write(key: 'refresh_token', value: responseData['refresh_token']);
        }
        final expiresIn = responseData['expires_in'] ?? 300;
        final expiry = DateTime.now().add(Duration(seconds: expiresIn));
        await _secureStorage.write(key: 'access_token_expiry', value: expiry.toIso8601String());
      } else {
        await clearTokens();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', responseData['userId']?.toString() ?? '');
      await prefs.setString('user_role', responseData['role'] ?? role);
      await prefs.setString('user_name', responseData['fullName'] ?? fullName);
      await prefs.setString('user_phone', responseData['phoneNumber']?.toString() ?? mobileNumber);
      await prefs.setString('user_email', responseData['email'] ?? '');

      return responseData;
    } else {
      throw Exception('staticLogin failed: ${response.statusCode} ${response.body}');
    }
  }

  /// Sends OTP to the given phone number via MSG91 backend proxy.
  Future<void> sendMsg91Otp({required String phoneNumber}) async {
    final url = Uri.parse('$baseUrl/api/auth/msg91/send-otp');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'phoneNumber': phoneNumber}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorMsg = json.decode(response.body)['message'] ?? 'Failed to send OTP';
      throw Exception(errorMsg);
    }
  }

  /// Verifies OTP via MSG91 backend proxy and performs login/signup.
  Future<Map<String, dynamic>> verifyMsg91Otp({
    required String phoneNumber,
    required String otp,
    required String role,
    required String fullName,
    required bool isLogin,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/msg91/verify-otp');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'phoneNumber': phoneNumber,
        'otp': otp,
        'role': role,
        'fullName': fullName.isNotEmpty ? fullName : null,
        'isLogin': isLogin,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (responseData['access_token'] != null) {
        await _secureStorage.write(key: 'access_token', value: responseData['access_token']);
        if (responseData['refresh_token'] != null) {
          await _secureStorage.write(key: 'refresh_token', value: responseData['refresh_token']);
        }
        final expiresIn = responseData['expires_in'] ?? 300;
        final expiry = DateTime.now().add(Duration(seconds: expiresIn));
        await _secureStorage.write(key: 'access_token_expiry', value: expiry.toIso8601String());
      } else {
        await clearTokens();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', responseData['userId']?.toString() ?? '');
      await prefs.setString('user_role', responseData['role'] ?? role);
      await prefs.setString('user_name', responseData['fullName'] ?? fullName);
      await prefs.setString('user_phone', responseData['phoneNumber']?.toString() ?? phoneNumber);
      await prefs.setString('user_email', responseData['email'] ?? '');

      return responseData;
    } else {
      final errorMsg = json.decode(response.body)['message'] ?? 'OTP verification failed';
      throw Exception(errorMsg);
    }
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
      final headers = await _getHeaders();
      final response = await http.put(url, headers: headers);
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        return response.body.isNotEmpty ? json.decode(response.body) : {};
      } else {
        throw Exception('Failed to update data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating data: $e');
    }
  }

  Future<dynamic> updateBookingStatus(String bookingId, String status, {String? cancelledBy, String? cancellationReason}) async {
    String endpoint = '${ApiConfig.bookings}/$bookingId/status?status=$status';
    if (cancelledBy != null && cancelledBy.isNotEmpty) {
      endpoint += '&cancelledBy=${Uri.encodeComponent(cancelledBy)}';
    }
    if (cancellationReason != null && cancellationReason.isNotEmpty) {
      endpoint += '&cancellationReason=${Uri.encodeComponent(cancellationReason)}';
    }
    return await putStatus(endpoint);
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

  Future<dynamic> triggerDemoNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    required String relatedId,
  }) async {
    return await post('${ApiConfig.notifications}/trigger-demo', {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'relatedId': relatedId,
    });
  }

  // Media Upload
  Future<Map<String, String>> uploadImage(XFile imageFile) async {
    final url = Uri.parse('$baseUrl/api/media/upload');
    try {
      var request = http.MultipartRequest('POST', url);
      final headers = await _getHeaders();
      request.headers.addAll(headers);
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

  // Firebase login token sync endpoint integration
  Future<dynamic> firebaseLogin({
    required String idToken,
    required String role,
    String? fullName,
  }) async {
    final response = await post('/api/auth/firebase-login', {
      'idToken': idToken,
      'role': role,
      'fullName': fullName ?? '',
    });
    
    if (response != null && response['access_token'] != null) {
      await _secureStorage.write(key: 'access_token', value: response['access_token']);
      if (response['refresh_token'] != null) {
        await _secureStorage.write(key: 'refresh_token', value: response['refresh_token']);
      }
      
      final expiresIn = response['expires_in'] ?? 300;
      final expiry = DateTime.now().add(Duration(seconds: expiresIn));
      await _secureStorage.write(key: 'access_token_expiry', value: expiry.toIso8601String());

      // Save credentials locally in SharedPreferences for UI consumption
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', response['userId'] ?? '');
      await prefs.setString('user_role', response['role'] ?? '');
      await prefs.setString('user_name', response['fullName'] ?? '');
      await prefs.setString('user_phone', response['phoneNumber'] ?? '');
      await prefs.setString('user_email', response['email'] ?? '');
    }
    return response;
  }
}
