import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../widgets/app_loader.dart';
import 'admin/dashboard_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  void registerUser() async {
    setState(() => loading = true);

    try {
      final response = await AuthService.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      setState(() => loading = false);

      final success = response['status'] == true;
      final message = response['message'] ?? "No response message";

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      if (success) {
        await FCMService.init(); // ✅ init FCM + send token to backend
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      setState(() => loading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> googleLogin() async {
    setState(() => loading = true);

    final response = await AuthService.googleLogin();

    setState(() => loading = false);

    final success = response['status'] == true;

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response['message'])),
    );

    if (success) {
      await FCMService.init(); // ✅ init FCM + send token to backend
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1F3F),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              // TOP HEADER SECTION
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F5DA8).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Show loader while registering
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: AppLoader(size: 56),
                      ),

                    if (!loading)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F5DA8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.smart_toy_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),

                    const SizedBox(height: 20),

                    const Text(
                      "Create Account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Join and start managing your business",
                      style: TextStyle(color: Color(0xFF8FAADC), fontSize: 15),
                    ),
                  ],
                ),
              ),

              // FORM CARD
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F2847),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    const SizedBox(height: 8),

                    _buildLabel("Full Name"),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: nameController,
                      hint: "Enter your full name",
                      icon: Icons.person_outline_rounded,
                    ),

                    const SizedBox(height: 20),

                    _buildLabel("Email Address"),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: emailController,
                      hint: "Enter your email",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 20),

                    _buildLabel("Password"),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C1F3F),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Create a password",
                          hintStyle: const TextStyle(
                            color: Color(0xFF8FAADC),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: Color(0xFF8FAADC),
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF8FAADC),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => obscurePassword = !obscurePassword);
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // REGISTER BUTTON
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F5DA8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: loading ? null : registerUser,
                        child: loading
                            ? const AppLoader(size: 28)
                            : const Text(
                                "Create Account",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: const Color(0xFF2F5DA8).withOpacity(0.3),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "or",
                            style: TextStyle(color: Color(0xFF8FAADC), fontSize: 13),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: const Color(0xFF2F5DA8).withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: const Color(0xFF2F5DA8).withOpacity(0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: loading ? null : googleLogin,
                        icon: const Icon(
                          Icons.g_mobiledata_rounded,
                          color: Color(0xFF8FAADC),
                          size: 28,
                        ),
                        label: const Text(
                          "Continue with Google",
                          style: TextStyle(color: Color(0xFF8FAADC), fontSize: 15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account?",
                          style: TextStyle(color: Color(0xFF8FAADC), fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C1F3F),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF8FAADC), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF8FAADC), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}