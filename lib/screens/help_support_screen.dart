import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@agrifarms.com',
      queryParameters: {
        'subject': 'Agri Farms Help & Support Request',
      },
    );
    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open email client: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _makeCall() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: '+9118001234567',
    );
    try {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open dialer: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _submitFeedback() async {
    final message = _feedbackController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your feedback or request message'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'Unknown User ID';
      final name = prefs.getString('user_name') ?? 'Unknown User';
      final email = prefs.getString('user_email') ?? 'No email';
      final phone = prefs.getString('user_phone') ?? 'No phone';

      await ApiService().submitSupportRequest(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        message: message,
      );

      if (mounted) {
        _feedbackController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support request submitted successfully! Admin has been notified.'),
            backgroundColor: Color(0xFF00AA55),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit support request: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B5E20), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(color: Color(0xFF1B5E20), fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF00AA55).withOpacity(0.08), shape: BoxShape.circle),
                    child: const Icon(Icons.support_agent_rounded, size: 60, color: Color(0xFF00AA55)),
                  ),
                  const SizedBox(height: 16),
                  const Text('How can we help you?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 8),
                  Text('Search for answers or contact our team', style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20), letterSpacing: -0.3),
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
                  const SizedBox(height: 32),
                  const Text(
                    'Direct Contact',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20), letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 16),
                  _buildContactOption(
                    Icons.alternate_email_rounded,
                    'Email Support',
                    'support@agrifarms.com',
                    const Color(0xFF1565C0),
                    onTap: _sendEmail,
                  ),
                  const SizedBox(height: 12),
                  _buildContactOption(
                    Icons.headset_mic_rounded,
                    'Call Helpline',
                    '+91 1800 123 4567',
                    const Color(0xFF00AA55),
                    onTap: _makeCall,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Send Feedback',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20), letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _feedbackController,
                          maxLines: 4,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
                          decoration: InputDecoration(
                            hintText: 'Tell us how we can improve...',
                            hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[100]!)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[100]!)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF00AA55))),
                            filled: true,
                            fillColor: const Color(0xFFF9FBF9),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: const Color(0xFF00AA55).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
                          ),
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitFeedback,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00AA55),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF00AA55).withOpacity(0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Text('SUBMIT FEEDBACK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1B5E20)),
        ),
        iconColor: const Color(0xFF00AA55),
        collapsedIconColor: Colors.grey[400],
        children: [
          Text(
            answer,
            style: TextStyle(color: Colors.grey[600], height: 1.5, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(IconData icon, String title, String subtitle, Color color, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1B5E20), fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600, fontSize: 13)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[300]),
        onTap: onTap,
      ),
    );
  }
}
