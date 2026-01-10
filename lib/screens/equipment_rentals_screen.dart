import 'package:flutter/material.dart';

import 'upload_item_screen.dart';
import 'generic_history_screen.dart';
import 'service_providers_screen.dart';
import '../utils/booking_manager.dart';

class EquipmentRentalsScreen extends StatelessWidget {
  final String? userRole;
  const EquipmentRentalsScreen({super.key, this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // As per image
      appBar: AppBar(
        title: const Text(
          'Equipment Rentals',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (userRole != null && userRole != 'General User')
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadItemScreen(category: 'Equipment')));
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
        ],
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView( // Need scrolling for list below grid
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle Header
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                            )
                          ],
                        ),
                        child: const Text(
                          'Rent Equipment',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const GenericHistoryScreen(
                            title: 'My Rentals',
                            categories: [BookingCategory.rentals],
                          )));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'My Rentals',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Browse Equipment
              const Text(
                'Browse Equipment',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              // Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true, // Vital for nesting in SingleChildScrollView
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.9,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                   _buildEquipmentCard(context, 'Tractors', '24 available', Icons.agriculture, Colors.green[50]!, Colors.green),
                   _buildEquipmentCard(context, 'Harvesters', '12 available', Icons.grass, Colors.yellow[50]!, Colors.orange),
                   _buildEquipmentCard(context, 'Sprayers', '18 available', Icons.water_drop, Colors.blue[50]!, Colors.blue),
                   _buildEquipmentCard(context, 'Trolleys', '15 available', Icons.shopping_cart_outlined, Colors.grey[100]!, Colors.grey), // Placeholder
                ],
              ),

              const SizedBox(height: 24),

              // Nearby Equipment
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nearby Equipment',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),

              // Nearby Item Card - Make clickable too?
              GestureDetector(
                onTap: () => _showBookingDialog(context, 'Mahindra Tractor 575 DI'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mahindra Tractor 575 DI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[50], // Light green bg for available
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Text(
                              'Available',
                              style: TextStyle(color: Colors.green, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                       Row(
                        children: const [
                           Text(
                            '₹500 per hour',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(width: 8),
                           Icon(Icons.star, size: 16, color: Colors.amber),
                           Text('4.7', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                           Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                           const SizedBox(width: 4),
                           Text(
                            'Suresh Patel • 4 km',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(BuildContext context, String title, String subtitle, IconData icon, Color bgColor, Color iconColor) {
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
           )
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showBookingDialog(context, title),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Center(
                   child: Container(
                    height: 60,
                    width: 60,
                    // No background in this specific design if matching exactly, but consistent look is better
                    decoration: BoxDecoration( 
                      color: bgColor.withOpacity(0.3), 
                      borderRadius: BorderRadius.circular(15), 
                    ),
                    child: Icon(icon, size: 32, color: iconColor), 
                   ),
                 ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                 Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[700], // Green text for availability as per standard or user pref
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context, String equipmentName) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceProvidersScreen(serviceName: equipmentName)));
  }
}
