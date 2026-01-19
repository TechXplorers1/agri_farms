import 'package:flutter/material.dart';

class AdminDisputesScreen extends StatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock Data
  final List<Map<String, dynamic>> _disputes = [
    {
      'id': 'D-1023',
      'user': 'Ramesh Kumar',
      'role': 'Farmer',
      'issue': 'Tractor operator demanded extra payment.',
      'status': 'Pending',
      'date': 'Jan 18, 2026',
      'priority': 'High'
    },
    {
      'id': 'D-1024',
      'user': 'Suresh Services',
      'role': 'Provider',
      'issue': 'Farmer cancelled after arrival involved cost.',
      'status': 'Pending',
      'date': 'Jan 19, 2026',
      'priority': 'Medium'
    },
    {
      'id': 'D-1001',
      'user': 'Anita Devi',
      'role': 'Farmer',
      'issue': 'Drone spraying was not done properly.',
      'status': 'Resolved',
      'date': 'Jan 10, 2026',
      'priority': 'Low'
    },
  ];

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
        title: const Text('Dispute Resolution'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.red,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.red,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDisputeList(status: 'Pending'),
          _buildDisputeList(status: 'Resolved'),
        ],
      ),
    );
  }

  Widget _buildDisputeList({required String status}) {
    final list = _disputes.where((d) => d['status'] == status).toList();

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No $status disputes', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item['priority'] == 'High' ? Colors.red[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['priority'] + ' Priority',
                        style: TextStyle(
                          fontSize: 10, 
                          fontWeight: FontWeight.bold,
                          color: item['priority'] == 'High' ? Colors.red : Colors.blue
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(item['date'], style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${item['id']} • ${item['user']} (${item['role']})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  item['issue'],
                  style: TextStyle(color: Colors.grey[800]),
                ),
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // Mock Call Action
                      },
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Contact'),
                      style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                    ),
                    if (status == 'Pending') ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            item['status'] = 'Resolved';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as Resolved')));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Resolve'),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
