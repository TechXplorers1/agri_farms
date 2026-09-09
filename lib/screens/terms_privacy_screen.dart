import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
                      color: Colors.black.withOpacity(0.05),
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

class _TermsOfServiceTab extends StatelessWidget {
  const _TermsOfServiceTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Terms of Service',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            '1. Acceptance of Terms\n'
            'By accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement.\n\n'
            
            '2. Use of License\n'
            'Permission is granted to temporarily download one copy of the materials (information or software) on Agri Farms\' application for personal, non-commercial transitory viewing only.\n\n'
            
            '3. User Account\n'
            'To use certain features of the app, you may be required to register for an account. You agree to keep your password confidential and will be responsible for all use of your account and password.\n\n'
            
            '4. Services\n'
            'The application facilitates connection between farmers, equipment owners, and service providers. We act as an intermediary platform and are not directly responsible for the quality of varied services provided by third parties.\n\n'
            
            '5. Booking and Cancellation\n'
            'Bookings made through the platform are subject to availability. Cancellations may be subject to fees as per the specific service provider\'s policy.\n\n'
            
            '6. Disclaimer\n'
            'The materials on Agri Farms\' application are provided on an \'as is\' basis. Agri Farms makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability.',
            style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _PrivacyPolicyTab extends StatelessWidget {
  const _PrivacyPolicyTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'AgriFarms Privacy & Transparency Policy',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00AA55)),
          ),
          SizedBox(height: 4),
          Text(
            'Google Play Store Verified & Compliant | Effective Date: August 27, 2026',
            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 16),
          Text(
            '1. Application Overview & Scope\n'
            'AgriFarms ("we", "our", or "us") operates a multi-sided agricultural technology platform connecting farmers, tractor/machinery rental providers, transport vehicle owners, and farm worker group leaders. We are committed to absolute transparency regarding how user data is collected, used, shared, protected, and deleted.\n\n'

            '2. Detailed Data Collection Inventory\n'
            'To provide location-based agricultural equipment matching, transport booking, and workforce hiring, we collect:\n'
            '• Personal Identifiable Information (PII): Full Name, 10-digit Phone Number, Email Address, Profile Picture, User Role (Farmer, Equipment Owner, Worker Group Leader, Admin), and Complete Address (House No, Street, Village, Mandal, District, State, Pincode).\n'
            '• Precise & Approximate Location Data: Foreground and background GPS coordinates (Latitude & Longitude) to calculate proximity distance in km between farmers and available machinery, reverse-geocoded Village & District names, and field pickup/delivery addresses.\n'
            '• Asset & Vehicle Information: Tractor/Machine specifications (Brand, Model, Horsepower, Condition, Attached Implements), Vehicle Registration Numbers, Load Capacity (Tons), Hourly/Daily Rental Pricing, Worker Group Headcount (Male/Female), and Daily Wages.\n'
            '• Transactional & Booking Data: Scheduled start/end times, land acreage, crop type, field instructions, booking status history, cancellation reasons, and ratings/reviews.\n'
            '• Device & Technical Data: Firebase Push Notification Tokens (FCM), locale/language preferences, notification toggles, uploaded machinery photos, and crop disease photos.\n\n'

            '3. Third-Party Service Providers & SDK Disclosures\n'
            'We disclose the following integrated 3rd-party services:\n'
            '• MSG91 Gateway: Sends 4-digit SMS OTPs for phone authentication via secure HTTPS.\n'
            '• Google Firebase (Auth & FCM): Phone token verification and real-time push notification delivery.\n'
            '• AWS S3 (Amazon Web Services): Encrypted cloud storage for user profile photos and equipment images.\n'
            '• Keycloak OIDC Server: Enterprise single sign-on identity management and user synchronization.\n'
            '• OpenStreetMap / Nominatim / Geolocator: Geocoding GPS coordinates to Village/District names.\n\n'

            '4. Information Sharing Boundaries Between Users\n'
            '• Shared to Farmers: Tractor/Vehicle specifications, Rental rates, Operator availability, Overall rating (e.g. 4.8★), Business Name, Proximity distance (km), Village and District.\n'
            '  *Boundary: Vendor\'s exact house number and personal street address are NOT displayed on public marketplace listings.\n'
            '• Shared to Providers upon Booking: Farmer\'s Full Name, Phone Number (for dispatch contact), Field Location Address, Field GPS Coordinates, Scheduled Date/Time, Crop Type, and Acreage.\n'
            '  *Boundary: Providers can ONLY view farmer details for bookings submitted directly for their own listed assets. Providers cannot search or browse unbooked farmer profiles.\n\n'

            '5. Data Security & Encrypted Storage\n'
            '• Encryption in Transit: All API traffic uses industry-standard TLS 1.3 / HTTPS.\n'
            '• Secure Mobile Storage: Access tokens are encrypted on mobile hardware using flutter_secure_storage (iOS Keychain and Android KeyStore AES-256 encryption).\n'
            '• Database Protection: Enterprise PostgreSQL database storage with Role-Based Access Control (RBAC) and parameterized queries.\n'
            '• Path Sanitization: Image uploads undergo file path sanitization to block directory traversal attacks.\n\n'

            '6. Inactive User Policy & Automatic Disabling\n'
            '• Automatic Availability Disabling: When an account status is set to Inactive, Deactivated, Suspended, or Banned, all equipment, transport vehicles, services, and worker groups owned by that user are AUTOMATICALLY set to inactive (isAvailable = false), immediately hiding them from public search.\n'
            '• Retention Window: Active user data is retained during active account use. Accounts inactive for 180+ days are archived. Accounts inactive for 365+ days undergo PII anonymization or purging.\n\n'

            '7. User Rights & Account Deletion Request\n'
            'In compliance with Google Play Store Data Safety policies, you have the right to access, correct, or request complete deletion of your account and personal data.\n'
            '• In-App Deletion: Navigate to Profile Settings -> Delete Account.\n'
            '• Email Deletion Request: Send an email to support@agrifarms.in with the subject line "Account Deletion Request" and your registered phone number. Requests are processed within 7 business days.\n\n'

            '8. Contact Information & Data Protection Officer\n'
            'Email: support@agrifarms.in\n'
            'Jurisdiction: Andhra Pradesh, India',
            style: TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
