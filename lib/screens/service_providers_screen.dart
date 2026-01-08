import 'package:flutter/material.dart';

class ServiceProvidersScreen extends StatelessWidget {
  final String serviceName;

  const ServiceProvidersScreen({super.key, required this.serviceName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Service Providers',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
}
