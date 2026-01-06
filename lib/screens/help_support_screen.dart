import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              'How do I book a service?',
              'Navigate to the Home screen, select "Book Services", choose your desired service type, and follow the on-screen instructions.',
            ),
            _buildFAQItem(
              'Can I cancel my rental?',
              'Yes, you can cancel your rental up to 24 hours before the scheduled time without any penalty. Go to "My Bookings" to manage your rentals.',
            ),
            _buildFAQItem(
              'What payment methods are accepted?',
              'We accept major credit/debit cards, UPI, and net banking. Cash on delivery is available for select services.',
            ),
            _buildFAQItem(
              'How do I contact the driver?',
              'Once your transport is booked, you will see the driver\'s details and a call button in the "My Bookings" section.',
            ),
            const SizedBox(height: 32),
            const Text(
              'Contact Us',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildContactOption(
              Icons.email_outlined,
              'Email Support',
              'support@agrifarms.com',
              onTap: () {
                // Implement email launch
              },
            ),
            const SizedBox(height: 12),
            _buildContactOption(
              Icons.phone_outlined,
              'Call Helpline',
              '+91 1800 123 4567',
              onTap: () {
                // Implement phone launch
              },
            ),
             const SizedBox(height: 32),
            const Text(
              'Feedback',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
             const SizedBox(height: 12),
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: Colors.grey[200]!)
               ),
               child: Column(
                 children: [
                   const TextField(
                     maxLines: 4,
                     decoration: InputDecoration(
                       hintText: 'Tell us how we can improve...',
                       border: InputBorder.none,
                     ),
                   ),
                   const SizedBox(height: 10),
                   SizedBox(
                     width: double.infinity,
                     child: ElevatedButton(
                       onPressed: (){}, 
                       style: ElevatedButton.styleFrom(
                         backgroundColor: const Color(0xFF00AA55),
                         foregroundColor: Colors.white,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                       ),
                       child: const Text('Send Feedback'),
                    ),
                   )
                 ],
               ),
             )
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      color: Colors.white,
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey[600], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
         border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[50], // Light green bg
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.green),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
