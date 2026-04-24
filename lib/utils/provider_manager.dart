import 'package:flutter/foundation.dart';
import '../data/services/api_service.dart';
import '../data/models/equipment_model.dart';
import '../data/models/transport_vehicle_model.dart';
import '../data/models/service_offering_model.dart';

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
    fetchProvidersFromApi();
  }

  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchProvidersFromApi() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Keep Mock Workers (as we don't have API for them yet)
      _providers.clear();
      _initializeMockData(); // Adds workers

      // 2. Fetch Equipment
      try {
        final equipmentList = await _apiService.getEquipment();
        for (var eq in equipmentList) {
          _providers.add(EquipmentListing(
            id: eq.equipmentId ?? DateTime.now().millisecondsSinceEpoch.toString(),
            name: 'Provider ${eq.ownerId.substring(0, 4)}', // Placeholder name
            serviceName: eq.category ?? 'Equipment',
            brandModel: eq.brandModel ?? 'Unknown Model',
            distance: eq.location ?? 'Unknown',
            rating: eq.rating ?? 0.0,
            price: '₹${eq.pricePerHour?.toStringAsFixed(0) ?? 0} / hour',
            operatorAvailable: eq.operatorAvailable ?? false,
            condition: 'Good', // Default
            location: eq.location ?? '',
            isAvailable: eq.isAvailable ?? true,
            image: eq.imageUrl,
          ));
        }
      } catch (e) {
        print('Error fetching equipment: $e');
      }

      // 3. Fetch Vehicles
      try {
        final vehicleList = await _apiService.getVehicles();
        for (var v in vehicleList) {
          _providers.add(TransportListing(
            id: v.vehicleId ?? DateTime.now().millisecondsSinceEpoch.toString(),
            name: 'Provider ${v.ownerId.substring(0, 4)}',
            serviceName: v.vehicleType ?? 'Transport',
            vehicleType: v.vehicleType ?? 'Unknown',
            loadCapacity: v.loadCapacity ?? 'Unknown',
            price: '₹${v.pricePerKmOrTrip?.toStringAsFixed(0) ?? 0} / trip',
            distance: v.location ?? 'Unknown',
            rating: v.rating ?? 0.0,
            driverIncluded: v.driverIncluded ?? true,
            vehicleNumber: v.vehicleNumber,
            serviceArea: v.location,
            location: v.location ?? '',
            isAvailable: v.isAvailable ?? true,
            image: v.imageUrl,
          ));
        }
      } catch (e) {
        print('Error fetching vehicles: $e');
      }

      // 4. Fetch Services
      try {
        final serviceList = await _apiService.getServices();
        for (var s in serviceList) {
          _providers.add(ServiceListing(
            id: s.serviceId ?? DateTime.now().millisecondsSinceEpoch.toString(),
            name: s.businessName ?? 'Provider ${s.ownerId.substring(0, 4)}',
            serviceName: s.serviceType ?? 'Service',
            distance: s.location ?? 'Unknown',
            rating: s.rating ?? 0.0,
            price: '₹${s.priceRate?.toStringAsFixed(0) ?? 0} ${s.priceUnit ?? ""}',
            equipmentUsed: s.description ?? 'Standard Equipment',
            operatorIncluded: true,
            location: s.location ?? '',
            isAvailable: s.isAvailable ?? true,
            image: s.imageUrl,
          ));
        }
      } catch (e) {
        print('Error fetching services: $e');
      }

    } catch (e) {
      print('Error in fetchProvidersFromApi: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  final List<ServiceProvider> _providers = [];

  List<ServiceProvider> get providers => List.unmodifiable(_providers);

  List<ServiceProvider> getProvidersByService(String serviceName) {
    return _providers.where((p) => p.serviceName == serviceName && p.approvalStatus == 'Approved').toList();
  }

  List<ServiceProvider> getPendingProviders() {
    return _providers.where((p) => p.approvalStatus == 'Pending').toList();
  }

  Future<void> addProvider(ServiceProvider provider) async {
    try {
      if (provider is EquipmentListing) {
        await _apiService.addEquipment(Equipment(
          ownerId: 'user-123', // Placeholder until Auth is ready
          category: provider.serviceName,
          brandModel: provider.brandModel,
          pricePerHour: double.tryParse(provider.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
          operatorAvailable: provider.operatorAvailable,
          location: provider.location,
          isAvailable: provider.isAvailable,
          imageUrl: provider.image,
          rating: provider.rating,
        ));
      } else if (provider is TransportListing) {
        await _apiService.addVehicle(TransportVehicle(
           ownerId: 'user-123',
           vehicleType: provider.vehicleType,
           vehicleNumber: provider.vehicleNumber,
           loadCapacity: provider.loadCapacity,
           pricePerKmOrTrip: double.tryParse(provider.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
           driverIncluded: provider.driverIncluded,
           location: provider.location,
           isAvailable: provider.isAvailable,
           imageUrl: provider.image,
           rating: provider.rating,
        ));
      } else if (provider is ServiceListing) {
         await _apiService.addService(ServiceOffering(
           ownerId: 'user-123',
           serviceType: provider.serviceName,
           businessName: provider.name,
           description: provider.equipmentUsed,
           priceRate: double.tryParse(provider.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
           location: provider.location,
           isAvailable: provider.isAvailable,
           imageUrl: provider.image,
           rating: provider.rating,
           priceUnit: provider.price.contains('/') ? "/" + provider.price.split('/').last.trim() : null,
         ));
      }
    } catch (e) {
      print('Error adding provider to API: $e');
    }

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
    // Only adding workers mock data now, others are fetched from API
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

    ]);
  }
}
