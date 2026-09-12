import 'dart:convert';
import 'api_client.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class NotificationService {
  static const String baseUrl =
      "https://bloommonie.store/api";

  static const String _cacheKey = "cached_notifications";

  /*
  |--------------------------------------------------------------------------
  | GET ALL NOTIFICATIONS
  |--------------------------------------------------------------------------
  */
  static Future<Map<String, dynamic>?> getNotifications({bool refresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!refresh) {
      final cache = prefs.getString(_cacheKey);
      if (cache != null) {
        return jsonDecode(cache);
      }
    }

    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/notifications"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true) {
      await prefs.setString(_cacheKey, jsonEncode(data['data']));
      return data['data'];
    }

    return null;
  }

  /*
  |--------------------------------------------------------------------------
  | MARK SINGLE AS READ
  |--------------------------------------------------------------------------
  */
  static Future<Map<String, dynamic>> markAsRead(String id) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/notifications/$id/read"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);
    if (data['status'] == true) await clearCache();
    return data;
  }

  /*
  |--------------------------------------------------------------------------
  | MARK ALL AS READ
  |--------------------------------------------------------------------------
  */
  static Future<Map<String, dynamic>> markAllAsRead() async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/notifications/read-all"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);
    if (data['status'] == true) await clearCache();
    return data;
  }

  /*
  |--------------------------------------------------------------------------
  | DELETE SINGLE NOTIFICATION
  |--------------------------------------------------------------------------
  */
  static Future<Map<String, dynamic>> deleteNotification(String id) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/notifications/$id"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);
    if (data['status'] == true) await clearCache();
    return data;
  }

  /*
  |--------------------------------------------------------------------------
  | DELETE ALL NOTIFICATIONS
  |--------------------------------------------------------------------------
  */
  static Future<Map<String, dynamic>> deleteAll() async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/notifications"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);
    if (data['status'] == true) await clearCache();
    return data;
  }

  /*
  |--------------------------------------------------------------------------
  | CLEAR CACHE
  |--------------------------------------------------------------------------
  */
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}