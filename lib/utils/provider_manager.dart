import 'package:flutter/foundation.dart';

class ServiceProvider {
  final String id;
  final String name;
  final String serviceName; // 'Farm Workers', 'Ploughing', etc.
  
  // Specific fields for Farm Workers
  final int? maleCount;
  final int? femaleCount;
  final int? malePrice;
  final int? femalePrice;
  
  // General fields
  final String? distance;
  final double? rating;
  final String? price; // Generic price string for other services
  final int? jobs;
  final bool? isAvailable;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.serviceName,
    this.maleCount,
    this.femaleCount,
    this.malePrice,
    this.femalePrice,
    this.distance,
    this.rating,
    this.price,
    this.jobs,
    this.isAvailable,
  });
}

class ProviderManager extends ChangeNotifier {
  static final ProviderManager _instance = ProviderManager._internal();
  factory ProviderManager() => _instance;

  ProviderManager._internal() {
    // Initialize with dummy data
    _providers.addAll([
      ServiceProvider(
        id: '1',
        name: 'Ramesh Labour Group',
        serviceName: 'Farm Workers',
        maleCount: 12,
        femaleCount: 20,
        malePrice: 500,
        femalePrice: 700,
        distance: '3 km',
        rating: 4.8,
      ),
      ServiceProvider(
        id: '2',
        name: 'Suresh Workers',
        serviceName: 'Farm Workers',
        maleCount: 8,
        femaleCount: 15,
        malePrice: 550,
        femalePrice: 750,
        distance: '5 km',
        rating: 4.5,
      ),
      // Transport Providers
       ServiceProvider(
        id: '3',
        name: 'Speedy Transport',
        serviceName: 'Mini Truck',
        distance: '2 km',
        rating: 4.6,
        price: '₹1200 / trip',
        isAvailable: true,
        jobs: 50
      ),
       ServiceProvider(
        id: '4',
        name: 'Kisan Logistics',
        serviceName: 'Mini Truck',
        distance: '4 km',
        rating: 4.2,
        price: '₹1100 / trip',
        isAvailable: true,
         jobs: 42
      ),
      ServiceProvider(
        id: '5',
        name: 'Heavy Haulers',
        serviceName: 'Tractor Trolley',
        distance: '3 km',
        rating: 4.8,
        price: '₹800 / trip',
        isAvailable: true,
         jobs: 120
      ),
      // Equipment Providers
       ServiceProvider(
        id: '6',
        name: 'AgriMachinery Hub',
        serviceName: 'Tractors',
        distance: '5 km',
        rating: 4.7,
        price: '₹500 / hour',
        isAvailable: true,
         jobs: 200
      ),
       ServiceProvider(
        id: '7',
        name: 'Local Rentals',
        serviceName: 'Tractors',
        distance: '1 km',
        rating: 4.0,
        price: '₹450 / hour',
        isAvailable: true,
         jobs: 80
      ),
      // Generic services can be added here too if needed to be dynamic
    ]);
  }

  final List<ServiceProvider> _providers = [];

  List<ServiceProvider> get providers => List.unmodifiable(_providers);

  List<ServiceProvider> getProvidersByService(String serviceName) {
    return _providers.where((p) => p.serviceName == serviceName).toList();
  }

  void addProvider(ServiceProvider provider) {
    _providers.insert(0, provider);
    notifyListeners();
  }

  void removeProvider(String id) {
    _providers.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
