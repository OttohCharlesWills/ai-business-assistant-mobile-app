import 'package:flutter/material.dart';
import '../../../services/staff_service.dart';

class RegisterStaffScreen extends StatefulWidget {
  const RegisterStaffScreen({super.key});

  @override
  State<RegisterStaffScreen> createState() => _RegisterStaffScreenState();
}

class _RegisterStaffScreenState extends State<RegisterStaffScreen> {

  static const bgColor = Color(0xFF0C1F3F);
  static const cardColor = Color(0xFF0F2847);
  static const accentBlue = Color(0xFF2F5DA8);
  static const softBlue = Color(0xFF8FAADC);

  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  bool submitting = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  List shops = [];
  String selectedRole = 'cashier';
  int? selectedShopId;

  @override
  void initState() {
    super.initState();
    fetchShops();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> fetchShops() async {
    setState(() => loading = true);
    final data = await StaffService.getShopsForStaff();
    setState(() {
      shops = data;
      loading = false;
    });
  }

  Future<void> registerStaff() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedShopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a shop"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => submitting = true);

    final res = await StaffService.storeStaff(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
      passwordConfirmation: confirmPasswordController.text,
      role: selectedRole,
      shopId: selectedShopId!,
    );

    setState(() => submitting = false);

    if (!mounted) return;

    if (res['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Staff registered successfully 🎉"),
          backgroundColor: accentBlue,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? "Something went wrong"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Register Staff",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: accentBlue),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // HEADER CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: accentBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              color: softBlue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "New Staff Member",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Fill in the details to register a cashier or manager",
                                  style: TextStyle(
                                    color: softBlue,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // NAME
                    _buildLabel("Full Name"),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: nameController,
                      hint: "Enter full name",
                      icon: Icons.person_outline_rounded,
                      validator: (val) =>
                          val!.isEmpty ? "Name is required" : null,
                    ),

                    const SizedBox(height: 18),

                    // EMAIL
                    _buildLabel("Email Address"),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: emailController,
                      hint: "Enter email address",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) =>
                          val!.isEmpty ? "Email is required" : null,
                    ),

                    const SizedBox(height: 18),

                    // PASSWORD
                    _buildLabel("Password"),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: passwordController,
                      hint: "Enter password",
                      obscure: obscurePassword,
                      onToggle: () =>
                          setState(() => obscurePassword = !obscurePassword),
                      validator: (val) => val!.length < 6
                          ? "Minimum 6 characters"
                          : null,
                    ),

                    const SizedBox(height: 18),

                    // CONFIRM PASSWORD
                    _buildLabel("Confirm Password"),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: confirmPasswordController,
                      hint: "Confirm password",
                      obscure: obscureConfirm,
                      onToggle: () =>
                          setState(() => obscureConfirm = !obscureConfirm),
                      validator: (val) =>
                          val != passwordController.text
                              ? "Passwords do not match"
                              : null,
                    ),

                    const SizedBox(height: 18),

                    // ROLE
                    _buildLabel("Role"),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          dropdownColor: bgColor,
                          style: const TextStyle(color: Colors.white),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'cashier',
                              child: Row(
                                children: [
                                  Icon(Icons.point_of_sale_rounded,
                                      color: softBlue, size: 18),
                                  SizedBox(width: 10),
                                  Text("Cashier",
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'manager',
                              child: Row(
                                children: [
                                  Icon(Icons.manage_accounts_rounded,
                                      color: softBlue, size: 18),
                                  SizedBox(width: 10),
                                  Text("Manager",
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => selectedRole = val!),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // SHOP
                    _buildLabel("Assign Shop"),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedShopId,
                          dropdownColor: bgColor,
                          isExpanded: true,
                          hint: const Text(
                            "Select Shop",
                            style: TextStyle(color: softBlue, fontSize: 14),
                          ),
                          items: shops.map<DropdownMenuItem<int>>((shop) {
                            return DropdownMenuItem<int>(
                              value: shop['id'],
                              child: Row(
                                children: [
                                  const Icon(Icons.store_rounded,
                                      color: softBlue, size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    shop['name'],
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => selectedShopId = val),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: submitting ? null : registerStaff,
                        child: submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Register Staff",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: softBlue, fontSize: 14),
        prefixIcon: Icon(icon, color: softBlue, size: 20),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: softBlue, fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: softBlue, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: softBlue,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}