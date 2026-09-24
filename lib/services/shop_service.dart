import 'dart:convert';
import 'api_client.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ShopService {
  static const String baseUrl =
      "https://bloommonie.store/api";

  // GET SHOPS (CACHE FIRST)
  static Future<List> getShops({bool refresh = false}) async {
  if (refresh) {
    return await refreshShops();
  }

  final prefs = await SharedPreferences.getInstance();

  final cachedData = prefs.getString('shops_cache');

  if (cachedData != null) {
    return jsonDecode(cachedData);
  }

  return await refreshShops();
}

  // REFRESH SHOPS FROM SERVER
  static Future<List> refreshShops() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/shops"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true) {
      await prefs.setString(
        'shops_cache',
        jsonEncode(data['shops']),
      );

      return data['shops'];
    }

    return [];
  }

  // CREATE SHOP
  // CREATE SHOP
static Future<Map<String, dynamic>> createShop({
  required String name,
  String? location,
}) async {
  final token = await AuthService.getToken();

  final response = await http.post(
    Uri.parse("$baseUrl/shops"),
    headers: {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    },
    body: {
      "name": name,
      "location": location ?? "",
    },
  );

  final result = jsonDecode(response.body);

  // PLAN RESTRICTION
  if (response.statusCode == 403) {
    return {
      "status": false,
      "restricted": true,
      "message": result["message"] ??
          "Your current plan does not allow you to create another shop.",
    };
  }

  // OTHER API ERROR
  if (response.statusCode < 200 || response.statusCode >= 300) {
    return {
      "status": false,
      "restricted": false,
      "message": result["message"] ??
          "Unable to create shop. Please try again.",
    };
  }

  // SUCCESS
  if (result['status'] == true) {
    await refreshShops();
  }

  return {
    ...result,
    "restricted": false,
  };
}

  // UPDATE SHOP
  static Future updateShop({
    required int id,
    required String name,
    String? location,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.put(
      Uri.parse("$baseUrl/shops/$id"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: {
        "name": name,
        "location": location ?? "",
      },
    );

    final result = jsonDecode(response.body);

    // UPDATE CACHE
    if (result['status'] == true) {
      await refreshShops();
    }

    return result;
  }

  // DELETE SHOP
  static Future deleteShop(int id) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/shops/$id"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final result = jsonDecode(response.body);

    // UPDATE CACHE
    if (result['status'] == true) {
      await refreshShops();
    }

    return result;
  }

  // CLEAR CACHE
  static Future clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('shops_cache');
  }
}