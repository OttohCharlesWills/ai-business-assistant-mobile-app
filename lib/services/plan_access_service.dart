
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart' as http;
import 'auth_service.dart';

class PlanAccessService {
  static String get baseUrl => AuthService.baseUrl;

  static const String _cacheKey = 'plan_access_cache';

  // ============================================================
  // FETCH PLAN ACCESS
  // ============================================================

  static Future<Map<String, dynamic>> fetchPlanAccess({
    bool refresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Return cached data unless refresh was requested
    if (!refresh) {
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData != null) {
        try {
          return jsonDecode(cachedData);
        } catch (_) {
          // Invalid cache — continue to server
        }
      }
    }

    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      return {
        'status': false,
        'message': 'Authentication token not found.',
      };
    }

    final response = await http.get(
      Uri.parse('$baseUrl/plan-access'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    Map<String, dynamic> result;

    try {
      result = jsonDecode(response.body);
    } catch (_) {
      return {
        'status': false,
        'message': 'Invalid response from server.',
      };
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        result['status'] == true) {
      await prefs.setString(
        _cacheKey,
        jsonEncode(result),
      );

      return result;
    }

    return {
      'status': false,
      'message': result['message'] ??
          'Unable to retrieve plan access.',
      'statusCode': response.statusCode,
    };
  }

  // ============================================================
  // REFRESH PLAN ACCESS
  // ============================================================

  static Future<Map<String, dynamic>> refreshPlanAccess() async {
    return await fetchPlanAccess(refresh: true);
  }

  // ============================================================
  // GET CACHED PLAN ACCESS
  // ============================================================

  static Future<Map<String, dynamic>?> getCachedPlanAccess() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedData = prefs.getString(_cacheKey);

    if (cachedData == null) {
      return null;
    }

    try {
      return jsonDecode(cachedData);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // CHECK FEATURE
  // ============================================================

  static Future<bool> hasFeature(String feature) async {
    final data = await fetchPlanAccess();

    if (data['status'] != true) {
      return false;
    }

    final features = data['features'];

    if (features is! Map) {
      return false;
    }

    return features[feature] == true;
  }

  // ============================================================
  // GET PLAN NAME
  // ============================================================

  static Future<String?> getPlanName() async {
    final data = await fetchPlanAccess();

    if (data['status'] != true) {
      return null;
    }

    final plan = data['plan'];

    if (plan is! Map) {
      return null;
    }

    return plan['name']?.toString();
  }

  // ============================================================
  // GET FEATURE MESSAGE
  // ============================================================

  static Future<String> getFeatureMessage(
    String feature, {
    String? featureName,
  }) async {
    final data = await fetchPlanAccess();

    if (data['status'] != true) {
      return data['message'] ??
          'Unable to check your current plan.';
    }

    final features = data['features'];

    if (features is Map && features[feature] == true) {
      return '';
    }

    return 'Your current plan does not include '
        '${featureName ?? feature}.';
  }

  // ============================================================
  // CLEAR CACHE
  // ============================================================

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_cacheKey);
  }
}

