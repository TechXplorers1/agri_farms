import 'package:flutter/material.dart';

import 'upload_item_screen.dart';
import 'book_workers_screen.dart';
import 'book_transport_detail_screen.dart'; // Import Transport Detail
import 'book_equipment_detail_screen.dart'; // Import Equipment Detail
import '../utils/provider_manager.dart';
import '../utils/booking_manager.dart';

class ServiceProvidersScreen extends StatelessWidget {
  final String serviceName;
  final String? userRole;

  const ServiceProvidersScreen({super.key, required this.serviceName, this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          serviceName,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          if (serviceName == 'Farm Workers' && userRole == 'Farmer')
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadItemScreen(category: 'Farm Workers')));
                },
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Add Group', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AA55),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: ProviderManager(),
        builder: (context, _) {
          final providers = ProviderManager().getProvidersByService(serviceName);

          if (providers.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                   const SizedBox(height: 16),
                   Text('No providers found for $serviceName', style: TextStyle(color: Colors.grey[600])),
                 ],
               ),
             );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              
              if (serviceName == 'Farm Workers') {
                return Column(
                  children: [
                    _buildWorkerProviderCard(
                      context,
                      name: provider.name,
                      maleCount: provider.maleCount ?? 0,
                      femaleCount: provider.femaleCount ?? 0,
                      malePrice: provider.malePrice ?? 0,
                      femalePrice: provider.femalePrice ?? 0,
                      distance: provider.distance ?? 'N/A',
                      rating: provider.rating ?? 0.0,
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              } else {
                 return Column(
                   children: [
                     _buildProviderCard(
                      context, // Pass context for dialog
                      providerId: provider.id,
                      name: provider.name,
                      service: provider.serviceName,
                      rating: provider.rating ?? 0.0,
                      distance: provider.distance ?? 'N/A',
                      jobs: provider.jobs ?? 0,
                      price: provider.price ?? 'N/A',
                      isAvailable: provider.isAvailable ?? true,
                    ),
                    const SizedBox(height: 16),
                   ],
                 );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildProviderCard(
    BuildContext context, {
    required String providerId,
    required String name,
    required String service,
    required double rating,
    required String distance,
    required int jobs,
    required String price,
    required bool isAvailable,
  }) {
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
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (isAvailable)
                Container(
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
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                rating.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Icon(Icons.location_on_outlined, color: Colors.grey[500], size: 18),
              const SizedBox(width: 4),
              Text(
                distance,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Text(
                '$jobs jobs',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Colors.grey), 
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: Color(0xFF00C853), // Bright Green
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                   _navigateToBooking(context, service, name, providerId, price);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0E21), 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  minimumSize: const Size(0, 40),
                ),
                child: const Text('Book Service', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToBooking(BuildContext context, String service, String providerName, String providerId, String priceString) {
      double rate = 0;
      // Simple parse of price string "₹500" or "₹2000" etc.
      try {
        rate = double.parse(priceString.replaceAll(RegExp(r'[^0-9.]'), ''));
      } catch (e) {
        rate = 0;
      }

      // Identify categories based on known strings (should be improved with enums ideally)
      final transportList = ['Mini Truck', 'Tractor Trolley', 'Full Truck', 'Tempo', 'Pickup Van', 'Container'];
      final equipmentList = ['Tractors', 'Harvesters', 'Sprayers', 'Trolleys'];

      if (transportList.contains(service)) {
         Navigator.push(context, MaterialPageRoute(builder: (context) => BookTransportDetailScreen(
           providerName: providerName,
           vehicleType: service,
           providerId: providerId,
           rate: rate > 0 ? rate : 1500, // Default fallback
         )));
      } else if (equipmentList.contains(service)) {
         Navigator.push(context, MaterialPageRoute(builder: (context) => BookEquipmentDetailScreen(
           providerName: providerName,
           equipmentType: service,
           providerId: providerId,
           rate: rate > 0 ? rate : 500, // Default fallback
         )));
      } else {
         // Fallback to legacy dialog for other future services
         _showBookingDialog(context, service, providerName, providerId);
      }
  }

  void _showBookingDialog(BuildContext context, String service, String providerName, String providerId) {
     // reuse booking manager import from somewhere? Need to import it if not present
     // Actually this file imports 'book_workers_screen.dart' and 'provider_manager.dart'
     // We need to import 'booking_manager.dart' to add bookings.
     // But wait, I can just show the dialog here.

     final field1Controller = TextEditingController();
     final field2Controller = TextEditingController();
     String selectedDate = DateTime.now().add(const Duration(days: 1)).toString().split(' ')[0];
     
     // Determine fields based on service type broad categories
     String label1 = 'Details';
     String label2 = 'Additional Info';
     
     // Simple heuristic
     bool isTransport = ['Mini Truck', 'Tractor Trolley', 'Full Truck', 'Tempo', 'Pickup Van', 'Container'].contains(service);
     if (isTransport) {
       label1 = 'Pickup Location';
       label2 = 'Drop Location';
     } else {
       label1 = 'Duration (Hours/Days)';
       label2 = 'Task Type';
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
              Text('Provider: $providerName', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
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
                    price: 'On Request',
                    status: 'Pending',
                    category: BookingCategory.services, // Or mapped correctly
                    details: {
                      'provider': providerName,
                      label1: field1Controller.text,
                      label2: field2Controller.text,
                    },
                    providerId: providerId
                 ));
                 Navigator.pop(ctx);
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking Request Sent to Provider!'), backgroundColor: Colors.green)
                 );
               }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
  Widget _buildWorkerProviderCard(
    BuildContext context, {
    required String name,
    required int maleCount,
    required int femaleCount,
    required int malePrice,
    required int femalePrice,
    required String distance,
    required double rating,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
               Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: Colors.grey[500], size: 16),
              const SizedBox(width: 4),
              Text(distance, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          
          // Counts
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('Male', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('$maleCount Available', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹$malePrice / day', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              Expanded(
                child: Column(
                  children: [
                    const Text('Female', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('$femaleCount Available', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹$femalePrice / day', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
                     providerName: name,
                     maxMale: maleCount,
                     maxFemale: femaleCount,
                     priceMale: malePrice,
                     priceFemale: femalePrice,
                   )));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AA55),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Book Workers'),
              ),
           ),
        ],
      ),
    );
  }
}
