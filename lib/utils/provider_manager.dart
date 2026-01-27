import 'package:flutter/foundation.dart';

abstract class ServiceProvider {
  final String id;
  final String name;
  final String serviceName; // 'Farm Workers', 'Ploughing', etc.
  final String distance;
  final double rating;
  final String approvalStatus; // 'Pending', 'Approved', 'Rejected'
  final String location;
  final bool isAvailable;
  final int jobsCompleted;
  final String? image; // New image field

  ServiceProvider({
    required this.id,
    required this.name,
    required this.serviceName,
    required this.distance,
    required this.rating,
    required this.approvalStatus,
    this.location = '',
    this.isAvailable = true,
    this.jobsCompleted = 0,
    this.image,
  });
}

class ServiceListing extends ServiceProvider {
  final String equipmentUsed;
  final String price; // e.g., '₹1200 / acre'
  final bool operatorIncluded;

  ServiceListing({
    required super.id,
    required super.name,
    required super.serviceName,
    required super.distance,
    required super.rating,
    String approvalStatus = 'Approved',
    super.location,
    super.isAvailable,
    super.jobsCompleted,
    required this.equipmentUsed,
    required this.price,
    required this.operatorIncluded,
    super.image,
  }) : super(approvalStatus: approvalStatus);
}

class FarmWorkerListing extends ServiceProvider {
  final int maleCount;
  final int femaleCount;
  final int malePrice;
  final int femalePrice;
  final String skills; // e.g., 'Sowing, Harvesting'
  final List<String> roleDistribution; // e.g. ["5 Men - Sowing", "4 Women - Weeding"]

  FarmWorkerListing({
    required super.id,
    required super.name,
    required super.serviceName, // 'Farm Workers'
    required super.distance,
    required super.rating,
    String approvalStatus = 'Approved',
    super.location,
    super.isAvailable,
    super.jobsCompleted,
    required this.maleCount,
    required this.femaleCount,
    required this.malePrice,
    required this.femalePrice,
    required this.skills,
    this.roleDistribution = const [],
    super.image,
  }) : super(approvalStatus: approvalStatus);
}

class TransportListing extends ServiceProvider {
  final String vehicleType; // Duplicate of serviceName usually, e.g. 'Mini Truck'
  final String loadCapacity; // '1 ton'
  final String price; // '₹1200 / trip'
  final bool driverIncluded;
  final String? vehicleNumber; // Optional / Private
  final String? serviceArea;

  TransportListing({
    required super.id,
    required super.name,
    required super.serviceName,
    required super.distance,
    required super.rating,
    String approvalStatus = 'Approved',
    super.location,
    super.isAvailable,
    super.jobsCompleted,
    required this.vehicleType,
    required this.loadCapacity,
    required this.price,
    this.driverIncluded = true, // Default usually yes
    this.vehicleNumber,
    this.serviceArea,
    super.image,
  }) : super(approvalStatus: approvalStatus);
}

class EquipmentListing extends ServiceProvider {
  final String brandModel;
  final String price; // '₹500 / hour'
  final bool operatorAvailable;
  final String condition; // 'Good', 'New'
  final String? yearOfManufacture;

  EquipmentListing({
    required super.id,
    required super.name,
    required super.serviceName,
    required super.distance,
    required super.rating,
    String approvalStatus = 'Approved',
    super.location,
    super.isAvailable,
    super.jobsCompleted,
    required this.brandModel,
    required this.price,
    required this.operatorAvailable,
    this.condition = 'Good',
    this.yearOfManufacture,
    super.image,
  }) : super(approvalStatus: approvalStatus);
}

class ProviderManager extends ChangeNotifier {
  static final ProviderManager _instance = ProviderManager._internal();
  factory ProviderManager() => _instance;

  ProviderManager._internal() {
    _initializeMockData();
  }

  final List<ServiceProvider> _providers = [];

  List<ServiceProvider> get providers => List.unmodifiable(_providers);

  List<ServiceProvider> getProvidersByService(String serviceName) {
    return _providers.where((p) => p.serviceName == serviceName && p.approvalStatus == 'Approved').toList();
  }

  List<ServiceProvider> getPendingProviders() {
    return _providers.where((p) => p.approvalStatus == 'Pending').toList();
  }

  void addProvider(ServiceProvider provider) {
    _providers.insert(0, provider);
    notifyListeners();
  }

  void updateProviderStatus(String id, String status) {
    final index = _providers.indexWhere((p) => p.id == id);
    if (index != -1) {
      // Re-create logic would be needed here, or mutability. 
      // For now we might need to cast or make status mutable.
      // But adhering to immutable pattern:
      final old = _providers[index];
      
      ServiceProvider? updated;
      
      if (old is ServiceListing) {
         updated = ServiceListing(
           id: old.id, name: old.name, serviceName: old.serviceName, distance: old.distance, rating: old.rating,
           approvalStatus: status, location: old.location, equipmentUsed: old.equipmentUsed, price: old.price,
           operatorIncluded: old.operatorIncluded, isAvailable: old.isAvailable, jobsCompleted: old.jobsCompleted
         );
      } else if (old is FarmWorkerListing) {
         updated = FarmWorkerListing(
           id: old.id, name: old.name, serviceName: old.serviceName, distance: old.distance, rating: old.rating,
           approvalStatus: status, location: old.location, maleCount: old.maleCount, femaleCount: old.femaleCount,
           malePrice: old.malePrice, femalePrice: old.femalePrice, skills: old.skills, isAvailable: old.isAvailable,
           jobsCompleted: old.jobsCompleted, roleDistribution: old.roleDistribution
         );
      } else if (old is TransportListing) {
         updated = TransportListing(
           id: old.id, name: old.name, serviceName: old.serviceName, distance: old.distance, rating: old.rating,
           approvalStatus: status, location: old.location, vehicleType: old.vehicleType, loadCapacity: old.loadCapacity,
           price: old.price, driverIncluded: old.driverIncluded, isAvailable: old.isAvailable,
           jobsCompleted: old.jobsCompleted, vehicleNumber: old.vehicleNumber, serviceArea: old.serviceArea
         );
      } else if (old is EquipmentListing) {
         updated = EquipmentListing(
           id: old.id, name: old.name, serviceName: old.serviceName, distance: old.distance, rating: old.rating,
           approvalStatus: status, location: old.location, brandModel: old.brandModel, price: old.price,
           operatorAvailable: old.operatorAvailable, condition: old.condition, isAvailable: old.isAvailable,
           jobsCompleted: old.jobsCompleted, yearOfManufacture: old.yearOfManufacture
         );
      }

      if (updated != null) {
        _providers[index] = updated;
        notifyListeners();
      }
    }
  }

  void removeProvider(String id) {
    _providers.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void _initializeMockData() {
    _providers.addAll([
      // --- Farm Workers ---
      FarmWorkerListing(
        id: '1',
        name: 'Ramesh Labour Group',
        serviceName: 'Farm Workers',
        maleCount: 12,
        femaleCount: 20,
        malePrice: 500,
        femalePrice: 700,
        distance: '3 km',
        rating: 4.8,
        skills: 'Sowing, Harvesting',
        roleDistribution: ['12 Men - Sowing', '20 Women - Harvesting'],
        location: 'Rampur Village',
        image: 'https://images.unsplash.com/photo-1595843472097-dfd63ff444d1?q=80&w=200&auto=format&fit=crop',
      ),
      FarmWorkerListing(
        id: '2',
        name: 'Suresh Workers',
        serviceName: 'Farm Workers',
        maleCount: 8,
        femaleCount: 15,
        malePrice: 550,
        femalePrice: 750,
        distance: '5 km',
        rating: 4.5,
        skills: 'Weeding, Loading',
        roleDistribution: ['8 Men - Loading', '15 Women - Weeding'],
        location: 'Sonapur',
        image: 'https://images.unsplash.com/photo-1628155985854-443b740523bb?q=80&w=200&auto=format&fit=crop',
      ),

      // --- Agricultural Services (Ploughing/Harvesting) ---
      ServiceListing(
        id: '101',
        name: 'Green Field Ploughing',
        serviceName: 'Ploughing',
        distance: '4 km',
        rating: 4.7,
        price: '₹1200 / acre',
        equipmentUsed: 'Mahindra 575 DI',
        operatorIncluded: true,
        jobsCompleted: 85,
        location: 'Rampur',
        image: 'https://images.unsplash.com/photo-1530267981375-f0de93fe1e91?q=80&w=200&auto=format&fit=crop',
      ),
      ServiceListing(
        id: '102',
        name: 'Mahindra Ploughers',
        serviceName: 'Ploughing',
        distance: '6 km',
        rating: 4.5,
        price: '₹1100 / acre',
        equipmentUsed: 'Swaraj 855',
        operatorIncluded: true,
        jobsCompleted: 60,
        image: 'https://plus.unsplash.com/premium_photo-1661963248881-22920c743fe5?q=80&w=200&auto=format&fit=crop',
      ),
      ServiceListing(
        id: '103',
        name: 'Royal Harvesters',
        serviceName: 'Harvesting',
        distance: '10 km',
        rating: 4.9,
        price: '₹2000 / hour',
        equipmentUsed: 'Kartar 4000',
        operatorIncluded: true,
        jobsCompleted: 110,
      ),
      ServiceListing(
        id: '107',
        name: 'Jal Shakti Irrigation',
        serviceName: 'Irrigation',
        distance: '5 km',
        rating: 4.5,
        price: '₹300 / hour',
        equipmentUsed: 'Diesel Pump 5HP',
        operatorIncluded: true,
        jobsCompleted: 200,
        image: 'https://images.unsplash.com/photo-1595843472097-dfd63ff444d1?q=80&w=200&auto=format&fit=crop', // Irrigation - just using worker image for now or placeholder
      ),
      ServiceListing(
        id: '108',
        name: 'Quick Fix Electric',
        serviceName: 'Electricians',
        distance: '2 km',
        rating: 4.8,
        price: '₹200 / visit',
        equipmentUsed: 'Standard Toolkit',
        operatorIncluded: true,
        jobsCompleted: 150,
        image: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=200&auto=format&fit=crop',
      ),
      ServiceListing(
        id: '109',
        name: 'Sharma Motor Works',
        serviceName: 'Mechanics',
        distance: '3 km',
        rating: 4.6,
        price: '₹300 / visit',
        equipmentUsed: 'Garage Tools',
        operatorIncluded: true,
        jobsCompleted: 120,
        image: 'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?q=80&w=200&auto=format&fit=crop',
      ),

      // --- Transport Services ---
      TransportListing(
        id: '3',
        name: 'Speedy Transport',
        serviceName: 'Mini Truck',
        vehicleType: 'Mini Truck',
        distance: '2 km',
        rating: 4.6,
        price: '₹1200 / trip',
        loadCapacity: '1 ton',
        driverIncluded: true,
        jobsCompleted: 50,
        image: 'https://images.unsplash.com/photo-1605218427306-022ba951dd0c?q=80&w=200&auto=format&fit=crop', 
      ),
      TransportListing(
        id: '4',
        name: 'Kisan Logistics',
        serviceName: 'Mini Truck',
        vehicleType: 'Mini Truck',
        distance: '4 km',
        rating: 4.2,
        price: '₹1100 / trip',
        loadCapacity: '1.5 ton',
        driverIncluded: true,
        jobsCompleted: 42,
        image: 'https://images.unsplash.com/photo-1626847037657-fd3622613ce3?q=80&w=200&auto=format&fit=crop',
      ),
      TransportListing(
        id: '5',
        name: 'Heavy Haulers',
        serviceName: 'Tractor Trolley',
        vehicleType: 'Tractor Trolley',
        distance: '3 km',
        rating: 4.8,
        price: '₹800 / trip',
        loadCapacity: '3 ton',
        driverIncluded: true,
        jobsCompleted: 120,
        image: 'https://images.unsplash.com/photo-1588665313070-653606f5712e?q=80&w=200&auto=format&fit=crop', // Tractor Trolleyish
      ),
      TransportListing(
        id: '201',
        name: 'Highway Kings',
        serviceName: 'Full Truck',
        vehicleType: 'Full Truck',
        distance: '15 km',
        rating: 4.5,
        price: '₹5000 / trip',
        loadCapacity: '10 ton',
        driverIncluded: true,
        jobsCompleted: 80,
         image: 'https://images.unsplash.com/photo-1519003722824-194d4455a60c?q=80&w=200&auto=format&fit=crop', // Truck
      ),

      // --- Equipment Rentals ---
      EquipmentListing(
        id: '6',
        name: 'AgriMachinery Hub',
        serviceName: 'Tractors',
        brandModel: 'John Deere 5310',
        distance: '5 km',
        rating: 4.7,
        price: '₹500 / hour',
        operatorAvailable: true, // "With or Without"
        condition: 'Good',
        jobsCompleted: 200,
        image: 'https://images.unsplash.com/photo-1592860956971-555df6d915c7?q=80&w=200&auto=format&fit=crop',
      ),
       EquipmentListing(
        id: '7',
        name: 'Local Rentals',
        serviceName: 'Tractors',
        brandModel: 'Sonalika 745',
        distance: '1 km',
        rating: 4.0,
        price: '₹450 / hour',
        operatorAvailable: false,
        condition: 'Average',
        jobsCompleted: 80,
        image: 'https://images.unsplash.com/photo-1628155985854-443b740523bb?q=80&w=200&auto=format&fit=crop',
      ),
      EquipmentListing(
        id: '301',
        name: 'Super Harvest',
        serviceName: 'Harvesters',
        brandModel: 'Class Crop Tiger',
        distance: '12 km',
        rating: 4.8,
        price: '₹2000 / hour',
        operatorAvailable: true,
        condition: 'New',
        jobsCompleted: 65,
        image: 'https://images.unsplash.com/photo-1632152862822-7776104bc179?q=80&w=200&auto=format&fit=crop', // Harvester
      ),
      EquipmentListing(
        id: '302',
        name: 'Spray Master',
        serviceName: 'Sprayers',
        brandModel: 'Mitra Sprayer',
        distance: '4 km',
        rating: 4.4,
        price: '₹200 / hour',
        operatorAvailable: false,
        condition: 'Good',
        jobsCompleted: 180,
        image: 'https://images.unsplash.com/photo-1559304822-9eb2813c9844?q=80&w=200&auto=format&fit=crop', // Sprayer
      ),
    ]);
  }
}
