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
  }) : super(approvalStatus: approvalStatus);
}

class FarmWorkerListing extends ServiceProvider {
  final int maleCount;
  final int femaleCount;
  final int malePrice;
  final int femalePrice;
  final String skills; // e.g., 'Sowing, Harvesting'

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
  }) : super(approvalStatus: approvalStatus);
}

class TransportListing extends ServiceProvider {
  final String vehicleType; // Duplicate of serviceName usually, e.g. 'Mini Truck'
  final String loadCapacity; // '1 ton'
  final String price; // '₹1200 / trip'
  final bool fuelIncluded;
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
    this.fuelIncluded = true, // Default usually yes
    this.driverIncluded = true, // Default usually yes
    this.vehicleNumber,
    this.serviceArea,
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
           jobsCompleted: old.jobsCompleted
         );
      } else if (old is TransportListing) {
         updated = TransportListing(
           id: old.id, name: old.name, serviceName: old.serviceName, distance: old.distance, rating: old.rating,
           approvalStatus: status, location: old.location, vehicleType: old.vehicleType, loadCapacity: old.loadCapacity,
           price: old.price, fuelIncluded: old.fuelIncluded, driverIncluded: old.driverIncluded, isAvailable: old.isAvailable,
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
        location: 'Rampur Village',
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
        location: 'Sonapur',
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
      ),
      ServiceListing(
        id: '103',
        name: 'Royal Harvesters',
        serviceName: 'Harvesting',
        distance: '10 km',
        rating: 4.9,
        price: '₹1500 / acre',
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
        fuelIncluded: true,
        driverIncluded: true,
        jobsCompleted: 50,
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
        fuelIncluded: true,
        driverIncluded: true,
        jobsCompleted: 42,
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
        fuelIncluded: true,
        driverIncluded: true,
        jobsCompleted: 120,
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
        fuelIncluded: true,
        driverIncluded: true,
        jobsCompleted: 80,
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
      ),
    ]);
  }
}
