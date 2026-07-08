import 'package:flutter/material.dart';
import 'upload_item_screen.dart';
import 'service_providers_screen.dart';
import 'package:agriculture/l10n/app_localizations.dart';
import '../utils/app_translations.dart';

class BookTransportScreen extends StatelessWidget {
  final String? userRole;
  const BookTransportScreen({super.key, this.userRole});

  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B5E20), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppTranslations.translate(context, 'transportServices'),
          style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 18, fontWeight: FontWeight.w900),
        ),
        actions: [
          if (userRole != null && ['owner', 'provider'].contains(userRole!.toLowerCase()))
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadItemScreen(category: 'Transport')));
                },
                icon: Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(color: const Color(0xFF00AA55).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                   child: const Icon(Icons.add_rounded, color: Color(0xFF00AA55), size: 22),
                ),
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    AppTranslations.translate(context, 'haulageLogistics'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppTranslations.translate(context, 'reliableTransport'),
                    style: TextStyle(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _buildVehicleCard(context, 'Mini Truck', l10n.miniTruck, 'assets/images/transport_truck_card.webp', AppTranslations.translate(context, '1_2_tons_capacity')),
                _buildVehicleCard(context, 'Tractor Trolley', l10n.tractorTrolley, 'assets/images/tractor_trolley_card.webp', AppTranslations.translate(context, '2_3_tons_capacity')),
                _buildVehicleCard(context, 'Full Truck', l10n.fullTruck, 'assets/images/full_truck_card.webp', AppTranslations.translate(context, '5_10_tons_capacity')),
                _buildVehicleCard(context, 'Tempo', l10n.tempo, 'assets/images/tractor_trolley_card.webp', AppTranslations.translate(context, '500kg_1_ton_capacity')),
                _buildVehicleCard(context, 'Pickup Van', l10n.pickupVan, 'assets/images/pickup_van_card.webp', AppTranslations.translate(context, '300_500_kg_capacity')), 
                _buildVehicleCard(context, 'Container', l10n.container, 'assets/images/full_truck_card.webp', AppTranslations.translate(context, '10_plus_tons_capacity')),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, String serviceKey, String title, String imagePath, String subtitle) {
    return GestureDetector(
      onTap: () => _showBookingDialog(context, serviceKey, title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF1F8F1), child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF00AA55), size: 40)),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 12,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, height: 1.1),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context, String vehicleType, String displayTitle) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceProvidersScreen(serviceKey: vehicleType, title: displayTitle, userRole: userRole)));
  }
}
