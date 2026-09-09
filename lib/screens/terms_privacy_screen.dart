import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';

class TermsPrivacyScreen extends StatefulWidget {
  final bool isAcceptanceMode;
  
  const TermsPrivacyScreen({super.key, this.isAcceptanceMode = false});

  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen> {
  bool _hasAccepted = false;

  void _onAccept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_accepted', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Terms & Privacy'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          bottom: const TabBar(
            labelColor: Color(0xFF00AA55),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF00AA55),
            tabs: [
              Tab(text: 'Terms of Service'),
              Tab(text: 'Privacy Policy'),
            ],
          ),
        ),
        body: Column(
          children: [
            const Expanded(
              child: TabBarView(
                children: [
                  _TermsOfServiceTab(),
                  _PrivacyPolicyTab(),
                ],
              ),
            ),
            if (widget.isAcceptanceMode)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _hasAccepted,
                            activeColor: const Color(0xFF00AA55),
                            onChanged: (value) {
                              setState(() {
                                _hasAccepted = value ?? false;
                              });
                            },
                          ),
                          const Expanded(
                            child: Text(
                              'I have read and agree to the Terms of Service and Privacy Policy',
                              style: TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _hasAccepted ? _onAccept : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00AA55),
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Accept and Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Terms of Service Tab
// ─────────────────────────────────────────────────────────────────────────────
class _TermsOfServiceTab extends StatelessWidget {
  const _TermsOfServiceTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Terms of Service', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('Last updated: September 2026', style: TextStyle(fontSize: 12, color: Colors.grey)),
          SizedBox(height: 16),
          Text(
            '1. Acceptance of Terms\n'
            'By downloading and using the Agri Farms application, you agree to be bound by these Terms of Service. If you do not agree, do not use the app.\n\n'
            '2. Eligibility\n'
            'You must be at least 18 years old to use Agri Farms. By registering, you confirm you meet this requirement.\n\n'
            '3. User Roles\n'
            'The platform supports two roles:\n'
            '• Farmer: Can browse and book equipment, services, transport, and farm workers.\n'
            '• Owner/Vendor: Can list and manage equipment, services, transport, or worker groups for booking.\n\n'
            '4. Account Registration\n'
            'You must register using a valid Indian mobile number. OTP verification is required. You are responsible for maintaining the security of your account.\n\n'
            '5. Bookings and Cancellations\n'
            'Bookings made through Agri Farms are subject to the service provider\'s availability and pricing. Cancellation policies vary by provider. Agri Farms acts as a marketplace intermediary only.\n\n'
            '6. User Conduct\n'
            'You agree not to:\n'
            '• Post false or misleading listings\n'
            '• Harass or harm other users\n'
            '• Use the platform for any unlawful purpose\n'
            '• Attempt to reverse-engineer the app\n\n'
            '7. Content and Listings\n'
            'You retain ownership of content you upload. By uploading, you grant Agri Farms a license to display it within the app. We may remove content that violates these terms.\n\n'
            '8. Account Deletion\n'
            'You can permanently delete your account from Profile > Danger Zone > Delete Account. Your data will be erased from our servers within 30 days. You may also request deletion at: https://agrifarms.in/account-deletion\n\n'
            '9. Disclaimer\n'
            'Agri Farms is a marketplace platform. We are not directly responsible for the quality, safety, or legality of services provided by third-party vendors.\n\n'
            '10. Termination\n'
            'We reserve the right to suspend or terminate accounts that violate these terms.\n\n'
            '11. Contact\n'
            'For any queries: support@agrifarms.in',
            style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Privacy Policy Tab — Play Store compliant: discloses all data collected,
// all third-party sharing (MSG91, Firebase, AWS), and deletion rights.
// ─────────────────────────────────────────────────────────────────────────────
class _PrivacyPolicyTab extends StatelessWidget {
  const _PrivacyPolicyTab();

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Privacy Policy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Last updated: September 2026', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          const Text(
            '1. What Information We Collect\n'
            'We collect the following personal data when you use Agri Farms:\n\n'
            '• Mobile Phone Number — for OTP-based identity verification during login and registration.\n\n'
            '• Full Name — provided during registration; displayed on your profile and to service providers you book.\n\n'
            '• Location (GPS) — collected while using the app to find nearby equipment, services, and workers. We collect precise GPS coordinates only while the app is in the foreground. We do NOT track location in the background.\n\n'
            '• Profile Photo & Listing Images — photos you upload are stored securely on AWS S3 and displayed within the app only.\n\n'
            '• Device Token (Firebase FCM) — a push notification identifier assigned by Firebase, used only to send you booking updates. Not used for advertising.\n\n'
            '• Address Details — village, district, state, and pincode entered on your profile; used to auto-fill location fields.\n\n'

            '2. How We Use Your Information\n'
            '• To create and maintain your account\n'
            '• To verify your identity via OTP\n'
            '• To match you with nearby services and equipment\n'
            '• To send booking confirmation and status push notifications\n'
            '• To display your profile to service providers during a booking\n'
            '• To improve app performance and fix issues\n\n'

            '3. Who We Share Your Data With\n'
            'We share data only with trusted service partners required to operate Agri Farms:\n\n'
            '• MSG91 (India) — receives your phone number to deliver OTP SMS.\n'
            '  Privacy policy: https://msg91.com/privacy-policy\n\n'
            '• Google Firebase — receives your device FCM token to deliver push notifications.\n'
            '  Privacy policy: https://firebase.google.com/support/privacy\n\n'
            '• Amazon Web Services (AWS S3) — stores your uploaded images in a secure cloud bucket.\n'
            '  Privacy policy: https://aws.amazon.com/privacy\n\n'
            'We do NOT sell your personal data. We do NOT share data with advertisers.\n\n'

            '4. Data Retention\n'
            'Your data is retained while your account is active. When you delete your account:\n'
            '• Profile data is permanently deleted within 30 days\n'
            '• Booking records may be retained up to 1 year for legal/tax compliance\n'
            '• Images are deleted from AWS S3 within 30 days\n\n'

            '5. Your Rights & Data Deletion\n'
            'You have the right to:\n'
            '• Access the data we hold about you\n'
            '• Request correction of inaccurate data\n'
            '• Request permanent deletion of your account\n\n'
            'To delete your account: open the app → Profile → Danger Zone → Delete Account.\n'
            'Or submit a request at: https://agrifarms.in/account-deletion\n\n'

            '6. Security\n'
            '• All API communication uses HTTPS (TLS)\n'
            '• Authentication tokens are stored in encrypted device storage\n'
            '• Our backend is hosted on AWS with strict access controls\n\n'

            '7. Children\'s Privacy\n'
            'Agri Farms is not intended for users under 18. We do not knowingly collect data from minors.\n\n'

            '8. Changes to this Policy\n'
            'We will notify you of significant changes via push notification or in-app message.\n\n'

            '9. Contact Us',
            style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _openUrl('mailto:support@agrifarms.in'),
            child: const Text(
              '📧  support@agrifarms.in',
              style: TextStyle(fontSize: 14, color: Color(0xFF00AA55), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _openUrl('https://agrifarms.in/privacy-policy'),
            child: const Text(
              '🌐  agrifarms.in/privacy-policy',
              style: TextStyle(fontSize: 14, color: Color(0xFF00AA55), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
