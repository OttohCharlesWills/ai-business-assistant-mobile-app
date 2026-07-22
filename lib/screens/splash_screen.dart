import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../helpers/role_router.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final loggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      await RoleRouter.navigateFromSaved(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1F3F),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF2F5DA8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "AI Business Assistant",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Smart tools for your business",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8FAADC),
              ),
            ),

            const SizedBox(height: 40),

            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFF8FAADC),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}