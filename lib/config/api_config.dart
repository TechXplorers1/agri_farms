import 'package:flutter/foundation.dart';

  enum Environment { dev, prod }

  class ApiConfig {
    // Switches environment based on compile-time ENV variable (defaults to dev)
    static const Environment env = Environment.dev;
 
    // Development base API endpoint (Using local IP on port 8081)
    // Note: Change to 8081 if you run the backend using Maven (mvn spring-boot:run) directly on host
    static const String devBaseUrl = 'http://192.168.29.57:8081';
    
    // Production base API endpoint (AWS ECS Load Balancer / Custom Domain)
    // Override at build time using: --dart-define=API_URL=https://your-load-balancer-url
    static const String prodBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://api-prod.agrifarms.in');

    static String get baseUrl => env == Environment.prod ? prodBaseUrl : devBaseUrl;

    // Keycloak OIDC configuration parameters
    static const String keycloakIssuer = 'https://auth-prod.agrifarms.in/realms/agrifarms';
    static const String keycloakClientId = 'agrifarms-mobile';
    static const String keycloakRedirectUri = 'agrifarms://oauth- callback';
    static const List<String> keycloakScopes = ['openid', 'profile', 'email', 'offline_access'];
    static const String users = '/api/users';
    static const String bookings = '/api/bookings';
    static const String inventoryEquipment = '/api/inventory/equipment';
    static const String inventoryVehicles = '/api/inventory/vehicles';
    static const String inventoryServices = '/api/inventory/services';
    static const String inventoryWorkerGroups = '/api/inventory/worker-groups';
    static const String notifications = '/api/notifications';

    // MSG91 Widget configuration for OTP
    static const String msg91WidgetId = '6a6470ebe285710a1e0ead72';
    // Replace this with your actual MSG91 Auth Token from the 'Tokens' section of the MSG91 dashboard
    static const String msg91AuthToken = '551740AvEkrLHO5I6a63711bP1'; // using the one from application.yml
    
    static String getFullImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';

    // If it's a direct AWS S3 URL, extract the filename and route through the backend proxy
    if (path.contains('.s3.') || path.contains('amazonaws.com')) {
      final uri = Uri.tryParse(path);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        final filename = uri.pathSegments.last;
        return '$baseUrl/api/media/download/$filename';
      }
    }

    // If it's already a full HTTP URL (non-S3), return as is
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // If it starts with slash (e.g. /api/media/download/...)
    if (path.startsWith('/')) {
      return '$baseUrl$path';
    }

    // Default: relative filename
    return '$baseUrl/api/media/download/$path';
  }
}