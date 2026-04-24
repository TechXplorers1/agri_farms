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
      backgroundColor: const Color(0xFFF5F7F2),
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
                     index % 2 == 0 ? Icons.water_drop_rounded : Icons.grass_rounded,
                     color: const Color(0xFF00AA55),
                   );
                 },
                 itemCount: 100,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Fancy Icon (Lush Success)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00AA55).withOpacity(0.15),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Stack(
                         alignment: Alignment.center,
                         children: [
                           // Background Glows
                           Container(
                             margin: const EdgeInsets.all(15),
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               gradient: RadialGradient(
                                 colors: [
                                   const Color(0xFF00AA55).withOpacity(0.1),
                                   Colors.transparent,
                                 ],
                               ),
                             ),
                           ),
                           // Icons
                           Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Container(
                                 padding: const EdgeInsets.all(20),
                                 decoration: BoxDecoration(
                                   color: const Color(0xFF00AA55).withOpacity(0.1),
                                   shape: BoxShape.circle,
                                 ),
                                 child: const Icon(Icons.eco_rounded, size: 64, color: Color(0xFF00AA55)),
                               ),
                               const SizedBox(height: 8),
                               const Icon(Icons.check_circle_rounded, size: 28, color: Colors.orangeAccent),
                             ],
                           )
                         ],
                       ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  FadeTransition(
                    opacity: _opacityAnimation,
                    child: Column(
                      children: [
                        const Text(
                          'Booking Successful!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1B5E20),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your request for "${widget.bookingTitle}"\nhas been sent to the provider.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        const SizedBox(height: 40),

                        // Ticket Style Confirmation Card
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F7F2),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.confirmation_num_rounded, color: Color(0xFF00AA55)),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'BOOKING ID',
                                            style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '#${widget.bookingId.substring(widget.bookingId.length - 8).toUpperCase()}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color(0xFF1B5E20),
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Divider with Cutouts (Ticket look)
                              Row(
                                children: [
                                  Container(width: 10, height: 20, decoration: const BoxDecoration(color: Color(0xFFF5F7F2), borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)))),
                                  Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: CustomPaint(painter: DashLinePainter(), size: const Size(double.infinity, 1)))),
                                  Container(width: 10, height: 20, decoration: const BoxDecoration(color: Color(0xFFF5F7F2), borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)))),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.info_outline_rounded, size: 14, color: Colors.orangeAccent),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Awaiting provider confirmation',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ],
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
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF00AA55).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                           Navigator.of(context).pushAndRemoveUntil(
                             MaterialPageRoute(builder: (context) => const HomeScreen()),
                             (route) => false,
                           );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00AA55),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home_rounded, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'Back to Home',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      // Navigate to My Services / History
                       Navigator.of(context).pushAndRemoveUntil(
                             MaterialPageRoute(builder: (context) => const HomeScreen(initialIndex: 3)), // Assuming 3 is History
                             (route) => false,
                           );
                    },
                    child: const Text(
                      'View Booking Details',
                      style: TextStyle(color: Color(0xFF00AA55), fontWeight: FontWeight.w800, fontSize: 15),
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

class DashLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    var max = size.width;
    var dashWidth = 5;
    var dashSpace = 5;
    double startX = 0;
    while (startX < max) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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
