import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/language_provider.dart';
import 'onboarding_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final bool isFromProfile;
  const LanguageSelectionScreen({super.key, this.isFromProfile = false});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final List<Map<String, String>> languages = [
    {'name': 'English', 'native': 'English'},
    {'name': 'Hindi', 'native': 'हिंदी'},
    {'name': 'Telugu', 'native': 'తెలుగు'},
    {'name': 'Tamil', 'native': 'தமிழ்'},
    {'name': 'Kannada', 'native': 'ಕನ್ನಡ'},
    {'name': 'Marathi', 'native': 'मराठी'},
  ];
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: widget.isFromProfile 
          ? AppBar(
              title: const Text('Select Language', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1B5E20))),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B5E20), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.isFromProfile) ...[
              const SizedBox(height: 40),
              // Brand Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF00AA55).withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        size: 50,
                        color: Color(0xFF00AA55),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Agri Farms',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B5E20),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select Your Preferred Language',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
            
            // Language Grid/List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final language = languages[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text(
                        language['native']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      subtitle: Text(
                        language['name']!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00AA55).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF00AA55), size: 20),
                      ),
                      onTap: () {
                        // Update Language via Provider
                        Provider.of<LanguageProvider>(context, listen: false).setLanguage(language['name']!);

                        if (widget.isFromProfile) {
                          Navigator.pop(context, true); // Return true to indicate change
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            
            if (!widget.isFromProfile)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                   'You can change this anytime from Profile',
                   style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
