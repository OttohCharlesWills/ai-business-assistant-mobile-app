import 'dart:convert';
import 'api_client.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class CategoryService {
  static const String baseUrl =
      "https://bloommonie.store/api";

  static Future<List> getCategories({bool refresh = false}) async {
  if (refresh) {
    return await refreshCategories();
  }

  final prefs = await SharedPreferences.getInstance();

  final cachedData = prefs.getString('categories_cache');

  if (cachedData != null) {
    return jsonDecode(cachedData);
  }

  return await refreshCategories();
}

  // REFRESH FROM SERVER
  static Future<List> refreshCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/categories"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true) {
      await prefs.setString(
        'categories_cache',
        jsonEncode(data['categories']),
      );

      return data['categories'];
    }

    return [];
  }

  // CREATE CATEGORY
  static Future createCategory({
    required String name,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/categories"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: {
        "name": name,
      },
    );

    final result = jsonDecode(response.body);

    // UPDATE CACHE
    if (result['status'] == true) {
      await refreshCategories();
    }

    return result;
  }

  // UPDATE CATEGORY
  static Future updateCategory({
    required int id,
    required String name,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.put(
      Uri.parse("$baseUrl/categories/$id"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: {
        "name": name,
      },
    );

    final result = jsonDecode(response.body);

    // UPDATE CACHE
    if (result['status'] == true) {
      await refreshCategories();
    }

    return result;
  }

  // DELETE CATEGORY
  static Future deleteCategory(int id) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/categories/$id"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final result = jsonDecode(response.body);

    // UPDATE CACHE
    if (result['status'] == true) {
      await refreshCategories();
    }

    return result;
  }

  // CLEAR CACHE
  static Future clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('categories_cache');
  }
}