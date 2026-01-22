import 'package:flutter/material.dart';
import 'dart:math';
import 'home_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final String bookingId;
  final String bookingTitle;
  
  const BookingConfirmationScreen({
    super.key,
    required this.bookingId,
    required this.bookingTitle,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> with TickerProviderStateMixin {
  late AnimationController _appearController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  // Confetti
  late AnimationController _confettiController;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    // Main Content Animation
    _appearController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _appearController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _appearController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    // Leaf Confetti Setup
    _confettiController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    for (int i = 0; i < 30; i++) {
        _particles.add(ConfettiParticle(_random));
    }

    _appearController.forward();
  }

  @override
  void dispose() {
    _appearController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Pattern (Faint)
          Positioned.fill(
             child: Opacity(
               opacity: 0.05,
               child: GridView.builder(
                 physics: const NeverScrollableScrollPhysics(),
                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
                 itemBuilder: (context, index) {
                   return Icon(
                     index % 2 == 0 ? Icons.water_drop : Icons.grass, // Alternate icons
                     color: Colors.green,
                   );
                 },
                 itemCount: 100, // Enough to fill screen roughly
               ),
             ),
          ),
          
          // Confetti Layer
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                painter: ConfettiPainter(_particles, _confettiController.value),
                size: Size.infinite,
              );
            },
          ),

          // Main Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Fancy Icon (Growing Plant / Success)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00AA55), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00AA55).withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Stack(
                         alignment: Alignment.center,
                         children: [
                           // Background Glow
                           Container(
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               gradient: RadialGradient(
                                 colors: [
                                   Colors.green.withOpacity(0.2),
                                   Colors.transparent,
                                 ],
                               ),
                             ),
                           ),
                           // Icons
                           const Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Icon(Icons.eco, size: 60, color: Color(0xFF00AA55)), // Plant
                               SizedBox(height: 8),
                               Icon(Icons.check_circle, size: 30, color: Colors.orangeAccent), // Checkmark badge
                             ],
                           )
                         ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  FadeTransition(
                    opacity: _opacityAnimation,
                    child: Column(
                      children: [
                        const Text(
                          'Booking Successful!',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32), // Dark Green
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your request for "${widget.bookingTitle}"\nhas been planted!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Ticket Style ID
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8E9), // Light Green bg
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFAED581)), // Light Green border
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.confirmation_number_outlined, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Booking ID: #${widget.bookingId.substring(widget.bookingId.length - 6)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF33691E),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  FadeTransition(
                    opacity: _opacityAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                           Navigator.of(context).pushAndRemoveUntil(
                             MaterialPageRoute(builder: (context) => const HomeScreen()),
                             (route) => false,
                           );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00AA55),
                          elevation: 8,
                          shadowColor: const Color(0xFF00AA55).withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Pill shape
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'Back to Home',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
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
    );
  }
}

// --- Confetti / Particle System ---

class ConfettiParticle {
  late double x;
  late double y;
  late double speed;
  late double size;
  late double angle;
  late Color color;

  ConfettiParticle(Random random) {
    reset(random, true);
  }

  void reset(Random random, bool initial) {
    x = random.nextDouble();
    y = initial ? random.nextDouble() : -0.2; // Start above screen if not initial
    speed = 0.005 + random.nextDouble() * 0.01;
    size = 5 + random.nextDouble() * 10;
    angle = random.nextDouble() * 2 * pi;
    
    // Varying green shades for leaves
    List<Color> colors = [Colors.green, Colors.lightGreen, Colors.teal, Colors.orangeAccent];
    color = colors[random.nextInt(colors.length)];
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double animationValue; // continuous 0..1 loop not really used directly if we animate particles themselves, but triggers repaint

  ConfettiPainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var particle in particles) {
      // Update position
      particle.y += particle.speed;
      particle.angle += 0.05;

      // Reset if off screen
      if (particle.y > 1.2) {
        particle.y = -0.1;
        particle.x = Random().nextDouble();
      }

      final xPos = particle.x * size.width;
      final yPos = particle.y * size.height;

      paint.color = particle.color.withOpacity(0.6);
      
      canvas.save();
      canvas.translate(xPos, yPos);
      canvas.rotate(particle.angle);
      
      // Draw a simple leaf shape (oval)
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size / 2),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Always repaint for animation
}
