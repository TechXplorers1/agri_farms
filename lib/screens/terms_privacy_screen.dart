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
            'Privacy Policy',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            '1. Information Collection\n'
            'We collect information from you when you register on our site, place an order, subscribe to our newsletter, respond to a survey or fill out a form.\n\n'
            
            '2. Use of Information\n'
            'Any of the information we collect from you may be used in one of the following ways: \n'
            '- To personalize your experience\n'
            '- To improve our application\n'
            '- To improve customer service\n'
            '- To process transactions\n\n'
            
            '3. Information Protection\n'
            'We implement a variety of security measures to maintain the safety of your personal information when you place an order or enter, submit, or access your personal information.\n\n'
            
            '4. Disclosure to Third Parties\n'
            'We do not sell, trade, or otherwise transfer to outside parties your personally identifiable information. This does not include trusted third parties who assist us in operating our application, conducting our business, or servicing you, so long as those parties agree to keep this information confidential.\n\n'
            
            '5. Changes to our Privacy Policy\n'
            'If we decide to change our privacy policy, we will post those changes on this page.',
            style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
