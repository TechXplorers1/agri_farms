import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;


  List<Map<String, dynamic>> _getPages(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
    {
      'title': l10n.rentEquipment,
      'description': l10n.rentEquipmentDesc,
      'icon': Icons.build_outlined, // Wrench
      'color': Colors.deepOrange,
      'bgColor': const Color(0xFFFFF3E0), // Light Orange
    },
    {
      'title': l10n.bookServices,
      'description': "Hire ploughing, harvesting, spraying services.",
      'icon': Icons.agriculture_outlined, // Tractor/Agri
      'color': Colors.green,
      'bgColor': const Color(0xFFE8F5E9), // Light Green
    },
    {
      'title': l10n.bookTransport,
      'description': "Book transport to take your produce to mandi.",
      'icon': Icons.local_shipping_outlined, // Truck
      'color': Colors.blue,
      'bgColor': const Color(0xFFE3F2FD), // Light Blue
    },
  ];
  }

  void _onSkip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _onNext() {
    if (_currentPage < _getPages(context).length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _onSkip();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _onSkip,
                child: Text(
                  AppLocalizations.of(context)!.skip,
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
            
            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _getPages(context).length,
                itemBuilder: (context, index) {
                  final page = _getPages(context)[index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon Circle
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: page['bgColor'],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page['icon'],
                            size: 80,
                            color: page['color'],
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Title
                        Text(
                          page['title'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.normal,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Description
                        Text(
                          page['description'],
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _getPages(context).length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF00AA55) // Active Green
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),

            // Next / Get Started Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF050510), // Dark Navy/Black
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == _getPages(context).length - 1 ? AppLocalizations.of(context)!.getStarted : AppLocalizations.of(context)!.next,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_currentPage < _getPages(context).length - 1) ...[
                        const SizedBox(width: 8),
                         const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                      ]
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
