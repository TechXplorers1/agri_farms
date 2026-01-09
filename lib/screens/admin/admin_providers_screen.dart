import 'package:flutter/material.dart';
import '../../utils/provider_manager.dart';
import '../upload_item_screen.dart';

class AdminProvidersScreen extends StatefulWidget {
  const AdminProvidersScreen({super.key});

  @override
  State<AdminProvidersScreen> createState() => _AdminProvidersScreenState();
}

class _AdminProvidersScreenState extends State<AdminProvidersScreen> {
  final ProviderManager _providerManager = ProviderManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Manage Providers'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           // Reuse existing Upload Screen
           // Defaulting to 'Farm Workers' for now as a generic entry point or could show a dialog to choose category
           showModalBottomSheet(context: context, builder: (context) {
             return Container(
               padding: const EdgeInsets.all(16),
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   ListTile(
                     leading: const Icon(Icons.groups),
                     title: const Text('Add Farm Workers'),
                     onTap: () {
                       Navigator.pop(context);
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadItemScreen(category: 'Farm Workers')));
                     },
                   ),
                   ListTile(
                     leading: const Icon(Icons.agriculture),
                     title: const Text('Add Equipment'),
                     onTap: () {
                       Navigator.pop(context);
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadItemScreen(category: 'Equipment')));
                     },
                   ),
                    ListTile(
                     leading: const Icon(Icons.local_shipping),
                     title: const Text('Add Transport'),
                     onTap: () {
                       Navigator.pop(context);
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadItemScreen(category: 'Transport')));
                     },
                   ),
                 ],
               ),
             );
           });
        },
        label: const Text('Add Provider'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF00AA55),
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: _providerManager,
        builder: (context, _) {
          final providers = _providerManager.providers;
          if (providers.isEmpty) {
            return const Center(child: Text('No providers found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[50],
                    child: Text(provider.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                  title: Text(provider.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${provider.serviceName} • ${provider.distance ?? "Unknown location"}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          const Divider(),
                          // Details Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDetailItem(Icons.star, '${provider.rating}', 'Rating'),
                              _buildDetailItem(Icons.work, '${provider.jobs ?? 0}', 'Jobs Done'),
                              _buildDetailItem(Icons.verified, provider.isAvailable == false ? 'Busy' : 'Available', 'Status'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Capacity / Price Specifics
                          if (provider.maleCount != null || provider.femaleCount != null) ...[
                            _buildInfoRow('Male Workers', '${provider.maleCount ?? 0} Available', '₹${provider.malePrice ?? 0}/day'),
                            const SizedBox(height: 8),
                            _buildInfoRow('Female Workers', '${provider.femaleCount ?? 0} Available', '₹${provider.femalePrice ?? 0}/day'),
                          ],
                          
                          if (provider.price != null) ...[
                             _buildInfoRow('Service Price', provider.price!, ''),
                          ],

                          const SizedBox(height: 16),
                          
                          // Actions
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _confirmDelete(context, provider);
                              },
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Remove Provider'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[50],
                                foregroundColor: Colors.red,
                                elevation: 0,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ServiceProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Provider?'),
        content: Text('Are you sure you want to remove "${provider.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              // Create a localized reference to the manager or use helper
              // Using method from state directly for now as simple
              ProviderManager().removeProvider(provider.id); 
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provider Removed')));
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, String trailing) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          Row(
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              if (trailing.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('• $trailing', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
              ]
            ],
          )
        ],
      ),
    );
  }
}
