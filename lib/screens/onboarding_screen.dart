import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {

  final PageController _controller = PageController();
  int currentPage = 0;

  late AnimationController _floatController;
  late AnimationController _rotateController;
  late Animation<double> _floatAnimation;

  final List<Map<String, dynamic>> onboardingData = [
    {
      "icon": Icons.analytics_rounded,
      "title": "Track Your Business",
      "description": "Monitor your sales, products and profits easily from your phone.",
      "color": const Color(0xFF2F5DA8),
      "lightColor": const Color(0xFF8FAADC),
    },
    {
      "icon": Icons.smart_toy_rounded,
      "title": "AI Business Assistant",
      "description": "Talk to AI naturally and let it update your inventory and sales.",
      "color": const Color(0xFF0C1F3F),
      "lightColor": const Color(0xFF2F5DA8),
    },
    {
      "icon": Icons.insights_rounded,
      "title": "Smart Insights",
      "description": "Get business advice, low stock alerts and sales analysis.",
      "color": const Color(0xFF2F5DA8),
      "lightColor": const Color(0xFF8FAADC),
    },
  ];

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _floatAnimation = Tween<double>(begin: -12, end: 12).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _floatController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void nextPage() {
    if (currentPage < onboardingData.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0C1F3F),

      body: SafeArea(
        child: Column(
          children: [

            // 🔥 PAGE VIEW ADDED (THIS WAS THE BUG)
            Expanded(
              flex: 5,
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemBuilder: (context, index) {

                  final item = onboardingData[index];

                  return Stack(
                    alignment: Alignment.center,
                    children: [

                      // ROTATING RING 1 (UNCHANGED)
                      AnimatedBuilder(
                        animation: _rotateController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotateController.value * 2 * math.pi,
                            child: Container(
                              width: 260,
                              height: 260,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF2F5DA8).withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: CustomPaint(
                                painter: _DashedCirclePainter(
                                  color: const Color(0xFF8FAADC).withOpacity(0.3),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // ROTATING RING 2
                      AnimatedBuilder(
                        animation: _rotateController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: -_rotateController.value * 2 * math.pi,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF2F5DA8).withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // GLOW CIRCLE
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2F5DA8).withOpacity(0.15),
                        ),
                      ),

                      // FLOATING ICON
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Container(
                          key: ValueKey(index),
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: item['color'],
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: (item['color'] as Color).withOpacity(0.4),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            item['icon'],
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // FLOATING DOTS (UNCHANGED)
                      ..._buildFloatingDots(),
                    ],
                  );
                },
              ),
            ),

            // 🔥 BOTTOM SECTION (UNCHANGED UI)
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0F2847),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [

                  // INDICATORS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: currentPage == index
                              ? const Color(0xFF8FAADC)
                              : const Color(0xFF2F5DA8).withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // TITLE
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      onboardingData[currentPage]['title'],
                      key: ValueKey(currentPage),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // DESCRIPTION
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      onboardingData[currentPage]['description'],
                      key: ValueKey("desc$currentPage"),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF8FAADC),
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F5DA8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        currentPage == onboardingData.length - 1
                            ? "Get Started"
                            : "Next",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (currentPage < onboardingData.length - 1)
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Skip",
                        style: TextStyle(color: Color(0xFF8FAADC)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFloatingDots() {
    final positions = [
      const Offset(-110, -80),
      const Offset(110, -60),
      const Offset(-90, 90),
      const Offset(100, 80),
      const Offset(-40, -120),
      const Offset(50, 120),
    ];

    final sizes = [8.0, 6.0, 10.0, 6.0, 8.0, 6.0];

    return List.generate(positions.length, (index) {
      return AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          final offset = index.isEven
              ? _floatAnimation.value * 0.4
              : -_floatAnimation.value * 0.4;

          return Transform.translate(
            offset: Offset(
              positions[index].dx,
              positions[index].dy + offset,
            ),
            child: Container(
              width: sizes[index],
              height: sizes[index],
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8FAADC).withOpacity(0.4),
              ),
            ),
          );
        },
      );
    });
  }
}

// DASHED PAINTER (UNCHANGED)
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dashCount = 20;
    const dashLength = 0.15;
    const gapLength = 0.16;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * (dashLength + gapLength) * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashLength * math.pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}