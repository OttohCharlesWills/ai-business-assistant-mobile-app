import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_loader.dart';
import 'admin/dashboard_screen.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool checking = false;
  bool resending = false;

  Future<void> checkVerified() async {
    setState(() => checking = true);

    final verified = await AuthService.checkVerificationStatus();

    setState(() => checking = false);

    if (!mounted) return;

    if (verified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Still not verified. Check your inbox and tap the link."),
        ),
      );
    }
  }

  Future<void> resendEmail() async {
    setState(() => resending = true);

    final response = await AuthService.resendVerificationEmail();

    setState(() => resending = false);

    if (!mounted) return;

    final message = response['message'] ?? "Verification email sent.";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> logout() async {
    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1F3F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F5DA8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: Color(0xFF8FAADC),
                  size: 34,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Verify Your Email",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              const Text(
                "We've sent a verification link to your email address. Tap it, then come back here and press the button below.",
                style: TextStyle(color: Color(0xFF8FAADC), fontSize: 14),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F5DA8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: checking ? null : checkVerified,
                  child: checking
                      ? const AppLoader(size: 28)
                      : const Text(
                          "I've Verified My Email",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: const Color(0xFF2F5DA8).withOpacity(0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: resending ? null : resendEmail,
                  child: resending
                      ? const AppLoader(size: 24)
                      : const Text(
                          "Resend Verification Email",
                          style: TextStyle(color: Color(0xFF8FAADC), fontSize: 15),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: logout,
                child: const Text(
                  "Log out",
                  style: TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}