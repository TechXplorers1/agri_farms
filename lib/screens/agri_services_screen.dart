import 'package:flutter/material.dart';
import 'package:agriculture/screens/service_providers_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AgriServicesScreen extends StatelessWidget {
  final String? userRole;
  const AgriServicesScreen({super.key, this.userRole});

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
        actions: [],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.bookServices,
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
                childAspectRatio: 0.85, // Adjust aspect ratio to prevent overflow and look better
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                   _buildServiceCard(context, 'Ploughing', AppLocalizations.of(context)!.ploughing, Icons.agriculture, const Color(0xFFE3F2FD), Colors.blue),
                   _buildServiceCard(context, 'Electricians', 'Electricians', Icons.electrical_services, const Color(0xFFFFF8E1), Colors.amber[800]!),
                   _buildServiceCard(context, 'Harvesting', AppLocalizations.of(context)!.harvesting, Icons.grass, const Color(0xFFFFF9C4), Colors.orange),
                   _buildServiceCard(context, 'Farm Workers', AppLocalizations.of(context)!.farmWorkers, Icons.groups, const Color(0xFFF3E5F5), Colors.purple),
                   _buildServiceCard(context, 'Drone Spraying', AppLocalizations.of(context)!.droneSpraying, Icons.airplanemode_active, const Color(0xFFE8F5E9), Colors.green),
                   _buildServiceCard(context, 'Vet Care', AppLocalizations.of(context)!.vetCare, Icons.pets, const Color(0xFFFCE4EC), Colors.pink),
                   _buildServiceCard(context, 'Mechanics', 'Mechanics', Icons.build, const Color(0xFFECEFF1), Colors.blueGrey, isComingSoon: true),
                   _buildServiceCard(context, 'Irrigation', AppLocalizations.of(context)!.irrigation, Icons.water_drop, const Color(0xFFE1F5FE), Colors.cyan, isComingSoon: true),
                   _buildServiceCard(context, 'Soil Testing', AppLocalizations.of(context)!.soilTesting, Icons.science, const Color(0xFFE8F5E9), Colors.green, isComingSoon: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, String title, String displayTitle, IconData icon, Color bgColor, Color iconColor, {bool isComingSoon = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isComingSoon ? null : () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceProvidersScreen(serviceKey: title, title: displayTitle, userRole: userRole)));
          },
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Main Content
              Opacity(
                opacity: isComingSoon ? 0.4 : 1.0,
                child: Center(
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
                        displayTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Coming Soon Catchy UI
              if (isComingSoon) ...[
                // Lock Icon Overlay
                const Positioned(
                  top: 12,
                  left: 12,
                  child: Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
                
                // Catchy Badge
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade400,
                          Colors.orange.shade700,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Coming Soon',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
