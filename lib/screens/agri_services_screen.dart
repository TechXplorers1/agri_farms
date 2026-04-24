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
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        title: Text(
          'Agri Services',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1B5E20)),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B5E20), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bookServices.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B5E20),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: [
                 _buildServiceCard(context, 'Ploughing', l10n.ploughing, 'assets/images/agri_services_card.webp', 'Lush Field Preparation'),
                 _buildServiceCard(context, 'Electricians', 'Electricians', 'assets/images/electrician_card.webp', 'Expert Power Fixes'),
                 _buildServiceCard(context, 'Harvesting', l10n.harvesting, 'assets/images/harvester_card.webp', 'Premium Crop Yield'),
                 _buildServiceCard(context, 'Farm Workers', l10n.farmWorkers, 'assets/images/farm_workers_card.webp', 'Skilled Daily Help'),
                 _buildServiceCard(context, 'Drone Spraying', l10n.droneSpraying, 'assets/images/drone_spraying_card.webp', 'Modern Tech Spray'),
                 _buildServiceCard(context, 'Vet Care', l10n.vetCare, 'assets/images/vet_care_card.webp', 'Animal Wellness'),
                 _buildServiceCard(context, 'Mechanics', 'Mechanics', 'assets/images/mechanic_card.webp', 'Vehicle Repair', isComingSoon: true),
                 _buildServiceCard(context, 'Irrigation', l10n.irrigation, 'assets/images/irrigation_card.webp', 'Water Solutions', isComingSoon: true),
                 _buildServiceCard(context, 'Soil Testing', l10n.soilTesting, 'assets/images/soil_testing_card.webp', 'Precision Analysis', isComingSoon: true),
              ],
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Hero Image with smoother fade
              Opacity(
                opacity: isComingSoon ? 0.4 : 1.0,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF9FBF9), child: const Icon(Icons.agriculture_rounded, color: Color(0xFF00AA55), size: 40)),
                ),
              ),
              // Lush Gradient Overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              // Content
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.2),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isComingSoon ? 'COMMING SOON' : subtitle,
                      style: TextStyle(
                        color: isComingSoon ? Colors.orangeAccent : Colors.white.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              if (isComingSoon) 
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded, color: Colors.white, size: 28),
                  ),
                ),
              if (isNew)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA020F0),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: const Color(0xFFA020F0).withOpacity(0.3), blurRadius: 8)],
                    ),
                    child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
