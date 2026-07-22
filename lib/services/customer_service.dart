import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class CustomerService {
  static const String baseUrl =
      "https://bloommonie.store/api";

  static const String _cacheKey = "cached_customers";

  /*
  |--------------------------------------------------------------------------
  | GET ALL CUSTOMERS
  |--------------------------------------------------------------------------
  */
  static Future<List> getCustomers({bool refresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!refresh) {
      final cache = prefs.getString(_cacheKey);
      if (cache != null) {
        return jsonDecode(cache);
      }
    }

    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/customers"),
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

    return [];
  }

  /*
  |--------------------------------------------------------------------------
  | GET SINGLE CUSTOMER
  |--------------------------------------------------------------------------
  */
  static Future<Map<String, dynamic>?> getCustomer(int id) async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/customers/$id"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true) {
      return data['data'];
    }

    return null;
  }

  /*
  |--------------------------------------------------------------------------
  | CREATE CUSTOMER
  |--------------------------------------------------------------------------
  */
  static Future<Map<String, dynamic>> createCustomer({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? company,
    String? notes,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/customers"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "email": email,
        "phone": phone,
        "address": address,
        "company": company,
        "notes": notes,
      }),
    );

    final data = jsonDecode(response.body);

    // clear cache so next fetch is fresh
    if (data['status'] == true) await clearCache();

    return data;
  }

  /*
  |--------------------------------------------------------------------------
  | UPDATE CUSTOMER
  |--------------------------------------------------------------------------
  */
  static Future<Map<String, dynamic>> updateCustomer({
    required int id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? company,
    String? notes,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.put(
      Uri.parse("$baseUrl/customers/$id"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "email": email,
        "phone": phone,
        "address": address,
        "company": company,
        "notes": notes,
      }),
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true) await clearCache();

    return data;
  }

  /*
  |--------------------------------------------------------------------------
  | DELETE CUSTOMER
  |--------------------------------------------------------------------------
  */
  static Future<Map<String, dynamic>> deleteCustomer(int id) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/customers/$id"),
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
  | SEARCH CUSTOMERS
  |--------------------------------------------------------------------------
  */
  static Future<List> searchCustomers(String query) async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/customers/search?query=$query"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true) {
      return data['data'];
    }

    return [];
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