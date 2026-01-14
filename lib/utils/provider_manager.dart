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
  final String approvalStatus; // 'Pending', 'Approved', 'Rejected'

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
    this.approvalStatus = 'Approved', // Default to Approved for mock data
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
        approvalStatus: 'Approved',
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
        approvalStatus: 'Approved',
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
        jobs: 50,
        approvalStatus: 'Approved',
      ),
       ServiceProvider(
        id: '4',
        name: 'Kisan Logistics',
        serviceName: 'Mini Truck',
        distance: '4 km',
        rating: 4.2,
        price: '₹1100 / trip',
        isAvailable: true,
        jobs: 42,
        approvalStatus: 'Approved',
      ),
      ServiceProvider(
        id: '5',
        name: 'Heavy Haulers',
        serviceName: 'Tractor Trolley',
        distance: '3 km',
        rating: 4.8,
        price: '₹800 / trip',
        isAvailable: true,
        jobs: 120,
        approvalStatus: 'Approved',
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
        jobs: 200,
        approvalStatus: 'Approved',
      ),
       ServiceProvider(
        id: '7',
        name: 'Local Rentals',
        serviceName: 'Tractors',
        distance: '1 km',
        rating: 4.0,
        price: '₹450 / hour',
        isAvailable: true,
        jobs: 80,
        approvalStatus: 'Approved',
      ),
      // New Pending Request Mock
      ServiceProvider(
        id: '8',
        name: 'New Village Tractor',
        serviceName: 'Tractors',
        distance: '2 km',
        rating: 0.0,
        price: '₹400 / hour',
        isAvailable: true,
        approvalStatus: 'Pending',
      ),
    ]);
  }

  final List<ServiceProvider> _providers = [];

  List<ServiceProvider> get providers => List.unmodifiable(_providers);

  List<ServiceProvider> getProvidersByService(String serviceName) {
    // Only show Approved providers in the main list
    return _providers.where((p) => p.serviceName == serviceName && p.approvalStatus == 'Approved').toList();
  }
  
  List<ServiceProvider> getPendingProviders() {
    return _providers.where((p) => p.approvalStatus == 'Pending').toList();
  }

  void addProvider(ServiceProvider provider) {
    // New providers are Pending by default (overriding whatever is passed if we strictly enforce it, 
    // but the constructor defaults to Approved, so we should set it to Pending here for uploads)
    
    // We can't modify the final field, so we must assume the caller passes 'Pending' 
    // OR we recreate it. For simplicity, since the caller is UploadItemScreen, we should ensure it passes Pending there.
    // However, to be safe:
    _providers.insert(0, provider);
    notifyListeners();
  }

  void updateProviderStatus(String id, String status) {
    // Since fields are final, we find, remove, and re-add (or we would use copyWith if available)
    final index = _providers.indexWhere((p) => p.id == id);
    if (index != -1) {
      final old = _providers[index];
      // Create new instance with updated status
      final updated = ServiceProvider(
        id: old.id,
        name: old.name,
        serviceName: old.serviceName,
        maleCount: old.maleCount,
        femaleCount: old.femaleCount,
        malePrice: old.malePrice,
        femalePrice: old.femalePrice,
        distance: old.distance,
        rating: old.rating,
        price: old.price,
        jobs: old.jobs,
        isAvailable: old.isAvailable,
        approvalStatus: status,
      );
      
      _providers[index] = updated;
      notifyListeners();
    }
  }

  void removeProvider(String id) {
    _providers.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
