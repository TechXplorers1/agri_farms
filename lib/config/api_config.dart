enum Environment { dev, prod }

class ApiConfig {
  // Switches environment based on compile-time ENV variable (defaults to dev)
  static const Environment env = Environment.prod;


  // Development base API endpoint
  // Use localhost when running Flutter on Chrome (web) - same machine as backend
  // Use your machine's local IP (e.g. http://192.168.29.237:8081) for physical Android/iOS devices
  static const String devBaseUrl = 'http://192.168.29.237:8081';

  // Production base API endpoint (AWS ECS Load Balancer / Custom Domain)
  // Override at build time using: --dart-define=API_URL=https://your-load-balancer-url
  static const String prodBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api-prod.agrifarms.in',
  );

  static String get baseUrl =>
      env == Environment.prod ? prodBaseUrl : devBaseUrl;

  // Keycloak OIDC configuration parameters
  static const String keycloakIssuer =
      'https://auth-prod.agrifarms.in/realms/agrifarms';
  static const String keycloakClientId = 'agrifarms-mobile';
  static const String keycloakRedirectUri = 'agrifarms://oauth-callback';
  static const List<String> keycloakScopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
  ];
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
    if (path == null || path.isEmpty) return '';
    // If it's already a full S3 URL, return it directly (S3 bucket is public-read)
    if (path.contains('.s3.') || path.contains('s3.amazonaws.com')) {
      return path;
    }
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) return '$baseUrl$path';
    return '$baseUrl/$path';
  }
}
