import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'upload_item_screen.dart';
import 'book_workers_screen.dart';
import 'book_transport_detail_screen.dart';
import 'book_equipment_detail_screen.dart';
import 'book_service_detail_screen.dart';
import '../utils/provider_manager.dart';

import '../services/api_service.dart';
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/vehicle_data.dart'; // Import VehicleData

class ServiceProvidersScreen extends StatefulWidget {
  final String serviceKey; // Internal key for data fetching (e.g., 'Ploughing')
  final String title;      // Localized title for display
  final String? userRole;

  const ServiceProvidersScreen({
    super.key, 
    required this.serviceKey, 
    required this.title, 
    this.userRole
  });

  @override
  State<ServiceProvidersScreen> createState() => _ServiceProvidersScreenState();
}

class _ServiceProvidersScreenState extends State<ServiceProvidersScreen> {
  String? _selectedMake;
  String? _selectedLocation;
  late Future<List<ServiceProvider>> _providersFuture;

  @override
  void initState() {
    super.initState();
    _providersFuture = _fetchProviders();
  }

  Future<List<ServiceProvider>> _fetchProviders() async {
    final List<String> transportTypes = ['Mini Truck', 'Tractor Trolley', 'Full Truck', 'Tempo', 'Pickup Van', 'Container'];
    final List<String> equipmentTypes = ['Tractors', 'Harvesters', 'Sprayers', 'Trolleys', 'JCB', 'Rotavators', 'Cultivators', 'Seed Drills', 'Power Tillers'];
    final List<String> serviceTypes = ['Ploughing', 'Harvesting', 'Drone Spraying', 'Irrigation', 'Vet Care', 'Crop Advisory'];

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');
      final apiService = ApiService();

      if (transportTypes.contains(widget.serviceKey)) {
        final vehiclesRaw = await apiService.getVehicles(type: widget.serviceKey) as List;
        final vehicles = vehiclesRaw.where((v) => v['ownerId']?.toString() != currentUserId).toList();
        
        return vehicles.map<ServiceProvider>((v) => TransportListing(
          id: v['vehicleId'].toString(),
          providerId: v['ownerId']?.toString(),
          name: v['ownerName'] ?? 'Unknown Owner',
          serviceName: v['vehicleType'],
          distance: 'Pending',
          rating: (v['rating'] ?? 5.0).toDouble(),
          approvalStatus: v['approvalStatus'] ?? 'Pending',
          location: v['location'] ?? 'Unknown',
          vehicleType: v['vehicleType'],
          loadCapacity: v['loadCapacity'] ?? 'Unknown',
          price: '₹${v['pricePerKmOrTrip']} / Trip',
          driverIncluded: v['driverIncluded'] ?? true,
          vehicleNumber: v['vehicleNumber'],
          serviceArea: v['serviceArea'],
          image: v['imageUrl'],
          ownerProfileImage: v['ownerProfileImageUrl'],
        )).toList();
      } else if (equipmentTypes.contains(widget.serviceKey)) {
        final equipmentRaw = await apiService.getEquipment(category: widget.serviceKey) as List;
        final equipment = equipmentRaw.where((e) => e['ownerId']?.toString() != currentUserId).toList();

        return equipment.map<ServiceProvider>((e) => EquipmentListing(
          id: e['equipmentId'].toString(),
          providerId: e['ownerId']?.toString(),
          name: e['ownerName'] ?? 'Unknown Owner',
          serviceName: e['category'],
          distance: 'Pending',
          rating: (e['rating'] ?? 5.0).toDouble(),
          approvalStatus: e['approvalStatus'] ?? 'Pending',
          location: e['location'] ?? 'Unknown',
          brandModel: e['brandModel'] ?? 'Unknown',
          condition: e['condition'] ?? 'Good',
          price: '₹${e['pricePerHour']} / hr',
          operatorAvailable: e['operatorAvailable'] ?? false,
          image: e['imageUrl'],
          ownerProfileImage: e['ownerProfileImageUrl'],
        )).toList();
      } else if (serviceTypes.contains(widget.serviceKey)) {
         final servicesRaw = await apiService.getServices(type: widget.serviceKey) as List;
         final services = servicesRaw.where((s) => s['ownerId']?.toString() != currentUserId).toList();

         return services.map<ServiceProvider>((s) => ServiceListing(
           id: s['serviceId'].toString(),
           providerId: s['ownerId']?.toString(),
           name: s['ownerName'] ?? s['businessName'] ?? 'Unknown Owner',
           serviceName: s['serviceType'],
           distance: 'Pending',
           rating: (s['rating'] ?? 5.0).toDouble(),
           approvalStatus: s['approvalStatus'] ?? 'Pending',
           location: s['location'] ?? 'Unknown',
           equipmentUsed: s['equipmentUsed'] ?? 'Standard Tools',
           price: '₹${s['priceRate']}', // API just has priceRate, assume formatted by UI or string
           operatorIncluded: true, // Typical for services
           jobsCompleted: s['jobsCompleted'] ?? 0,
           image: s['imageUrl'],
           ownerProfileImage: s['ownerProfileImageUrl'],
         )).toList();
      } else if (widget.serviceKey == 'Farm Workers') {
         final workersRaw = await apiService.getWorkerGroups() as List;
         final workers = workersRaw.where((w) => w['ownerId']?.toString() != currentUserId).toList();

         return workers.map<ServiceProvider>((w) => FarmWorkerListing(
             id: w['groupId'].toString(),
             providerId: w['ownerId']?.toString(),
             name: w['ownerName'] ?? w['groupName'] ?? 'Unknown Leader',
             serviceName: 'Farm Workers',
             distance: 'Pending',
             rating: (w['rating'] ?? 5.0).toDouble(),
             approvalStatus: w['approvalStatus'] ?? 'Pending',
             location: w['location'] ?? 'Unknown',
             maleCount: (w['maleCount'] as num?)?.toInt() ?? 0,
             femaleCount: (w['femaleCount'] as num?)?.toInt() ?? 0,
             malePrice: (w['pricePerMale'] as num?)?.toInt() ?? 0,
             femalePrice: (w['pricePerFemale'] as num?)?.toInt() ?? 0,
             skills: w['skills'] ?? 'General Labor',
             roleDistribution: (w['roles'] as List<dynamic>?)?.map((r) => '${r['count']} ${r['gender']} - ${r['taskName']}').toList() ?? ['General Farming'],
             groupName: w['groupName'],
             image: w['imageUrl'],
             ownerProfileImage: w['ownerProfileImageUrl']
         )).toList();
      } else {
         return ProviderManager().getProvidersByService(widget.serviceKey);
      }
    } catch (e) {
      print('Error fetching providers for ${widget.serviceKey}: $e');
      // Fallback to local on error
      return ProviderManager().getProvidersByService(widget.serviceKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          if (['Owner', 'Provider'].contains(widget.userRole))
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: _buildAddButton(context),
            ),
        ],
      ),
      body: FutureBuilder<List<ServiceProvider>>(
        future: _providersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00AA55)));
          }

          if (snapshot.hasError) {
             return Center(child: Text('Error loading providers: ${snapshot.error}'));
          }

          final allProviders = snapshot.data ?? [];
          
          // --- Filter Logic ---
          // 1. Get Unique Locations from current providers
          final uniqueLocations = allProviders
              .map((p) => p.location)
              .where((loc) => loc.isNotEmpty)
              .toSet()
              .toList();
          uniqueLocations.sort();

          // 2. Get Makes/Brands from VehicleData
          // Determine the category for VehicleData based on serviceKey or service type.
          String dataCategory = widget.serviceKey;
          if (widget.serviceKey == 'Ploughing') dataCategory = 'Tractors';
          if (widget.serviceKey == 'Harvesting') dataCategory = 'Harvesters';
          if (widget.serviceKey == 'Tractor Trolley') dataCategory = 'Trolleys';
          
          final availableMakes = VehicleData.getMakes(dataCategory);

          // 3. Apply Filters
          final filteredProviders = allProviders.where((provider) {
            bool matchesMake = true;
            bool matchesLocation = true;

            if (_selectedMake != null && _selectedMake != 'All') {
               // Check appropriate field based on type
               if (provider is EquipmentListing) {
                 matchesMake = provider.brandModel.contains(_selectedMake!); 
               } else if (provider is TransportListing) {
                 matchesMake = provider.vehicleType.contains(_selectedMake!) || provider.name.contains(_selectedMake!); // Loose matching
               } else if (provider is ServiceListing) {
                 matchesMake = provider.equipmentUsed.contains(_selectedMake!);
               }
               // Farm Workers don't typically have "Makes" unless we filter by skills? Skipping for now.
            }

            if (_selectedLocation != null && _selectedLocation != 'All') {
              matchesLocation = provider.location == _selectedLocation;
            }

            return matchesMake && matchesLocation;
          }).toList();


          // Helper to get hint text
          String getMakeHint(String key) {
             if (key == 'Tractors' || key == 'Harvesters') return AppLocalizations.of(context)!.chooseMake;
             if (key == 'Sprayers' || key == 'Trolleys' || key == 'Rotavators') return AppLocalizations.of(context)!.chooseMake;
             if (['Mini Truck', 'Full Truck', 'Tractor Trolley', 'Pickup Van', 'Tempo', 'Container'].contains(key)) return AppLocalizations.of(context)!.chooseVehicle;
             return AppLocalizations.of(context)!.chooseEquipment; // Default
          }
          
          return Column(
            children: [
               // --- Filter Section ---
               Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), // Increased padding
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                 child: Row(
                   children: [
                     // Make Filter (Only show if we have makes available)
                     if (availableMakes.isNotEmpty && availableMakes.length > 1) ...[
                       Expanded(
                         flex: 3,
                         child: _buildDropdown(
                           hint: getMakeHint(widget.serviceKey),
                           value: _selectedMake,
                           items: ['All', ...availableMakes],
                           onChanged: (val) {
                             setState(() {
                               _selectedMake = val == 'All' ? null : val;
                             });
                           },
                         ),
                       ),
                       const SizedBox(width: 12),
                     ],
                     
                     // Location Filter
                     Expanded(
                       flex: 3, // Give equal or more space
                       child: _buildLocationDropdown( // New method for distinct style
                         hint: AppLocalizations.of(context)!.selectLocation,
                         value: _selectedLocation,
                         items: ['All', ...uniqueLocations],
                         onChanged: (val) {
                           setState(() {
                             _selectedLocation = val == 'All' ? null : val;
                           });
                         },
                       ),
                     ),
                   ],
                 ),
               ),
               
               // --- List Section ---
               Expanded(
                 child: filteredProviders.isEmpty
                 ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.of(context)!.noMatchFound, style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  )
                 : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProviders.length,
                    itemBuilder: (context, index) {
                      final provider = filteredProviders[index];
                      
                      if (provider is FarmWorkerListing) {
                        return Column(
                          children: [
                            _buildWorkerProviderCard(
                              context,
                              provider: provider,
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      } else if (provider is ServiceListing) {
                         return Column(
                           children: [
                             _buildServiceListingCard(context, provider),
                             const SizedBox(height: 16),
                           ],
                         );
                      } else if (provider is TransportListing) {
                         return Column(
                           children: [
                             _buildTransportListingCard(context, provider),
                             const SizedBox(height: 16),
                           ],
                         );
                      } else if (provider is EquipmentListing) {
                         return Column(
                           children: [
                             _buildEquipmentListingCard(context, provider),
                             const SizedBox(height: 16),
                           ],
                         );
                      } else {
                         return const SizedBox(); // Fallback
                      }
                    },
                  ),
               ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDropdown({
    required String hint, 
    required String? value, 
    required List<String> items, 
    required Function(String?) onChanged
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[600], fontSize: 13), overflow: TextOverflow.ellipsis),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLocationDropdown({
    required String hint, 
    required String? value, 
    required List<String> items, 
    required Function(String?) onChanged
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6), // Slight grey background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent) // No border, just background or different style
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 16, color: Color(0xFF00AA55)), // Location Icon
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(hint, style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 20),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssetDetails(BuildContext context, ServiceProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AssetDetailModal(
        provider: provider,
        onBookNow: () {
          Navigator.pop(context);
          _navigateToBooking(context, provider);
        },
      ),
    );
  }

  // --- CARDS ---

  Widget _buildWorkerProviderCard(BuildContext context, {required FarmWorkerListing provider}) {
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showFullImage(context, provider.ownerProfileImage, provider.name),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue[100],
                        backgroundImage: provider.ownerProfileImage != null
                            ? NetworkImage(ApiConfig.getFullImageUrl(provider.ownerProfileImage))
                            : null,
                        child: provider.ownerProfileImage == null
                            ? const Icon(Icons.person, size: 28, color: Colors.blue)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (provider.groupName != null && provider.groupName!.isNotEmpty && provider.groupName != provider.name) ...[
                             const SizedBox(height: 2),
                             Text(
                               provider.groupName!,
                               style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500),
                               overflow: TextOverflow.ellipsis,
                             ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildRatingBadge(provider.rating),
            ],
          ),
          const SizedBox(height: 8),
          _buildDistanceRow(provider.distance),
           if (provider.location.isNotEmpty) ...[
             const SizedBox(height: 4),
             Text(provider.location, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
          if (provider.image != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showAssetDetails(context, provider),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  ApiConfig.getFullImageUrl(provider.image),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Skills
          Text(provider.skills, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
           
          // Role Distribution
          if (provider.roleDistribution.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: provider.roleDistribution.map((role) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context)!.male, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${provider.maleCount} Available', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹${provider.malePrice} ${AppLocalizations.of(context)!.perDay}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              Expanded(
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context)!.female, style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${provider.femaleCount} Available', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹${provider.femalePrice} ${AppLocalizations.of(context)!.perDay}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
           const SizedBox(height: 20),
           SizedBox(
             width: double.infinity,
             child: ElevatedButton(
                onPressed: () async {
                   final prefs = await SharedPreferences.getInstance();
                   final currentUserId = prefs.getString('user_id');
                   final actualProviderId = provider.providerId ?? currentUserId ?? '1';
                   if (!context.mounted) return;

                   Navigator.push(context, MaterialPageRoute(builder: (context) => BookWorkersScreen(
                     providerName: provider.name,
                     providerId: actualProviderId,
                     assetId: provider.id,
                     maxMale: provider.maleCount,
                     maxFemale: provider.femaleCount,
                     priceMale: provider.malePrice,
                     priceFemale: provider.femalePrice,
                     roleDistribution: provider.roleDistribution,
                   )));
                },
                style: _primaryButtonStyle(),
                child: Text(AppLocalizations.of(context)!.bookWorkers),
              ),
           ),
        ],
      ),
    );
  }

  Widget _buildServiceListingCard(BuildContext context, ServiceListing provider) {
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showFullImage(context, provider.ownerProfileImage, provider.name),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.green[50],
                        backgroundImage: provider.ownerProfileImage != null
                            ? NetworkImage(ApiConfig.getFullImageUrl(provider.ownerProfileImage))
                            : null,
                        child: provider.ownerProfileImage == null
                            ? const Icon(Icons.person, size: 28, color: Colors.green)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            provider.equipmentUsed, // e.g., Tractor Model
                            style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.isAvailable) _buildAvailableBadge(context),
            ],
          ),
          if (provider.image != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showAssetDetails(context, provider),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  ApiConfig.getFullImageUrl(provider.image),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRatingBadge(provider.rating),
              const SizedBox(width: 16),
              _buildDistanceRow(provider.distance),
               const SizedBox(width: 16),
              Text('${provider.jobsCompleted} ${AppLocalizations.of(context)!.jobsCompleted}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          if (provider.operatorIncluded)
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(AppLocalizations.of(context)!.operatorIncluded, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),

          const SizedBox(height: 16),
          const Divider(height: 1), 
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                provider.price,
                style: const TextStyle(
                  color: Color(0xFF00C853), 
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () => _navigateToBooking(context, provider),
                style: _bookButtonStyle(),
                child: Text(AppLocalizations.of(context)!.bookService, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransportListingCard(BuildContext context, TransportListing provider) {
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showFullImage(context, provider.ownerProfileImage, provider.name),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue[50],
                        backgroundImage: provider.ownerProfileImage != null
                            ? NetworkImage(ApiConfig.getFullImageUrl(provider.ownerProfileImage))
                            : null,
                        child: provider.ownerProfileImage == null
                            ? const Icon(Icons.person, size: 28, color: Colors.blue)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${provider.vehicleType} • ${provider.loadCapacity}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[800], fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.isAvailable) _buildAvailableBadge(context),
            ],
          ),
          if (provider.image != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showAssetDetails(context, provider),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  ApiConfig.getFullImageUrl(provider.image),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _buildRatingBadge(provider.rating),
              const SizedBox(width: 16),
              _buildDistanceRow(provider.distance),
               const SizedBox(width: 16),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                 decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                 child: Text(AppLocalizations.of(context)!.driverIncluded, style: const TextStyle(fontSize: 10, color: Colors.blue)),
               ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(height: 1), 
          const SizedBox(height: 16),

           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                provider.price,
                style: const TextStyle(
                  color: Colors.black87, 
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () => _navigateToBooking(context, provider),
                style: _bookButtonStyle(),
                child: Text(AppLocalizations.of(context)!.bookNow, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentListingCard(BuildContext context, EquipmentListing provider) {
     return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showFullImage(context, provider.ownerProfileImage, provider.name),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.orange[50],
                        backgroundImage: provider.ownerProfileImage != null
                            ? NetworkImage(ApiConfig.getFullImageUrl(provider.ownerProfileImage))
                            : null,
                        child: provider.ownerProfileImage == null
                            ? const Icon(Icons.person, size: 28, color: Colors.orange)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.name, // Owner Name
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            provider.brandModel,
                            style: TextStyle(fontSize: 13, color: Colors.grey[800], fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.isAvailable) _buildAvailableBadge(context),
            ],
          ),
          if (provider.image != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showAssetDetails(context, provider),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  ApiConfig.getFullImageUrl(provider.image),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
             children: [
                _buildRatingBadge(provider.rating),
                const SizedBox(width: 16),
                _buildDistanceRow(provider.distance),
                 const SizedBox(width: 16),
                Container(
                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                   decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(4)),
                   child: Text(provider.condition, style: const TextStyle(fontSize: 10, color: Colors.orange)),
                 ),
             ],
          ),
          const SizedBox(height: 8),
          Text(
            provider.operatorAvailable ? AppLocalizations.of(context)!.withOperatorAvailable : AppLocalizations.of(context)!.noOperator,
             style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          
          const SizedBox(height: 16),
          const Divider(height: 1), 
          const SizedBox(height: 16),

           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                provider.price,
                 style: const TextStyle(
                  color: Color(0xFF00AA55), 
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () => _navigateToBooking(context, provider),
                style: _bookButtonStyle(),
                child: Text(AppLocalizations.of(context)!.rentNow, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildBaseCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildRatingBadge(double rating) {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 18),
        const SizedBox(width: 4),
        Text(
          rating.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDistanceRow(String distance) {
    return Row(
      children: [
        Icon(Icons.location_on_outlined, color: Colors.grey[500], size: 18),
        const SizedBox(width: 4),
        Text(
          distance,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildAvailableBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
        color: Colors.green.withOpacity(0.05),
      ),
      child: Text(
        AppLocalizations.of(context)!.available,
        style: const TextStyle(
          color: Colors.green,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF00AA55),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

   ButtonStyle _bookButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0A0E21), 
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      minimumSize: const Size(0, 40),
    );
  }
  
  // --- NAVIGATION ---

  void _navigateToBooking(BuildContext context, ServiceProvider provider) async {
      double rate = 0;
      // Extract numeric rate
      String priceString = '';
      if (provider is ServiceListing) priceString = provider.price;
      if (provider is TransportListing) priceString = provider.price;
      if (provider is EquipmentListing) priceString = provider.price;

      try {
        rate = double.parse(priceString.replaceAll(RegExp(r'[^0-9.]'), ''));
      } catch (e) {
        rate = 0;
      }

      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');
      final actualProviderId = provider.providerId ?? currentUserId ?? '1';

      if (!context.mounted) return;

      if (provider is TransportListing) {
         Navigator.push(context, MaterialPageRoute(builder: (context) => BookTransportDetailScreen(
           providerName: provider.name,
           vehicleType: provider.vehicleType,
           providerId: actualProviderId,
           assetId: provider.id,
           rate: rate > 0 ? rate : 1500,
           ownerProfileImage: provider.ownerProfileImage,
         )));
      } else if (provider is EquipmentListing) {
         Navigator.push(context, MaterialPageRoute(builder: (context) => BookEquipmentDetailScreen(
           providerName: provider.name,
           equipmentType: provider.serviceName, // Or Brand Model
           providerId: actualProviderId,
           assetId: provider.id,
           rate: rate > 0 ? rate : 500,
           ownerProfileImage: provider.ownerProfileImage,
         )));
      } else {
         // Service Listing (Ploughing, Harvesting...)
         Navigator.push(context, MaterialPageRoute(builder: (context) => BookServiceDetailScreen(
           providerName: provider.name,
           serviceName: provider.serviceName,
           providerId: actualProviderId,
           assetId: provider.id,
           priceInfo: priceString,
           ownerProfileImage: provider.ownerProfileImage,
         )));
      }
  }

  Widget _buildAddButton(BuildContext context) {
    // Localized Logic for category using English keys or separate logic?
    // Using simple logic for now, titles localized in button label
    String label = AppLocalizations.of(context)!.addListing;
    String category = 'Service'; 

    const transportKeys = ['Mini Truck', 'Tractor Trolley', 'Full Truck', 'Tempo', 'Pickup Van', 'Container'];
    const equipmentKeys = ['Tractors', 'Harvesters', 'Sprayers', 'Trolleys'];

    if (widget.serviceKey == 'Farm Workers') {
      label = AppLocalizations.of(context)!.addGroup;
      category = 'Farm Workers';
    } else if (transportKeys.contains(widget.serviceKey)) {
      label = AppLocalizations.of(context)!.addVehicle;
      category = 'Transport';
    } else if (equipmentKeys.contains(widget.serviceKey)) {
      label = AppLocalizations.of(context)!.addEquipment;
      category = 'Equipment';
    } else {
      label = AppLocalizations.of(context)!.addService;
      category = widget.serviceKey;
    }

    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => UploadItemScreen(category: category)));
      },
      icon: const Icon(Icons.add, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00AA55),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 32),
      ),
    );
  }
}

void _showFullImage(BuildContext context, String? imageUrl, String title) {
  if (imageUrl == null || imageUrl.isEmpty) return;
  
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                ApiConfig.getFullImageUrl(imageUrl),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(40),
                  child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AssetDetailModal extends StatelessWidget {
  final ServiceProvider provider;
  final VoidCallback onBookNow;

  const _AssetDetailModal({required this.provider, required this.onBookNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  GestureDetector(
                    onTap: () => _showFullImage(context, provider.image, provider.serviceName),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        ApiConfig.getFullImageUrl(provider.image),
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 220,
                          color: Colors.grey[100],
                          child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                 GestureDetector(
                                  onTap: () => _showFullImage(context, provider.ownerProfileImage, provider.name),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundImage: provider.ownerProfileImage != null
                                        ? NetworkImage(ApiConfig.getFullImageUrl(provider.ownerProfileImage))
                                        : null,
                                    child: provider.ownerProfileImage == null
                                        ? const Icon(Icons.person, size: 24)
                                        : null,
                                  ),
                                ),

                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    provider.name,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              provider.serviceName,
                              style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 18, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(provider.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Specific Details Based on Type (Now includes Location, Jobs Done, and Distance)
                  if (provider is EquipmentListing) _buildEquipmentDetails(context, provider as EquipmentListing),
                  if (provider is TransportListing) _buildTransportDetails(context, provider as TransportListing),
                  if (provider is FarmWorkerListing) _buildWorkerDetails(context, provider as FarmWorkerListing),
                  if (provider is ServiceListing) _buildServiceDetails(context, provider as ServiceListing),
                  
                  const SizedBox(height: 30),
                  
                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: onBookNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AA55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        (provider is FarmWorkerListing) 
                          ? AppLocalizations.of(context)!.bookNow 
                          : AppLocalizations.of(context)!.rentNow, 
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentDetails(BuildContext context, EquipmentListing item) {
    return Column(
      children: [
        _buildDetailRow(Icons.construction, 'Brand & Model', item.brandModel),
        _buildDetailRow(Icons.info_outline, 'Condition', item.condition),
        if (item.yearOfManufacture != null)
           _buildDetailRow(Icons.calendar_today, 'Year', item.yearOfManufacture!),
        _buildDetailRow(Icons.person_outline, 'Operator', item.operatorAvailable ? 'Available (Included/Extra)' : 'Not Provided'),
        _buildDetailRow(Icons.payments_outlined, 'Price Rate', item.price),
        _buildDetailRow(Icons.location_on_outlined, AppLocalizations.of(context)!.locationLabel, item.location.isNotEmpty ? item.location : 'Village Area'),
        _buildDetailRow(Icons.history, 'Jobs Done', '${item.jobsCompleted} ${AppLocalizations.of(context)!.jobsCompleted}'),
        _buildDetailRow(Icons.social_distance_outlined, 'Distance', item.distance),
      ],
    );
  }

  Widget _buildTransportDetails(BuildContext context, TransportListing item) {
    return Column(
      children: [
        _buildDetailRow(Icons.local_shipping_outlined, 'Vehicle Type', item.vehicleType),
        _buildDetailRow(Icons.fitness_center, 'Load Capacity', item.loadCapacity),
        _buildDetailRow(Icons.person_pin_circle_outlined, 'Driver', item.driverIncluded ? 'Included in Price' : 'Customer Must Provide'),
        if (item.serviceArea != null)
           _buildDetailRow(Icons.map_outlined, 'Service Area', item.serviceArea!),
        _buildDetailRow(Icons.payments_outlined, 'Rental Rate', item.price),
        _buildDetailRow(Icons.location_on_outlined, AppLocalizations.of(context)!.locationLabel, item.location.isNotEmpty ? item.location : 'Village Area'),
        _buildDetailRow(Icons.history, 'Jobs Done', '${item.jobsCompleted} ${AppLocalizations.of(context)!.jobsCompleted}'),
        _buildDetailRow(Icons.social_distance_outlined, 'Distance', item.distance),
      ],
    );
  }

  Widget _buildWorkerDetails(BuildContext context, FarmWorkerListing item) {
    return Column(
      children: [
        if (item.groupName != null && item.groupName!.isNotEmpty)
          _buildDetailRow(Icons.business_outlined, 'Group Name', item.groupName!),
        _buildDetailRow(Icons.people_outline, 'Total Group', '${item.maleCount + item.femaleCount} Workers'),
        _buildDetailRow(Icons.male, 'Male Workers', '${item.maleCount} Staff (₹${item.malePrice}/day)'),
        _buildDetailRow(Icons.female, 'Female Workers', '${item.femaleCount} Staff (₹${item.femalePrice}/day)'),
        _buildDetailRow(Icons.psychology_outlined, 'Skills Offered', item.skills),
        _buildDetailRow(Icons.location_on_outlined, AppLocalizations.of(context)!.locationLabel, item.location.isNotEmpty ? item.location : 'Village Area'),
        _buildDetailRow(Icons.history, 'Jobs Done', '${item.jobsCompleted} ${AppLocalizations.of(context)!.jobsCompleted}'),
        _buildDetailRow(Icons.social_distance_outlined, 'Distance', item.distance),
        const SizedBox(height: 12),
        const Text('Role Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: item.roleDistribution.map((role) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Text(role, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildServiceDetails(BuildContext context, ServiceListing item) {
    return Column(
      children: [
        _buildDetailRow(Icons.settings_outlined, 'Tools Used', item.equipmentUsed),
        _buildDetailRow(Icons.person_outline, 'Operator', item.operatorIncluded ? 'Expert Provided' : 'Only Machine'),
        _buildDetailRow(Icons.payments_outlined, 'Service Charge', item.price),
        _buildDetailRow(Icons.location_on_outlined, AppLocalizations.of(context)!.locationLabel, item.location.isNotEmpty ? item.location : 'Village Area'),
        _buildDetailRow(Icons.history, 'Jobs Done', '${item.jobsCompleted} ${AppLocalizations.of(context)!.jobsCompleted}'),
        _buildDetailRow(Icons.social_distance_outlined, 'Distance', item.distance),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: const Color(0xFF00AA55)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
