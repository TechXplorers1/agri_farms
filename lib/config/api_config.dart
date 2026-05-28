  import 'package:flutter/foundation.dart';

  class ApiConfig {
    // Automatically switches to localhost on web, and your local PC Wi-Fi IP on physical/emulated mobile devices!
    static const String baseUrl = 'http://192.168.29.57:8083'; 
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
