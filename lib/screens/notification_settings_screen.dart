import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // State variables for toggles
  bool _orderUpdates = true;
  bool _bookingUpdates = true;
  bool _paymentUpdates = true;
  bool _communityActivity = false;
  bool _promotionalOffers = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: Colors.grey[200],
              height: 1.0,
            )),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        children: [
          _buildSwitchTile(
            title: 'Order Updates',
            subtitle: 'Get notified about order status',
            value: _orderUpdates,
            onChanged: (val) => setState(() => _orderUpdates = val),
          ),
          const SizedBox(height: 24),
          _buildSwitchTile(
            title: 'Booking Updates',
            subtitle: 'Rental and service bookings',
            value: _bookingUpdates,
            onChanged: (val) => setState(() => _bookingUpdates = val),
          ),
          const SizedBox(height: 24),
          _buildSwitchTile(
            title: 'Payment Updates',
            subtitle: 'Transaction notifications',
            value: _paymentUpdates,
            onChanged: (val) => setState(() => _paymentUpdates = val),
          ),
          const SizedBox(height: 24),
          _buildSwitchTile(
            title: 'Community Activity',
            subtitle: 'Replies and mentions',
            value: _communityActivity,
            onChanged: (val) => setState(() => _communityActivity = val),
          ),
          const SizedBox(height: 24),
          _buildSwitchTile(
            title: 'Promotional Offers',
            subtitle: 'Deals and discounts',
            value: _promotionalOffers,
            onChanged: (val) => setState(() => _promotionalOffers = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF001F24), // Dark text color
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Transform.scale(
          scale: 0.8, // Adjust scale to match design if needed
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.black, // Thumb color when active
            activeTrackColor: Colors.white, // Track color when active (with border usually, but default switch is filled)
            // Customizing to match the black toggle look better:
            // Flutter's default Material switch might look slightly different depending on theme.
            // For a "black toggle" look:
            activeThumbImage: null,
            trackColor: WidgetStateProperty.resolveWith((states) {
               if (states.contains(WidgetState.selected)) {
                 return Colors.black;
               }
               return Colors.grey[300];
            }),
             thumbColor: WidgetStateProperty.all(Colors.white),
             trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ),
      ],
    );
  }
}
