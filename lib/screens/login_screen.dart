import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../helpers/role_router.dart';
import '../widgets/app_loader.dart';
import '../services/fcm_service.dart';
import 'register_screen.dart';
import 'email_verification_screen.dart';
import '../helpers/error_message.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscure = true;

  Future<void> login() async {
    setState(() => loading = true);

    try {
      await AuthService.saveLastEmail(
        emailController.text.trim(),
      );

      final response = await AuthService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      setState(() => loading = false);

      final success = response['status'] == true;
      final message =
          response['message'] ?? "Something went wrong";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      if (success) {
        await FCMService.init();

        if (!mounted) return;

        final emailVerified =
            response['email_verified'] ?? true;

        // =========================================================
        // EMAIL NOT VERIFIED
        // =========================================================

        if (!emailVerified) {
          final userEmail =
              response['user']?['email'] ??
                  emailController.text.trim();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(
                email: userEmail,
              ),
            ),
          );

          return;
        }

        // =========================================================
        // EMAIL VERIFIED
        // =========================================================

        RoleRouter.navigateFromResponse(
          context,
          response,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e)),
        ),
      );
    }
  }

  Future<void> googleLogin() async {
    setState(() => loading = true);

    try {
      final response = await AuthService.googleLogin();

      if (!mounted) return;

      setState(() => loading = false);

      final success = response['status'] == true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyError(
              response['message'] ??
                  'Something went wrong',
            ),
          ),
        ),
      );

      if (success) {
        await FCMService.init();

        if (!mounted) return;

        final emailVerified =
            response['email_verified'] ?? true;

        // =========================================================
        // GOOGLE ACCOUNT EMAIL NOT VERIFIED
        // =========================================================

        if (!emailVerified) {
          final userEmail =
              response['user']?['email'] ?? '';

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(
                email: userEmail,
              ),
            ),
          );

          return;
        }

        // =========================================================
        // GOOGLE ACCOUNT EMAIL VERIFIED
        // =========================================================

        RoleRouter.navigateFromResponse(
          context,
          response,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyError(e),
          ),
        ),
      );
    }
  }

  // =========================================================
  // EXIT APP
  // =========================================================

  void _exitApp() {
    SystemNavigator.pop();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1F3F),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              // ===================================================
              // HEADER
              // ===================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  24,
                  40,
                  24,
                  30,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    // BACK / EXIT BUTTON
                    GestureDetector(
                      onTap: _exitApp,

                      child: Container(
                        width: 42,
                        height: 42,

                        decoration: BoxDecoration(
                          color: const Color(0xFF2F5DA8)
                              .withOpacity(0.2),

                          borderRadius:
                              BorderRadius.circular(12),
                        ),

                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // LOADER / LOGO
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.only(
                          bottom: 20,
                        ),

                        child: AppLoader(
                          size: 56,
                        ),
                      ),

                    if (!loading)
                      Container(
                        width: 56,
                        height: 56,

                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF2F5DA8),

                          borderRadius:
                              BorderRadius.circular(16),
                        ),

                        child: Image.asset(
                          'assets/icon/icon.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,

                          errorBuilder:
                              (_, __, ___) =>
                                  const Icon(
                            Icons.smart_toy_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),

                    const SizedBox(height: 18),

                    const Text(
                      "Welcome Back",

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Login to continue managing your business",

                      style: TextStyle(
                        color: Color(0xFF8FAADC),
                      ),
                    ),
                  ],
                ),
              ),

              // ===================================================
              // FORM CARD
              // ===================================================

              Container(
                width: double.infinity,

                decoration:
                    const BoxDecoration(
                  color: Color(0xFF0F2847),

                  borderRadius:
                      BorderRadius.only(
                    topLeft:
                        Radius.circular(32),
                    topRight:
                        Radius.circular(32),
                  ),
                ),

                padding:
                    const EdgeInsets.all(28),

                child: Column(
                  children: [

                    // EMAIL
                    _buildField(
                      controller:
                          emailController,

                      hint:
                          "Email Address",

                      icon:
                          Icons.email_outlined,

                      type:
                          TextInputType
                              .emailAddress,
                    ),

                    const SizedBox(height: 16),

                    // PASSWORD
                    Container(
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFF0C1F3F,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),

                      child: TextField(
                        controller:
                            passwordController,

                        obscureText:
                            obscure,

                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 15,
                        ),

                        decoration:
                            InputDecoration(
                          hintText:
                              "Password",

                          hintStyle:
                              const TextStyle(
                            color:
                                Color(
                              0xFF8FAADC,
                            ),
                            fontSize: 15,
                          ),

                          prefixIcon:
                              const Icon(
                            Icons.lock_outline,
                            color:
                                Color(
                              0xFF8FAADC,
                            ),
                            size: 20,
                          ),

                          suffixIcon:
                              IconButton(
                            onPressed: () {
                              setState(
                                () => obscure =
                                    !obscure,
                              );
                            },

                            icon: Icon(
                              obscure
                                  ? Icons
                                      .visibility_off
                                  : Icons
                                      .visibility,

                              color:
                                  const Color(
                                0xFF8FAADC,
                              ),

                              size: 20,
                            ),
                          ),

                          border:
                              InputBorder.none,

                          contentPadding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // LOGIN BUTTON
                    SizedBox(
                      width:
                          double.infinity,

                      height: 56,

                      child:
                          ElevatedButton(
                        onPressed:
                            loading
                                ? null
                                : login,

                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              const Color(
                            0xFF2F5DA8,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),

                          elevation: 0,
                        ),

                        child: loading
                            ? const AppLoader(
                                size: 28,
                              )
                            : const Text(
                                "Login",

                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // GOOGLE LOGIN
                    OutlinedButton.icon(
                      onPressed:
                          loading
                              ? null
                              : googleLogin,

                      style:
                          OutlinedButton
                              .styleFrom(
                        minimumSize:
                            const Size(
                          double.infinity,
                          56,
                        ),

                        side: BorderSide(
                          color:
                              const Color(
                            0xFF2F5DA8,
                          ).withOpacity(0.5),
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                      ),

                      icon: const Icon(
                        Icons.g_mobiledata,
                        color:
                            Color(
                          0xFF8FAADC,
                        ),
                      ),

                      label: const Text(
                        "Continue with Google",

                        style: TextStyle(
                          color:
                              Color(
                            0xFF8FAADC,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // REGISTER
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                      children: [
                        const Text(
                          "No account?",

                          style: TextStyle(
                            color:
                                Color(
                              0xFF8FAADC,
                            ),
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (_) =>
                                    const RegisterScreen(),
                              ),
                            );
                          },

                          child:
                              const Text(
                            "Register",

                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                            ),
                          ),
                        ),
                      ],
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

  // =============================================================
  // TEXT FIELD
  // =============================================================

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type =
        TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(
          0xFF0C1F3F,
        ),

        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),

      child: TextField(
        controller: controller,

        keyboardType: type,

        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),

        decoration:
            InputDecoration(
          hintText: hint,

          hintStyle:
              const TextStyle(
            color:
                Color(0xFF8FAADC),
            fontSize: 15,
          ),

          prefixIcon:
              Icon(
            icon,
            color:
                const Color(
              0xFF8FAADC,
            ),
            size: 20,
          ),

          border:
              InputBorder.none,

          contentPadding:
              const EdgeInsets
                  .symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
