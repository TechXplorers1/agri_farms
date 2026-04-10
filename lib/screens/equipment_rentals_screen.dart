import 'package:flutter/material.dart';
import 'upload_item_screen.dart';
import 'service_providers_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EquipmentRentalsScreen extends StatelessWidget {
  final String? userRole;
  const EquipmentRentalsScreen({super.key, this.userRole});

  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.equipmentRentals,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (userRole != null && ['Owner', 'Provider'].contains(userRole))
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadItemScreen(category: 'Equipment')));
                },
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: Text(l10n.addListing, style: const TextStyle(color: Colors.white)),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  l10n.rentEquipment,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.browseEquipment,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                   _buildEquipmentCard(context, 'Tractors', l10n.tractors, 'assets/images/tractor_card.png', 'Plough & Cultivate'),
                   _buildEquipmentCard(context, 'Harvesters', l10n.harvesters, 'assets/images/harvester_card.png', 'Wheat & Paddy Harvest'),
                   _buildEquipmentCard(context, 'Sprayers', l10n.sprayers, 'assets/images/sprayer_card.png', 'Pest Control'),
                   _buildEquipmentCard(context, 'JCB', l10n.jcb, 'assets/images/jcb_card.png', 'Digging & Leveling'),
                   _buildEquipmentCard(context, 'Trolleys', l10n.trolleys, 'assets/images/trolley_card.png', 'Load & Carry'),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.nearbyEquipment,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(l10n.viewMore, style: const TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showBookingDialog(context, 'Tractors', l10n.tractors),
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
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Text(
                              l10n.available,
                              style: const TextStyle(color: Colors.green, fontSize: 12),
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

  Widget _buildEquipmentCard(BuildContext context, String serviceKey, String title, String imagePath, String subtitle) {
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
            Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.green[50])),
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

  void _showBookingDialog(BuildContext context, String equipmentName, String displayTitle) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceProvidersScreen(serviceKey: equipmentName, title: displayTitle, userRole: userRole)));
  }
}
