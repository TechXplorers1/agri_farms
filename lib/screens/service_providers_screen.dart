import 'package:flutter/material.dart';

import 'upload_item_screen.dart';
import 'upload_item_screen.dart';
import 'book_workers_screen.dart';
import '../utils/provider_manager.dart';

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
          if (serviceName == 'Farm Workers' && userRole == 'Farm Worker')
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
          if (serviceName == 'Farm Workers') {
            final providers = ProviderManager().getProvidersByService('Farm Workers');
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: providers.length,
              itemBuilder: (context, index) {
                final provider = providers[index];
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
              },
            );
          }
          
          return ListView(
        padding: const EdgeInsets.all(16),
        children: [
            // Default Service Providers
            _buildProviderCard(
            name: 'Ramesh Services',
            service: 'Ploughing',
            rating: 4.8,
            distance: '3 km',
            jobs: 156,
            price: '₹800 per acre',
            isAvailable: true,
          ),
          const SizedBox(height: 16),
          _buildProviderCard(
            name: 'Green Agri Solutions',
            service: 'Drone Spraying',
            rating: 4.9,
            distance: '5 km',
            jobs: 89,
            price: '₹600 per acre',
            isAvailable: true,
          ),
          // Additional static items for variety
           const SizedBox(height: 16),
           _buildProviderCard(
            name: 'Kisan Help Group',
            service: 'Harvesting',
            rating: 4.5,
            distance: '2 km',
            jobs: 210,
            price: '₹1200 per hour',
            isAvailable: true,
          ),
          ],
        ); // End of non-worker ListView
        },
      ),
    );
  }

  Widget _buildProviderCard({
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
          const Divider(height: 1, color: Colors.grey), // Optional divider or just spacing, design has none, but spacing exists
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
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0E21), // Dark Navy/Black like image
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
                    const Icon(Icons.male, color: Colors.blue, size: 28),
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
                    const Icon(Icons.female, color: Colors.pink, size: 28),
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
