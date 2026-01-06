import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.isFromProfile 
          ? AppBar(
              title: const Text('Select Language'),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!widget.isFromProfile) ...[
                const SizedBox(height: 40),
                // Logo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00AA55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.eco,
                    size: 35,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Agri Farms',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00AA55),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 40),
                // Headers
                const Text(
                  'Select Your Language',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose your preferred language',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
              ],
              
              // Language List
              Expanded(
                child: ListView.separated(
                  itemCount: languages.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final language = languages[index];
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        title: Text(
                          language['native']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        trailing: Text(
                          language['name']!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('selected_language', language['name']!);

                          if (!mounted) return;

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
            ],
          ),
        ),
      ),
    );
  }
}
