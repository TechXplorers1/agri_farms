import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Automatically switches to localhost in the web browser, and 10.0.2.2 in the Android emulator!
  // To test on a physical device, temporarily replace 'http://10.0.2.2:8083' with your Wi-Fi IP 'http://192.168.29.237:8083'.
  static const String baseUrl = kIsWeb ? 'http://localhost:8083' : 'http://10.0.2.2:8083'; 

  static const String users = '/api/users';
  static const String bookings = '/api/bookings';
  static const String inventoryEquipment = '/api/inventory/equipment';
  static const String inventoryVehicles = '/api/inventory/vehicles';
  static const String inventoryServices = '/api/inventory/services';
  static const String inventoryWorkerGroups = '/api/inventory/worker-groups';
  static const String notifications = '/api/notifications';
  
  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }
}
