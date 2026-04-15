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
      'icon': Icons.agriculture_outlined, // Tractor
      'color': Colors.deepOrange,
      'bgColor': const Color(0xFFFFF3E0), // Light Orange
    },
    {
      'title': l10n.bookServices,
      'description': "Hire ploughing, harvesting, spraying services.",
      'icon': Icons.grass_outlined, // Crop/Farm Work
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
      MaterialPageRoute(builder: (context) => const AuthScreen()),
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
    final pages = _getPages(context);
    return Scaffold(
      body: Container(
        color: const Color(0xFFF5F7F2),
        child: SafeArea(
          child: Column(
            children: [
              // Skip Button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextButton(
                    onPressed: _onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[400],
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.skip.toUpperCase(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
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
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon Circle (Premium Soft Glow)
                          Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (page['color'] as Color).withOpacity(0.1),
                                  blurRadius: 50,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Stack(
                               alignment: Alignment.center,
                               children: [
                                 Container(
                                   width: 180,
                                   height: 180,
                                   decoration: BoxDecoration(
                                     color: (page['color'] as Color).withOpacity(0.05),
                                     shape: BoxShape.circle,
                                   ),
                                 ),
                                 Icon(
                                   page['icon'],
                                   size: 100,
                                   color: page['color'],
                                 ),
                               ],
                            ),
                          ),
                          const SizedBox(height: 60),
                          // Title
                          Text(
                            page['title'],
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B5E20),
                              letterSpacing: -1.0,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          // Description
                          Text(
                            page['description'],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Indicators & Button Section
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? const Color(0xFF00AA55) 
                                : const Color(0xFFDCE2D6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Next / Get Started Button (Premium Lush)
                    Container(
                      width: double.infinity,
                      height: 66,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B5E20).withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == pages.length - 1 
                                  ? AppLocalizations.of(context)!.getStarted.toUpperCase()
                                  : AppLocalizations.of(context)!.next.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              _currentPage == pages.length - 1 ? Icons.rocket_launch_rounded : Icons.arrow_forward_ios_rounded,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
