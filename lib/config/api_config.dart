import 'package:flutter/foundation.dart';

  enum Environment { dev, prod }

  class ApiConfig {
    // Switches environment based on compile-time ENV variable (defaults to dev)
    static const Environment env = Environment.dev;
 
    // Development base API endpoint
    static const String devBaseUrl = 'http://192.168.29.57:8083';
    
    // Production base API endpoint (AWS ECS Load Balancer / Custom Domain)
    // Override at build time using: --dart-define=API_URL=https://your-load-balancer-url
    static const String prodBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://agri-prod-alb-1519009909.ap-south-2.elb.amazonaws.com');

    static String get baseUrl => env == Environment.prod ? prodBaseUrl : devBaseUrl;

    // Keycloak OIDC configuration parameters
    static const String keycloakIssuer = 'https://auth-prod.agrifarms.in/realms/agrifarms';
    static const String keycloakClientId = 'agrifarms-mobile';
    static const String keycloakRedirectUri = 'agrifarms://oauth-callback';
    static const List<String> keycloakScopes = ['openid', 'profile', 'email', 'offline_access'];
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