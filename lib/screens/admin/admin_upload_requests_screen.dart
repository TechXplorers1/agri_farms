import 'package:flutter/material.dart';
import '../../utils/provider_manager.dart';

class AdminUploadRequestsScreen extends StatelessWidget {
  const AdminUploadRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Upload Requests'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: ProviderManager(),
        builder: (context, _) {
          final pendingProviders = ProviderManager().getPendingProviders();

          if (pendingProviders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
                  const SizedBox(height: 16),
                  Text('No pending requests', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingProviders.length,
            itemBuilder: (context, index) {
              final provider = pendingProviders[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              provider.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Pending',
                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                         children: [
                           Icon(Icons.category, size: 16, color: Colors.grey[600]),
                           const SizedBox(width: 4),
                           Text('Service: ${provider.serviceName}', style: TextStyle(color: Colors.grey[800])),
                         ],
                      ),
                      const SizedBox(height: 4),
                       Row(
                         children: [
                           Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                           const SizedBox(width: 4),
                           if (provider.price != null)
                             Text('Price: ${provider.price}', style: TextStyle(color: Colors.grey[800])),
                           if (provider.malePrice != null) // Worker pricing
                              Text('M: ₹${provider.malePrice} / F: ₹${provider.femalePrice}', style: TextStyle(color: Colors.grey[800])),
                         ],
                      ),
                      
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                ProviderManager().updateProviderStatus(provider.id, 'Rejected');
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Rejected')));
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                ProviderManager().updateProviderStatus(provider.id, 'Approved');
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Approved! Now visible to users.')));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
