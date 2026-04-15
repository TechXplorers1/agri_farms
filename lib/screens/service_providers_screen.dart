import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'upload_item_screen.dart';
import 'book_workers_screen.dart';
import 'book_transport_detail_screen.dart';
import 'book_equipment_detail_screen.dart';
import 'book_service_detail_screen.dart';
import '../utils/provider_manager.dart';

import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../utils/language_provider.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/vehicle_data.dart';

class ServiceProvidersScreen extends StatefulWidget {
  final String serviceKey;
  final String title;
  final String? userRole;

  const ServiceProvidersScreen({
    super.key, 
    required this.serviceKey, 
    required this.title, 
    this.userRole
  });

  @override
  State<ServiceProvidersScreen> createState() => _ServiceProvidersScreenState();
}

class _ServiceProvidersScreenState extends State<ServiceProvidersScreen> {
  String? _selectedMake;
  String? _selectedLocation;
  late Future<List<ServiceProvider>> _providersFuture;
  Locale? _lastLocale;

  @override
  void initState() {
    super.initState();
    // Initial fetch will be handled by didChangeDependencies or standard flow
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Provider.of<LanguageProvider>(context).locale;
    if (_lastLocale != locale) {
      _lastLocale = locale;
      _providersFuture = _fetchProviders();
    }
  }

  Future<List<ServiceProvider>> _fetchProviders() async {
    final List<String> transportTypes = ['Mini Truck', 'Tractor Trolley', 'Full Truck', 'Tempo', 'Pickup Van', 'Container'];
    final List<String> equipmentTypes = ['Tractors', 'Harvesters', 'Sprayers', 'Trolleys', 'JCB', 'Rotavators', 'Cultivators', 'Seed Drills', 'Power Tillers'];
    final List<String> serviceTypes = ['Ploughing', 'Harvesting', 'Drone Spraying', 'Irrigation', 'Vet Care', 'Crop Advisory', 'Electricians', 'Mechanics', 'Soil Testing'];

    try {
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      final targetLang = langProvider.languageCode;
      final trans = TranslationService();
      
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');
      final apiService = ApiService();

      List<ServiceProvider> providers = [];

      if (transportTypes.contains(widget.serviceKey)) {
        final vehiclesRaw = await apiService.getVehicles(type: widget.serviceKey) as List;
        final vehicles = vehiclesRaw.where((v) => v['ownerId']?.toString() != currentUserId).toList();
        
        providers = vehicles.map<ServiceProvider>((v) => TransportListing(
          id: v['vehicleId'].toString(),
          providerId: v['ownerId']?.toString(),
          name: v['ownerName'] ?? 'Unknown Owner',
          serviceName: v['vehicleType'],
          distance: '2-5 km',
          rating: (v['rating'] ?? 5.0).toDouble(),
          approvalStatus: v['approvalStatus'] ?? 'Pending',
          location: v['location'] ?? 'Nearby',
          vehicleType: v['vehicleType'],
          loadCapacity: v['loadCapacity'] ?? 'Standard',
          price: '₹${v['pricePerKmOrTrip']} / Trip',
          driverIncluded: v['driverIncluded'] ?? true,
          vehicleNumber: v['vehicleNumber'],
          serviceArea: v['serviceArea'],
          image: v['imageUrl'],
          ownerProfileImage: v['ownerProfileImageUrl'],
        )).toList();
      } else if (equipmentTypes.contains(widget.serviceKey)) {
        final equipmentRaw = await apiService.getEquipment(category: widget.serviceKey) as List;
        final equipment = equipmentRaw.where((e) => e['ownerId']?.toString() != currentUserId).toList();

        providers = equipment.map<ServiceProvider>((e) => EquipmentListing(
          id: e['equipmentId'].toString(),
          providerId: e['ownerId']?.toString(),
          name: e['ownerName'] ?? 'Unknown Owner',
          serviceName: e['category'],
          distance: '1-3 km',
          rating: (e['rating'] ?? 5.0).toDouble(),
          approvalStatus: e['approvalStatus'] ?? 'Pending',
          location: e['location'] ?? 'Nearby',
          brandModel: e['brandModel'] ?? 'Standard',
          condition: e['condition'] ?? 'Good',
          price: '₹${e['pricePerHour']} / hr',
          operatorAvailable: e['operatorAvailable'] ?? false,
          image: e['imageUrl'],
          ownerProfileImage: e['ownerProfileImageUrl'],
        )).toList();
      } else if (serviceTypes.contains(widget.serviceKey)) {
         final servicesRaw = await apiService.getServices(type: widget.serviceKey) as List;
         final services = servicesRaw.where((s) => s['ownerId']?.toString() != currentUserId).toList();

         providers = services.map<ServiceProvider>((s) => ServiceListing(
           id: s['serviceId'].toString(),
           providerId: s['ownerId']?.toString(),
           name: s['ownerName'] ?? s['businessName'] ?? 'Unknown Owner',
           serviceName: s['serviceType'],
           distance: 'Nearby',
           rating: (s['rating'] ?? 5.0).toDouble(),
           approvalStatus: s['approvalStatus'] ?? 'Pending',
           location: s['location'] ?? 'Village',
           equipmentUsed: s['equipmentUsed'] ?? 'Expert Tools',
           price: '₹${s['priceRate']}',
           operatorIncluded: true,
           jobsCompleted: s['jobsCompleted'] ?? 0,
           image: s['imageUrl'],
           ownerProfileImage: s['ownerProfileImageUrl'],
         )).toList();
      } else if (widget.serviceKey == 'Farm Workers') {
         final workersRaw = await apiService.getWorkerGroups() as List;
         final workers = workersRaw.where((w) => w['ownerId']?.toString() != currentUserId).toList();

         providers = workers.map<ServiceProvider>((w) => FarmWorkerListing(
             id: w['groupId'].toString(),
             providerId: w['ownerId']?.toString(),
             name: w['ownerName'] ?? w['groupName'] ?? 'Unknown Leader',
             serviceName: 'Farm Workers',
             distance: '2 km',
             rating: (w['rating'] ?? 5.0).toDouble(),
             approvalStatus: w['approvalStatus'] ?? 'Pending',
             location: w['location'] ?? 'Nearby',
             maleCount: (w['maleCount'] as num?)?.toInt() ?? 0,
             femaleCount: (w['femaleCount'] as num?)?.toInt() ?? 0,
             malePrice: (w['pricePerMale'] as num?)?.toInt() ?? 0,
             femalePrice: (w['pricePerFemale'] as num?)?.toInt() ?? 0,
             malePriceHourly: (w['pricePerMaleHourly'] as num?)?.toInt() ?? 0,
             femalePriceHourly: (w['pricePerFemaleHourly'] as num?)?.toInt() ?? 0,
             skills: w['skills'] ?? 'General Labor',
             roleDistribution: (w['roles'] as List<dynamic>?)?.map((r) => '${r['count']} ${r['gender']} - ${r['taskName']}').toList() ?? ['General Farming'],
             groupName: w['groupName'],
             image: w['imageUrl'],
             ownerProfileImage: w['ownerProfileImageUrl']
         )).toList();
      } else {
         providers = ProviderManager().getProvidersByService(widget.serviceKey);
      }

      // Apply Translation if not English
      if (targetLang != 'en') {
        for (var p in providers) {
          p.serviceName = await trans.translate(p.serviceName, targetLang);
          p.location = await trans.translate(p.location, targetLang);
          
          if (p is EquipmentListing) {
            p.brandModel = await trans.translate(p.brandModel, targetLang);
            p.condition = await trans.translate(p.condition, targetLang);
          } else if (p is TransportListing) {
            p.vehicleType = await trans.translate(p.vehicleType, targetLang);
            p.loadCapacity = await trans.translate(p.loadCapacity, targetLang);
          } else if (p is ServiceListing) {
            p.equipmentUsed = await trans.translate(p.equipmentUsed, targetLang);
          } else if (p is FarmWorkerListing) {
            p.skills = await trans.translate(p.skills, targetLang);
            p.roleDistribution = await Future.wait(p.roleDistribution.map((r) => trans.translate(r, targetLang)));
          }
        }
      }
      
      return providers;
    } catch (e) {
      debugPrint('Error fetching providers for ${widget.serviceKey}: $e');
      return ProviderManager().getProvidersByService(widget.serviceKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          if (['Owner', 'Provider'].contains(widget.userRole))
            Padding(padding: const EdgeInsets.only(right: 8), child: _buildAddButton(context)),
        ],
      ),
      body: FutureBuilder<List<ServiceProvider>>(
        future: _providersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00AA55)));
          }
          final allProviders = snapshot.data ?? [];
          
          final uniqueLocations = allProviders.map((p) => p.location).where((loc) => loc.isNotEmpty).toSet().toList();
          uniqueLocations.sort();

          String dataCategory = widget.serviceKey;
          if (widget.serviceKey == 'Ploughing') dataCategory = 'Tractors';
          if (widget.serviceKey == 'Harvesting') dataCategory = 'Harvesters';
          if (widget.serviceKey == 'Tractor Trolley') dataCategory = 'Trolleys';
          final availableMakes = VehicleData.getMakes(dataCategory);

          final filteredProviders = allProviders.where((provider) {
            bool matchesMake = true;
            bool matchesLocation = true;
            if (_selectedMake != null && _selectedMake != 'All') {
               if (provider is EquipmentListing) matchesMake = provider.brandModel.contains(_selectedMake!); 
               else if (provider is TransportListing) matchesMake = provider.vehicleType.contains(_selectedMake!) || provider.name.contains(_selectedMake!);
               else if (provider is ServiceListing) matchesMake = provider.equipmentUsed.contains(_selectedMake!);
            }
            if (_selectedLocation != null && _selectedLocation != 'All') {
              matchesLocation = provider.location == _selectedLocation;
            }
            return matchesMake && matchesLocation;
          }).toList();

          return Column(
            children: [
               _buildFilterSection(availableMakes, uniqueLocations),
               Expanded(
                 child: filteredProviders.isEmpty
                 ? _buildEmptyState(l10n)
                 : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filteredProviders.length,
                    itemBuilder: (context, index) {
                      final provider = filteredProviders[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _buildListingCard(context, provider),
                      );
                    },
                  ),
               ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(List<String> makes, List<String> locations) {
    var l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Row(
        children: [
          if (makes.isNotEmpty && makes.length > 1) ...[
            Expanded(child: _buildFilterDropdown(
              hint: l10n.chooseMake, value: _selectedMake, items: ['All', ...makes],
              onChanged: (v) => setState(() => _selectedMake = v == 'All' ? null : v),
            )),
            const SizedBox(width: 12),
          ],
          Expanded(child: _buildFilterDropdown(
            hint: l10n.selectLocation, value: _selectedLocation, items: ['All', ...locations],
            onChanged: (v) => setState(() => _selectedLocation = v == 'All' ? null : v),
            isLocation: true,
          )),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({required String hint, required String? value, required List<String> items, required Function(String?) onChanged, bool isLocation = false}) {
    return Container(
      height: 42, padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFFF5F7F5), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isExpanded: true,
          hint: Row(children: [
            if (isLocation) const Icon(Icons.location_on, size: 14, color: Color(0xFF00AA55)),
            if (isLocation) const SizedBox(width: 6),
            Expanded(child: Text(hint, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          ]),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
      const SizedBox(height: 16),
      Text(l10n.noMatchFound, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
    ]));
  }

  Widget _buildListingCard(BuildContext context, ServiceProvider provider) {
    if (provider is FarmWorkerListing) return _buildWorkerProviderCard(context, provider);
    if (provider is ServiceListing) return _buildServiceListingCard(context, provider);
    if (provider is TransportListing) return _buildTransportListingCard(context, provider);
    if (provider is EquipmentListing) return _buildEquipmentListingCard(context, provider);
    return const SizedBox();
  }

  Widget _buildWorkerProviderCard(BuildContext context, FarmWorkerListing provider) {
    var l10n = AppLocalizations.of(context)!;
    return _buildBasePremiumCard(
      provider: provider,
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        final currentUserId = prefs.getString('user_id');
        Navigator.push(context, MaterialPageRoute(builder: (_) => BookWorkersScreen(
          providerName: provider.name, providerId: provider.providerId ?? currentUserId ?? '1', assetId: provider.id,
          maxMale: provider.maleCount, maxFemale: provider.femaleCount, priceMale: provider.malePrice, priceFemale: provider.femalePrice,
          priceMaleHourly: provider.malePriceHourly, priceFemaleHourly: provider.femalePriceHourly, roleDistribution: provider.roleDistribution,
        )));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(provider.skills, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF2C3E50))),
          const SizedBox(height: 6),
          _buildWorkerStats(provider, l10n),
          const SizedBox(height: 12),
          _buildBookFullWidthButton(l10n.bookWorkers, () async {
             final prefs = await SharedPreferences.getInstance();
             final currentUserId = prefs.getString('user_id');
             Navigator.push(context, MaterialPageRoute(builder: (_) => BookWorkersScreen(
               providerName: provider.name, providerId: provider.providerId ?? currentUserId ?? '1', assetId: provider.id,
               maxMale: provider.maleCount, maxFemale: provider.femaleCount, priceMale: provider.malePrice, priceFemale: provider.femalePrice,
               priceMaleHourly: provider.malePriceHourly, priceFemaleHourly: provider.femalePriceHourly, roleDistribution: provider.roleDistribution,
             )));
          }),
        ],
      ),
    );
  }

  Widget _buildServiceListingCard(BuildContext context, ServiceListing provider) {
    var l10n = AppLocalizations.of(context)!;
    return _buildBasePremiumCard(
      provider: provider, subtitle: provider.equipmentUsed,
      onTap: () => _navigateToBooking(context, provider),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const Icon(Icons.history_rounded, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${provider.jobsCompleted} ${l10n.jobsCompleted}', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
          _buildBookMiniButton(provider.price, () => _navigateToBooking(context, provider)),
        ],
      ),
    );
  }

  Widget _buildTransportListingCard(BuildContext context, TransportListing provider) {
    var l10n = AppLocalizations.of(context)!;
    return _buildBasePremiumCard(
      provider: provider, subtitle: '${provider.vehicleType} • ${provider.loadCapacity}',
      onTap: () => _navigateToBooking(context, provider),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(Icons.person_pin_circle_outlined, size: 14, color: Colors.blue[600]),
            const SizedBox(width: 4),
            Text(l10n.driverIncluded, style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          _buildBookMiniButton(provider.price, () => _navigateToBooking(context, provider)),
        ],
      ),
    );
  }

  Widget _buildEquipmentListingCard(BuildContext context, EquipmentListing provider) {
    var l10n = AppLocalizations.of(context)!;
    return _buildBasePremiumCard(
      provider: provider, subtitle: provider.brandModel,
      onTap: () => _navigateToBooking(context, provider),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(6)),
              child: Text(provider.condition, style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold))),
            const SizedBox(width: 8),
            Text(provider.operatorAvailable ? l10n.withOperatorAvailable : l10n.noOperator, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
          _buildBookMiniButton(provider.price, () => _navigateToBooking(context, provider)),
        ],
      ),
    );
  }

  Widget _buildBasePremiumCard({required ServiceProvider provider, String? subtitle, required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showFullImage(context, provider.ownerProfileImage, provider.name),
                    child: CircleAvatar(radius: 24, backgroundImage: provider.ownerProfileImage != null ? NetworkImage(ApiConfig.getFullImageUrl(provider.ownerProfileImage)) : null,
                      child: provider.ownerProfileImage == null ? const Icon(Icons.person, size: 28) : null),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(provider.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF2C3E50)), overflow: TextOverflow.ellipsis),
                    if (subtitle != null) Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                  ])),
                  if (provider.isAvailable) _buildStatusBadge(),
                ],
              ),
            ),
            if (provider.image != null)
              GestureDetector(
                onTap: () => _showAssetDetails(context, provider),
                child: Container(
                  height: 160, width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                  child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(ApiConfig.getFullImageUrl(provider.image), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[100]))),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: Column(
                children: [
                  Row(children: [
                    _iconLabel(Icons.star_rounded, Colors.amber, provider.rating.toString()),
                    const SizedBox(width: 16),
                    _iconLabel(Icons.location_on_rounded, const Color(0xFF00AA55), provider.distance),
                    const SizedBox(width: 16),
                    Text(provider.location, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 16),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconLabel(IconData icon, Color color, String label) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF2C3E50))),
    ]);
  }

  Widget _buildStatusBadge() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
      child: const Text('Available', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 10, fontWeight: FontWeight.w800)));
  }

  Widget _buildBookMiniButton(String price, VoidCallback onTap) {
    return Row(children: [
      Text(price.split('/').first.trim(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF2E7D32))),
      const SizedBox(width: 12),
      ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), minimumSize: const Size(0, 36)),
        child: const Text('Book', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
    ]);
  }

  Widget _buildBookFullWidthButton(String label, VoidCallback onTap) {
    return SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF00AA55), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))));
  }

  Widget _buildWorkerStats(FarmWorkerListing p, AppLocalizations l10n) {
    return Row(children: [
      _workerStat(l10n.male, p.maleCount.toString(), '₹${p.malePrice}', Colors.blue),
      const SizedBox(width: 12),
      _workerStat(l10n.female, p.femaleCount.toString(), '₹${p.femalePrice}', Colors.pink),
    ]);
  }

  Widget _workerStat(String sex, String count, String price, Color color) {
    return Expanded(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(sex, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
        const SizedBox(height: 2),
        Text(count, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        Text(price, style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w500)),
      ])));
  }

  void _showAssetDetails(BuildContext context, ServiceProvider provider) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _AssetDetailModal(provider: provider, onBookNow: () { Navigator.pop(context); _navigateToBooking(context, provider); }));
  }

  void _navigateToBooking(BuildContext context, ServiceProvider provider) async {
      double rate = 0;
      String priceString = '';
      if (provider is ServiceListing) priceString = provider.price;
      if (provider is TransportListing) priceString = provider.price;
      if (provider is EquipmentListing) priceString = provider.price;
      try { rate = double.parse(priceString.replaceAll(RegExp(r'[^0-9.]'), '')); } catch (_) { rate = 0; }
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');
      final actualProviderId = provider.providerId ?? currentUserId ?? '1';
      if (!context.mounted) return;
      if (provider is TransportListing) {
         Navigator.push(context, MaterialPageRoute(builder: (_) => BookTransportDetailScreen(providerName: provider.name, vehicleType: provider.vehicleType, providerId: actualProviderId, assetId: provider.id, rate: rate > 0 ? rate : 1500, ownerProfileImage: provider.ownerProfileImage)));
      } else if (provider is EquipmentListing) {
         Navigator.push(context, MaterialPageRoute(builder: (_) => BookEquipmentDetailScreen(providerName: provider.name, equipmentType: provider.serviceName, providerId: actualProviderId, assetId: provider.id, rate: rate > 0 ? rate : 500, ownerProfileImage: provider.ownerProfileImage)));
      } else {
         Navigator.push(context, MaterialPageRoute(builder: (_) => BookServiceDetailScreen(providerName: provider.name, serviceName: provider.serviceName, providerId: actualProviderId, assetId: provider.id, priceInfo: priceString, ownerProfileImage: provider.ownerProfileImage)));
      }
  }

  Widget _buildAddButton(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    String label = l10n.addListing;
    String category = 'Service'; 
    if (widget.serviceKey == 'Farm Workers') { label = l10n.addGroup; category = 'Farm Workers'; }
    else if (['Mini Truck', 'Tractor Trolley', 'Full Truck', 'Tempo', 'Pickup Van', 'Container'].contains(widget.serviceKey)) { label = l10n.addVehicle; category = 'Transport'; }
    else if (['Tractors', 'Harvesters', 'Sprayers', 'Trolleys'].contains(widget.serviceKey)) { label = l10n.addEquipment; category = 'Equipment'; }
    else { label = l10n.addService; category = widget.serviceKey; }

    return ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UploadItemScreen(category: category))),
      icon: const Icon(Icons.add, size: 16, color: Colors.white), label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00AA55), padding: const EdgeInsets.symmetric(horizontal: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), minimumSize: const Size(0, 34)));
  }
}

void _showFullImage(BuildContext context, String? imageUrl, String title) {
  if (imageUrl == null || imageUrl.isEmpty) return;
  showDialog(context: context, builder: (context) => Dialog(backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.all(20), child: Stack(alignment: Alignment.center, children: [
    GestureDetector(onTap: () => Navigator.pop(context), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(ApiConfig.getFullImageUrl(imageUrl), fit: BoxFit.contain, errorBuilder: (_, __, ___) => Container(color: Colors.white, padding: const EdgeInsets.all(40), child: const Icon(Icons.broken_image, size: 80, color: Colors.grey))))),
    Positioned(top: 10, right: 10, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
  ])));
}

class _AssetDetailModal extends StatelessWidget {
  final ServiceProvider provider;
  final VoidCallback onBookNow;
  const _AssetDetailModal({required this.provider, required this.onBookNow});

  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        Flexible(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 32), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.network(ApiConfig.getFullImageUrl(provider.image), height: 240, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 240, color: Colors.grey[100], child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey)))),
          const SizedBox(height: 24),
          Row(children: [
            CircleAvatar(radius: 20, backgroundImage: provider.ownerProfileImage != null ? NetworkImage(ApiConfig.getFullImageUrl(provider.ownerProfileImage)) : null, child: provider.ownerProfileImage == null ? const Icon(Icons.person) : null),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(provider.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
              Text(provider.serviceName, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(12)),
              child: Row(children: [const Icon(Icons.star_rounded, size: 18, color: Colors.amber), const SizedBox(width: 4), Text(provider.rating.toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))])),
          ]),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          if (provider is EquipmentListing) _buildEquipmentDetails(context, provider as EquipmentListing),
          if (provider is TransportListing) _buildTransportDetails(context, provider as TransportListing),
          if (provider is FarmWorkerListing) _buildWorkerDetails(context, provider as FarmWorkerListing),
          if (provider is ServiceListing) _buildServiceDetails(context, provider as ServiceListing),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 54, child: ElevatedButton(onPressed: onBookNow, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00AA55), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            child: Text((provider is FarmWorkerListing) ? l10n.bookNow : l10n.rentNow, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)))),
        ]))),
      ]),
    );
  }

  Widget _buildEquipmentDetails(BuildContext context, EquipmentListing item) {
    return Column(children: [
      _detailRow(Icons.construction_rounded, 'Brand & Model', item.brandModel),
      _detailRow(Icons.info_outline_rounded, 'Condition', item.condition),
      _detailRow(Icons.person_outline_rounded, 'Operator', item.operatorAvailable ? 'Available' : 'Not Provided'),
      _detailRow(Icons.payments_outlined, 'Price Rate', item.price),
      _detailRow(Icons.location_on_outlined, 'Location', item.location),
      _detailRow(Icons.history_rounded, 'Jobs Completed', '${item.jobsCompleted}'),
    ]);
  }

  Widget _buildTransportDetails(BuildContext context, TransportListing item) {
    return Column(children: [
      _detailRow(Icons.local_shipping_outlined, 'Vehicle', item.vehicleType),
      _detailRow(Icons.fitness_center_rounded, 'Capacity', item.loadCapacity),
      _detailRow(Icons.person_pin_circle_outlined, 'Driver', item.driverIncluded ? 'Included' : 'Self-Drive'),
      _detailRow(Icons.payments_outlined, 'Rental Rate', item.price),
      _detailRow(Icons.location_on_outlined, 'Location', item.location),
      _detailRow(Icons.history_rounded, 'Jobs Completed', '${item.jobsCompleted}'),
    ]);
  }

  Widget _buildWorkerDetails(BuildContext context, FarmWorkerListing item) {
    return Column(children: [
      _detailRow(Icons.groups_rounded, 'Total Staff', '${item.maleCount + item.femaleCount} Members'),
      _detailRow(Icons.psychology_outlined, 'Expertise', item.skills),
      _detailRow(Icons.location_on_outlined, 'Location', item.location),
      _detailRow(Icons.history_rounded, 'Jobs Completed', '${item.jobsCompleted}'),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: item.roleDistribution.map((r) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFF3F7F3), borderRadius: BorderRadius.circular(10)), child: Text(r, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))))).toList()),
    ]);
  }

  Widget _buildServiceDetails(BuildContext context, ServiceListing item) {
    return Column(children: [
      _detailRow(Icons.handyman_outlined, 'Tools', item.equipmentUsed),
      _detailRow(Icons.person_outline_rounded, 'Expert', item.operatorIncluded ? 'Provided' : 'Machine Only'),
      _detailRow(Icons.payments_outlined, 'Service Cost', item.price),
      _detailRow(Icons.location_on_outlined, 'Location', item.location),
      _detailRow(Icons.history_rounded, 'Jobs Completed', '${item.jobsCompleted}'),
    ]);
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF1F8F1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: const Color(0xFF2E7D32))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600, letterSpacing: 0.5)), const SizedBox(height: 2), Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)))]))
    ]));
  }
}
