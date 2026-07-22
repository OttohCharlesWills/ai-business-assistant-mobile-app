import 'package:flutter/material.dart';

import '../../../services/profile_service.dart';
import '../../../widgets/app_loader.dart';

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String email;

  const EditProfileScreen({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.name);
    emailController = TextEditingController(text: widget.email);
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => loading = true);

    try {
      final response = await ProfileService.updateProfile(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        passwordConfirmation:
            confirmPasswordController.text.trim(),
      );

      setState(() => loading = false);

      if (response['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Profile updated successfully."),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              response['message'] ?? "Something went wrong.",
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(e.toString()),
        ),
      );
    }
  }

  InputDecoration inputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF8FAADC),
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF8FAADC),
      ),
      filled: true,
      fillColor: const Color(0xFF0F2847),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF2F5DA8),
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0C1F3F),

          appBar: AppBar(
            backgroundColor: const Color(0xFF0C1F3F),
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(
              color: Colors.white,
            ),
            title: const Text(
              "Edit Profile",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          body: Form(
            key: _formKey,

            child: ListView(
              padding: const EdgeInsets.all(20),

              children: [ TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration(
                    "Full Name",
                    Icons.person_outline,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Name is required";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration(
                    "Email Address",
                    Icons.email_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Email is required";
                    }

                    if (!value.contains("@")) {
                      return "Enter a valid email";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration(
                    "New Password (Optional)",
                    Icons.lock_outline,
                  ),
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        value.length < 6) {
                      return "Password must be at least 6 characters";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration(
                    "Confirm Password",
                    Icons.lock_reset_outlined,
                  ),
                  validator: (value) {
                    if (passwordController.text.isNotEmpty &&
                        value != passwordController.text) {
                      return "Passwords do not match";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: updateProfile,
                    icon: const Icon(
                      Icons.save_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "UPDATE PROFILE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF2F5DA8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),

        if (loading)
          const FullScreenLoader(
            message: "Updating profile...",
          ),
      ],
    );
  }
}