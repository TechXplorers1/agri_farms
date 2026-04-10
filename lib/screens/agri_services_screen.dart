import 'package:flutter/material.dart';
import 'service_providers_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AgriServicesScreen extends StatelessWidget {
  final String? userRole;
  const AgriServicesScreen({super.key, this.userRole});

  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Agri Services',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: const [],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bookServices,
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
                   _buildServiceCard(context, 'Ploughing', l10n.ploughing, 'assets/images/agri_services_card.png', 'Field Preparation'),
                   _buildServiceCard(context, 'Electricians', 'Electricians', 'assets/images/electrician_card.png', 'Expert Repairs'),
                   _buildServiceCard(context, 'Harvesting', l10n.harvesting, 'assets/images/harvester_card.png', 'Crop Collection'),
                   _buildServiceCard(context, 'Farm Workers', l10n.farmWorkers, 'assets/images/farm_workers_card.png', 'Skilled Labour'),
                   _buildServiceCard(context, 'Drone Spraying', l10n.droneSpraying, 'assets/images/drone_spraying_card.png', 'Modern Spraying'),
                   _buildServiceCard(context, 'Vet Care', l10n.vetCare, 'assets/images/vet_care_card.png', 'Animal health'),
                   _buildServiceCard(context, 'Mechanics', 'Mechanics', 'assets/images/mechanic_card.png', 'Vehicle Repair', isComingSoon: true),
                   _buildServiceCard(context, 'Irrigation', l10n.irrigation, 'assets/images/irrigation_card.png', 'Water Management'),
                   _buildServiceCard(context, 'Soil Testing', l10n.soilTesting, 'assets/images/soil_testing_card.png', 'Know Your Soil'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, String serviceKey, String title, String imagePath, String subtitle, {bool isComingSoon = false, bool isNew = false}) {
    return GestureDetector(
      onTap: isComingSoon ? null : () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceProvidersScreen(serviceKey: serviceKey, title: title, userRole: userRole)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(fit: StackFit.expand, children: [
            Opacity(
              opacity: isComingSoon ? 0.6 : 1.0,
              child: Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.blue[50])),
            ),
            DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.68)],
              stops: const [0.35, 1.0],
            ))),
            Positioned(left: 12, right: 8, bottom: 10, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, height: 1.1), maxLines: 2),
              const SizedBox(height: 2),
              Text(isComingSoon ? 'Coming Soon' : subtitle, style: TextStyle(color: isComingSoon ? Colors.orange : Colors.white70, fontSize: 10, fontWeight: FontWeight.w400)),
            ])),
            if (isComingSoon) 
              Center(child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle), child: const Icon(Icons.lock_outline, color: Colors.white, size: 24))),
            if (isNew)
              Positioned(top: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: const BoxDecoration(color: Color(0xFFA020F0), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12))), child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
          ]),
        ),
      ),
    );
  }
}
