import 'dart:convert';

import 'api_client.dart';
import 'auth_service.dart';

class PlanService {
  static String get baseUrl => AuthService.baseUrl;

  /// Get the current user's complete plan information.
  static Future<Map<String, dynamic>> getPlan() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    try {
      final response = await get(
        Uri.parse('$baseUrl/plan'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return Map<String, dynamic>.from(
          data['data'] ?? {},
        );
      }

      if (response.statusCode == 401) {
        throw Exception(
          data['message'] ??
              'Your session has expired. Please login again.',
        );
      }

      if (response.statusCode == 404) {
        throw Exception(
          data['message'] ??
              'Plan information could not be found.',
        );
      }

      throw Exception(
        data['message'] ??
            'Unable to load your subscription plan.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Get only the plan information.
  static Future<Map<String, dynamic>> getPlanDetails() async {
    final data = await getPlan();

    return Map<String, dynamic>.from(
      data['plan'] ?? {},
    );
  }

  /// Get plan limits.
  static Future<Map<String, dynamic>> getLimits() async {
    final data = await getPlan();

    return Map<String, dynamic>.from(
      data['limits'] ?? {},
    );
  }

  /// Get current usage.
  static Future<Map<String, dynamic>> getUsage() async {
    final data = await getPlan();

    return Map<String, dynamic>.from(
      data['usage'] ?? {},
    );
  }

  /// Get feature access.
  static Future<Map<String, dynamic>> getFeatures() async {
    final data = await getPlan();

    return Map<String, dynamic>.from(
      data['features'] ?? {},
    );
  }

  /// Check whether a particular feature is available.
  static Future<bool> hasFeature(String feature) async {
    final features = await getFeatures();

    return features[feature] == true;
  }

  /// Check whether the current subscription is active.
  static Future<bool> isActive() async {
    final plan = await getPlanDetails();

    return plan['status'] == 'Active';
  }

  /// Get remaining subscription days.
  static Future<int> getDaysRemaining() async {
    final plan = await getPlanDetails();

    final value = plan['days_remaining'];

    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}