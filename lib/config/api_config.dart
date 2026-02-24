class ApiConfig {
  // Use 10.0.2.2 for Android emulator to access localhost of the host machine.
  // Use your machine's IP address if testing on a real device.
  // Use 'localhost' ONLY if testing on iOS simulator.
  // UPDATE: Found local IP 192.168.29.196. This works best for physical devices too.
  static const String baseUrl = 'http://localhost:8083'; 

  static const String users = '/api/users';
  static const String bookings = '/api/bookings';
  static const String inventoryEquipment = '/api/inventory/equipment';
  static const String inventoryVehicles = '/api/inventory/vehicles';
  static const String inventoryServices = '/api/inventory/services';
  static const String inventoryWorkerGroups = '/api/inventory/worker-groups';
}
