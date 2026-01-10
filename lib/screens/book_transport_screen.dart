import 'package:flutter/material.dart';

import 'upload_item_screen.dart';
import 'generic_history_screen.dart';
import 'service_providers_screen.dart';
import '../utils/booking_manager.dart';

class BookTransportScreen extends StatelessWidget {
  final String? userRole;
  const BookTransportScreen({super.key, this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Book Transport',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          if (userRole != null && userRole != 'General User')
             Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadItemScreen(category: 'Transport')));
                },
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Upload', style: TextStyle(color: Colors.white)),
                 style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AA55),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const GenericHistoryScreen(
                  title: 'My Transports',
                  categories: [BookingCategory.transport],
                )));
              },
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
              'Choose Vehicle Type',
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
                childAspectRatio: 0.8, // Taller for capacity text
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                   _buildVehicleCard(context, 'Mini Truck', '1-2 tons', Icons.local_shipping, const Color(0xFFE3F2FD), Colors.blue),
                   _buildVehicleCard(context, 'Tractor Trolley', '2-3 tons', Icons.agriculture, const Color(0xFFE8F5E9), Colors.green),
                   _buildVehicleCard(context, 'Full Truck', '5-10 tons', Icons.local_shipping_outlined, const Color(0xFFFFF3E0), Colors.orange),
                   _buildVehicleCard(context, 'Tempo', '500kg-1 ton', Icons.airport_shuttle, const Color(0xFFFFF9C4), Colors.amber[800]!),
                   _buildVehicleCard(context, 'Pickup Van', '300-500 kg', Icons.fire_truck, const Color(0xFFF3E5F5), Colors.purple), 
                   _buildVehicleCard(context, 'Container', '10+ tons', Icons.inventory, const Color(0xFFEFEBE9), Colors.brown),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, String title, String capacity, IconData icon, Color bgColor, Color iconColor) {
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
          onTap: () => _showBookingDialog(context, title),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Container(
                height: 70,
                width: 70,
                 decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 36, color: iconColor),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
               Text(
                capacity,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context, String vehicleType) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceProvidersScreen(serviceName: vehicleType)));
  }
}
