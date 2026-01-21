import 'package:flutter/material.dart';

import 'upload_item_screen.dart';
import 'book_workers_screen.dart';
import 'book_transport_detail_screen.dart';
import 'book_equipment_detail_screen.dart';
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
                   Text('No providers found for $title', style: TextStyle(color: Colors.grey[600])),
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
                    const Text('Male', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${provider.maleCount} Available', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹${provider.malePrice} / day', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              Expanded(
                child: Column(
                  children: [
                    const Text('Female', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${provider.femaleCount} Available', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹${provider.femalePrice} / day', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
                child: const Text('Book Workers'),
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
              if (provider.isAvailable) _buildAvailableBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRatingBadge(provider.rating),
              const SizedBox(width: 16),
              _buildDistanceRow(provider.distance),
               const SizedBox(width: 16),
              Text('${provider.jobsCompleted} done', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          if (provider.operatorIncluded)
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Operator Included', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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
                child: const Text('Book Service', style: TextStyle(fontWeight: FontWeight.w600)),
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
              if (provider.isAvailable) _buildAvailableBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildRatingBadge(provider.rating),
              const SizedBox(width: 16),
              _buildDistanceRow(provider.distance),
               const SizedBox(width: 16),
               if (provider.fuelIncluded) 
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                   decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                   child: const Text('Fuel Inc.', style: TextStyle(fontSize: 10, color: Colors.blue)),
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
                child: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.w600)),
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
              if (provider.isAvailable) _buildAvailableBadge(),
            ],
          ),
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
            provider.operatorAvailable ? 'With Operator Available' : 'No Operator',
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
                child: const Text('Rent Now', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildAvailableBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
        color: Colors.green.withOpacity(0.05),
      ),
      child: const Text(
        'Available',
        style: TextStyle(
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
         // Service Listing (Ploughing, etc.) uses fallback dialog for now as we don't have a screen for it in the plan explicitly other than 'listings'
         // But wait, the plan said "Update/Create Service model" and "Ploughing/Harvesting Listing Screen".
         // Use the legacy dialog for 'Book Services' general booking or create a simple detail screen?
         // For now, use dialog but make it smarter.
         _showBookingDialog(context, provider, priceString);
      }
  }

  void _showBookingDialog(BuildContext context, ServiceProvider provider, String price) {
     final field1Controller = TextEditingController();
     final field2Controller = TextEditingController();
     String selectedDate = DateTime.now().add(const Duration(days: 1)).toString().split(' ')[0];
     
     String label1 = 'Details';
     String label2 = 'Additional Info';
     String service = provider.serviceName;

     if (provider is ServiceListing) {
        label1 = 'Acres / Hours';
        label2 = 'Special Instructions';
     }

     showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Book $service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Provider: ${provider.name}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Text('Rate: $price', style: TextStyle(color: Colors.green[700], fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: field1Controller,
                decoration: InputDecoration(labelText: label1, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: field2Controller,
                decoration: InputDecoration(labelText: label2, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                   const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                   const SizedBox(width: 8),
                   Text('Date: $selectedDate', style: const TextStyle(color: Colors.black87)),
                ],
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
               if (field1Controller.text.isNotEmpty) {
                 BookingManager().addBooking(BookingDetails(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: '$service Booking',
                    date: selectedDate,
                    price: 'On Request', // Calculate if possible
                    status: 'Pending',
                    category: BookingCategory.services,
                    details: {
                      'provider': provider.name,
                      label1: field1Controller.text,
                      label2: field2Controller.text,
                    },
                    providerId: provider.id
                 ));
                 Navigator.pop(ctx);
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking Request Sent to Provider!'), backgroundColor: Colors.green)
                 );
               }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A0E21), foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    String label = 'Add Listing';
    String category = 'Service'; // Default

    // Logic to determine Category and Label based on serviceKey
    // Lists synchronized with UploadItemScreen mocks or known keys
    const transportKeys = ['Mini Truck', 'Tractor Trolley', 'Full Truck', 'Tempo', 'Pickup Van', 'Container'];
    const equipmentKeys = ['Tractors', 'Harvesters', 'Sprayers', 'Trolleys'];

    if (serviceKey == 'Farm Workers') {
      label = 'Add Group';
      category = 'Farm Workers';
    } else if (transportKeys.contains(serviceKey)) {
      label = 'Add Vehicle';
      category = 'Transport';
    } else if (equipmentKeys.contains(serviceKey)) {
      label = 'Add Equipment';
      category = 'Equipment';
    } else {
      // Default Services (Ploughing, Harvesting...)
      label = 'Add Service';
      category = serviceKey; // Pass the specific service name (e.g. 'Ploughing')
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
