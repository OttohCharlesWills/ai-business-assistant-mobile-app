import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1F3F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1F3F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Stock X",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF2F5DA8).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.manage_accounts_rounded,
                size: 40,
                color: Color(0xFF8FAADC),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Manager Dashboard",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your management tools will appear here",
              style: TextStyle(
                color: Color(0xFF8FAADC),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2847),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  _InfoRow(icon: Icons.info_outline_rounded, text: "You are logged in as a Manager"),
                  SizedBox(height: 12),
                  _InfoRow(icon: Icons.bar_chart_rounded, text: "You can view sales reports"),
                  SizedBox(height: 12),
                  _InfoRow(icon: Icons.inventory_2_rounded, text: "You can manage products"),
                  SizedBox(height: 12),
                  _InfoRow(icon: Icons.people_rounded, text: "You can manage cashiers"),
                  SizedBox(height: 12),
                  _InfoRow(icon: Icons.lock_rounded, text: "Some admin features are restricted"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8FAADC), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}