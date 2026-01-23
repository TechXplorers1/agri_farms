import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'upload_item_screen.dart';
import 'book_workers_screen.dart';
import 'book_transport_detail_screen.dart';
import 'book_equipment_detail_screen.dart';
import 'book_service_detail_screen.dart';
import '../utils/provider_manager.dart';
import '../utils/booking_manager.dart';

class ServiceProvidersScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          if (['Owner', 'Provider'].contains(userRole))
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: _buildAddButton(context),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: ProviderManager(),
        builder: (context, _) {
          final providers = ProviderManager().getProvidersByService(serviceKey);

          if (providers.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                   const SizedBox(height: 16),
                   Text(AppLocalizations.of(context)!.noMatchFound, style: TextStyle(color: Colors.grey[600])),
                 ],
               ),
             );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              
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
          );
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
              Text(
                provider.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                provider.image!,
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
          ],
          const SizedBox(height: 12),
          // Skills
          Text(provider.skills, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
          
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
                onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => BookWorkersScreen(
                     providerName: provider.name,
                     maxMale: provider.maleCount,
                     maxFemale: provider.femaleCount,
                     priceMale: provider.malePrice,
                     priceFemale: provider.femalePrice,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.equipmentUsed, // e.g., Tractor Model
                      style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (provider.isAvailable) _buildAvailableBadge(context),
            ],
          ),
          if (provider.image != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                provider.image!,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${provider.vehicleType} • ${provider.loadCapacity}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              if (provider.isAvailable) _buildAvailableBadge(context),
            ],
          ),
          if (provider.image != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                provider.image!,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name, // Owner Name
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.brandModel,
                      style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (provider.isAvailable) _buildAvailableBadge(context),
            ],
          ),
          if (provider.image != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                provider.image!,
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

  void _navigateToBooking(BuildContext context, ServiceProvider provider) {
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

      if (provider is TransportListing) {
         Navigator.push(context, MaterialPageRoute(builder: (context) => BookTransportDetailScreen(
           providerName: provider.name,
           vehicleType: provider.vehicleType,
           providerId: provider.id,
           rate: rate > 0 ? rate : 1500, 
         )));
      } else if (provider is EquipmentListing) {
         Navigator.push(context, MaterialPageRoute(builder: (context) => BookEquipmentDetailScreen(
           providerName: provider.name,
           equipmentType: provider.serviceName, // Or Brand Model
           providerId: provider.id,
           rate: rate > 0 ? rate : 500, 
         )));
      } else {
         // Service Listing (Ploughing, Harvesting...)
         Navigator.push(context, MaterialPageRoute(builder: (context) => BookServiceDetailScreen(
           providerName: provider.name,
           serviceName: provider.serviceName,
           providerId: provider.id,
           priceInfo: priceString,
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

    if (serviceKey == 'Farm Workers') {
      label = AppLocalizations.of(context)!.addGroup;
      category = 'Farm Workers';
    } else if (transportKeys.contains(serviceKey)) {
      label = AppLocalizations.of(context)!.addVehicle;
      category = 'Transport';
    } else if (equipmentKeys.contains(serviceKey)) {
      label = AppLocalizations.of(context)!.addEquipment;
      category = 'Equipment';
    } else {
      label = AppLocalizations.of(context)!.addService;
      category = serviceKey;
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
