import 'package:flutter/material.dart';

class AgriServicesScreen extends StatelessWidget {
  const AgriServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Agri Services',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.grey[300]!),
                foregroundColor: Colors.black87,
              ),
              child: const Text('My Bookings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.normal)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a Service',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 0.85, // Adjust aspect ratio to prevent overflow and look better
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                   _buildServiceCard('Ploughing', Icons.agriculture, const Color(0xFFE3F2FD), Colors.blue),
                   _buildServiceCard('Harvesting', Icons.grass, const Color(0xFFFFF9C4), Colors.orange), // Yellowish bg
                   _buildServiceCard('Drone Spraying', Icons.airplanemode_active, const Color(0xFFE8F5E9), Colors.green),
                   _buildServiceCard('Irrigation', Icons.water_drop, const Color(0xFFE1F5FE), Colors.cyan),
                   _buildServiceCard('Soil Testing', Icons.science, const Color(0xFFF3E5F5), Colors.purple),
                   _buildServiceCard('Vet Care', Icons.pets, const Color(0xFFFCE4EC), Colors.pink),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20), // Squircle shape
                ),
                child: Icon(icon, size: 36, color: iconColor),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15, // Slightly smaller than 16 to fit better
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
