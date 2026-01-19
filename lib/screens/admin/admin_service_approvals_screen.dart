import 'package:flutter/material.dart';
import '../../utils/provider_manager.dart';

class ServiceApprovalsScreen extends StatefulWidget {
  const ServiceApprovalsScreen({super.key});

  @override
  State<ServiceApprovalsScreen> createState() => _ServiceApprovalsScreenState();
}

class _ServiceApprovalsScreenState extends State<ServiceApprovalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Service Approvals'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: 'Vehicles & Equipment'),
            Tab(text: 'Farm Workers'),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: ProviderManager(),
        builder: (context, _) {
          final allPending = ProviderManager().getPendingProviders();
          
          // Filter lists
          final equipmentList = allPending.where((p) => p.serviceName != 'Farm Workers').toList();
          final workersList = allPending.where((p) => p.serviceName == 'Farm Workers').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildApprovalList(equipmentList, isWorker: false),
              _buildApprovalList(workersList, isWorker: true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildApprovalList(List<ServiceProvider> providers, {required bool isWorker}) {
    if (providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isWorker ? Icons.group_off_outlined : Icons.agriculture_outlined, 
              size: 64, 
              color: Colors.grey[300]
            ),
            const SizedBox(height: 16),
            Text(
              'No pending ${isWorker ? 'worker group' : 'equipment'} requests', 
              style: TextStyle(color: Colors.grey[600], fontSize: 16)
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              provider.serviceName,
                              style: TextStyle(fontSize: 12, color: Colors.blue[800], fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
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
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                
                // Details Section
                if (isWorker) ...[
                  _buildDetailRow(Icons.person, 'Workers', 'Male: ${provider.maleCount} | Female: ${provider.femaleCount}'),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.payments_outlined, 'Rates', 'M: ₹${provider.malePrice} / F: ₹${provider.femalePrice}'),
                ] else ...[
                   _buildDetailRow(Icons.price_change_outlined, 'Price', provider.price ?? 'N/A'),
                   if (provider.jobs != null) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.work_history_outlined, 'Past Jobs', '${provider.jobs} completed'),
                   ]
                ],
                
                const SizedBox(height: 8),
                _buildDetailRow(Icons.location_on_outlined, 'Distance', provider.distance ?? 'Unknown'),

                const SizedBox(height: 20),
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ProviderManager().updateProviderStatus(provider.id, 'Approved');
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Approved!')));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(value, style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }
}
