import 'package:flutter/material.dart';
import 'upload_item_screen.dart';
import 'service_providers_screen.dart';
import 'package:agriculture/l10n/app_localizations.dart';

class EquipmentRentalsScreen extends StatelessWidget {
  final String? userRole;
  const EquipmentRentalsScreen({super.key, this.userRole});

  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        title: Text(
          l10n.equipmentRentals,
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
        actions: [
          if (userRole != null && ['Owner', 'Provider'].contains(userRole))
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadItemScreen(category: 'Equipment')));
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00AA55).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: Color(0xFF00AA55), size: 24),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lush Header Background/Banner would go here, for now using a premium title container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF00AA55), const Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00AA55).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    l10n.rentEquipment,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'High-quality farming machinery for your seasonal needs.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              l10n.browseEquipment.toUpperCase(),
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
                 _buildEquipmentCard(context, 'Tractors', l10n.tractors, 'assets/images/tractor_card.webp', 'Heavy Duty Pulling'),
                 _buildEquipmentCard(context, 'Harvesters', l10n.harvesters, 'assets/images/harvester_card.webp', 'Precision Reaping'),
                 _buildEquipmentCard(context, 'Sprayers', l10n.sprayers, 'assets/images/sprayer_card.webp', 'Fast Crop Care'),
                 _buildEquipmentCard(context, 'JCB', l10n.jcb, 'assets/images/jcb_card.webp', 'Land Preparation'),
                 _buildEquipmentCard(context, 'Trolleys', l10n.trolleys, 'assets/images/trolley_card.webp', 'Secure Haulage'),
              ],
            ),
            
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.nearbyEquipment.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B5E20),
                    letterSpacing: 1.2,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(l10n.viewMore, style: const TextStyle(color: Color(0xFF00AA55), fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            GestureDetector(
              onTap: () => _showBookingDialog(context, 'Tractors', l10n.tractors),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4)),
                  ],
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
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2C3E50),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            l10n.available,
                            style: const TextStyle(color: Color(0xFF00AA55), fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          '₹500',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
                        ),
                        const Text(
                          ' / hour',
                          style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const Icon(Icons.star_rounded, size: 20, color: Colors.orangeAccent),
                        const SizedBox(width: 4),
                        const Text('4.7', style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.w800, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[100], height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                         Container(
                           padding: const EdgeInsets.all(8),
                           decoration: BoxDecoration(color: const Color(0xFFF5F7F2), shape: BoxShape.circle),
                           child: const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF00AA55)),
                         ),
                         const SizedBox(width: 12),
                         Text(
                          'Suresh Patel • 4 km vicinity',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(BuildContext context, String serviceKey, String title, String imagePath, String subtitle) {
    return GestureDetector(
      onTap: () => _showBookingDialog(context, serviceKey, title),
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
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF9FBF9), child: const Icon(Icons.agriculture_rounded, color: Color(0xFF00AA55), size: 40)),
              ),
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
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
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

  void _showBookingDialog(BuildContext context, String equipmentName, String displayTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceProvidersScreen(
          serviceKey: equipmentName,
          title: displayTitle,
          userRole: userRole,
        ),
      ),
    );
  }
}
