import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class DashboardService {

  static const String baseUrl =
      "https://bloommonie.store/api";

  static const String cacheKey = "dashboard_data";

  // GET DASHBOARD
  static Future<Map<String, dynamic>?> getDashboard() async {

    final prefs = await SharedPreferences.getInstance();

    // STEP 1: Try cache first
    final cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {

      // Refresh in background
      refreshDashboard();

      final decoded = jsonDecode(cachedData);

      if (decoded['status'] == true) {
        return decoded['data'];
      }
    }

    // STEP 2: No cache → fetch from API
    return await refreshDashboard();
  }

  // REFRESH FROM INTERNET
  static Future<Map<String, dynamic>?> refreshDashboard() async {

    try {

      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/admin/dashboard"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true) {

        // Save entire response
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString(
          cacheKey,
          response.body,
        );

        return data['data'];
      }

    } catch (e) {

      print("Dashboard refresh error: $e");

    }

    return null;
  }

  // CLEAR CACHE
  static Future<void> clearDashboardCache() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(cacheKey);

  }
}