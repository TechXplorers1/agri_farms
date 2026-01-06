import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Weather Alerts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            Text(
              'Farmer-specific notifications',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotificationCard(
            type: 'rain',
            title: 'Heavy Rain Expected',
            description: 'Moderate to heavy rainfall expected in next 48 hours. Total rainfall: 50-70mm.',
            advice: 'Postpone pesticide spraying. Ensure proper drainage in fields. Cover harvested produce.',
            time: '2 hours ago',
          ),
          const SizedBox(height: 16),
          _buildNotificationCard(
            type: 'heat',
            title: 'High Temperature Alert',
            description: 'Temperature will rise to 38-40°C in next 3 days.',
            advice: 'Increase irrigation frequency. Apply mulch to retain moisture. Avoid working in fields during peak afternoon hours.',
            time: '5 hours ago',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required String type,
    required String title,
    required String description,
    required String advice,
    required String time,
  }) {
    final bool isRain = type == 'rain';
    final Color bgColor = isRain ? const Color(0xFFE3F2FD) : const Color(0xFFFFF8E1); // Light Blue / Light Orange
    final Color iconBg = isRain ? const Color(0xFFFFF9C4) : const Color(0xFFFFF9C4); // Yellowish for icon bg in both (from image)
    final IconData icon = isRain ? Icons.thunderstorm_outlined : Icons.wb_sunny_outlined;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
           BoxShadow(
             color: Colors.grey.withOpacity(0.05),
             blurRadius: 5,
             offset: const Offset(0, 2),
           )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.brown[700], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'New',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Advice Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFC8E6C9)), // Light Green Border
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFF2E7D32), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Farming Advice',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  advice,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Time
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
