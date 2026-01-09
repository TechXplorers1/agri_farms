import 'package:flutter/material.dart';
import 'admin_bookings_screen.dart';
import 'admin_providers_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSummaryCard('Total\nBookings', '12', Icons.book_online, Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard('Active\nProviders', '45', Icons.group, Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard('Total\nUsers', '150+', Icons.person, Colors.orange)),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildLinkCard(
              context,
              'Manage Bookings', 
              'Approve or reject bookings', 
              Icons.calendar_month, 
              Colors.blue,
              const AdminBookingsScreen()
            ),
            const SizedBox(height: 16),
             _buildLinkCard(
              context,
              'Manage Providers', 
              'Add or remove services', 
              Icons.agriculture, 
              Colors.green,
              const AdminProvidersScreen()
            ),
            const SizedBox(height: 16),
             _buildLinkCard(
              context,
              'Manage Users', 
              'Block or unblock users', 
              Icons.manage_accounts, 
              Colors.purple,
              const AdminUsersScreen()
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard(BuildContext context, String title, String subtitle, IconData icon, Color color, Widget targetScreen) {
    return Card(
      color: Colors.white,
      elevation: 0,
       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!)
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
