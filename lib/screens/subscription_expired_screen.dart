import 'package:flutter/material.dart';
import '../main.dart';              // for navigatorKey
import '../services/auth_service.dart'; // wherever AuthService actually lives
import 'login_screen.dart';         // wherever LoginScreen actually lives
import 'subscription_screen.dart';
// import 'dashboard_screen.dart';  // TODO: import the screen users land on after login

class SubscriptionExpiredScreen extends StatelessWidget {
  const SubscriptionExpiredScreen({super.key});

  void _openSubscription(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubscriptionScreen(
          onActivated: () {
            navigatorKey.currentState?.pushAndRemoveUntil(
              // TODO: replace LoginScreen with your dashboard / home screen
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1F3F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F5DA8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.lock_clock_rounded,
                  size: 36,
                  color: Color(0xFF8FAADC),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Plan Expired",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your subscription has expired. Choose a plan to renew and keep using the app.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8FAADC),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F5DA8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _openSubscription(context),
                  child: const Text(
                    "Renew subscription",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await AuthService.logout(); // clear stored token
                  navigatorKey.currentState?.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text(
                  "Back to Login",
                  style: TextStyle(color: Color(0xFF8FAADC)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}