import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/admin/dashboard_screen.dart';
import '../screens/manager/manager_dashboard_screen.dart';
import '../screens/cashier/cashier_dashboard_screen.dart';

class RoleRouter {

  // NAVIGATE BASED ON ROLE FROM API RESPONSE
  static void navigateFromResponse(
    BuildContext context,
    Map<String, dynamic> response,
  ) {
    final role = response['role'] ?? 'admin';
    _navigateToRole(context, role);
  }

  // NAVIGATE BASED ON SAVED ROLE (for splash screen auto-login)
  static Future<void> navigateFromSaved(BuildContext context) async {
    final role = await AuthService.getRole() ?? 'admin';
    if (!context.mounted) return;
    _navigateToRole(context, role);
  }

  // ROUTE TO CORRECT DASHBOARD
  static void _navigateToRole(BuildContext context, String role) {
    Widget screen;

    switch (role) {
      case 'manager':
        screen = const ManagerDashboardScreen();
        break;
      case 'cashier':
        screen = const CashierDashboardScreen();
        break;
      case 'admin':
      default:
        screen = const DashboardScreen();
        break;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }
}