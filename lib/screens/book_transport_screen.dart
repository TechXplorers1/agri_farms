import 'package:flutter/material.dart';
import 'upload_item_screen.dart';
import 'service_providers_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BookTransportScreen extends StatelessWidget {
  final String? userRole;
  const BookTransportScreen({super.key, this.userRole});

  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
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
          if (userRole != null && ['Owner', 'Provider'].contains(userRole))
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
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bookTransport,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                   _buildVehicleCard(context, 'Mini Truck', l10n.miniTruck, 'assets/images/transport_truck_card.png', '1-2 tons'),
                   _buildVehicleCard(context, 'Tractor Trolley', l10n.tractorTrolley, 'assets/images/tractor_trolley_card.png', '2-3 tons'),
                   _buildVehicleCard(context, 'Full Truck', l10n.fullTruck, 'assets/images/full_truck_card.png', '5-10 tons'),
                   _buildVehicleCard(context, 'Tempo', l10n.tempo, 'assets/images/tractor_trolley_card.png', '500kg-1 ton'),
                   _buildVehicleCard(context, 'Pickup Van', l10n.pickupVan, 'assets/images/pickup_van_card.png', '300-500 kg'), 
                   _buildVehicleCard(context, 'Container', l10n.container, 'assets/images/full_truck_card.png', '10+ tons'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, String serviceKey, String title, String imagePath, String subtitle) {
    return GestureDetector(
      onTap: () => _showBookingDialog(context, serviceKey, title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.orange[50])),
            DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.68)],
              stops: const [0.35, 1.0],
            ))),
            Positioned(left: 12, right: 8, bottom: 10, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, height: 1.1), maxLines: 2),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w400)),
            ])),
          ]),
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context, String vehicleType, String displayTitle) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceProvidersScreen(serviceKey: vehicleType, title: displayTitle)));
  }
}
