import 'dart:convert';
import 'api_client.dart' as http;
import 'auth_service.dart';

class RoleService {

  static const String baseUrl =
      "https://bloommonie.store/api";

  // GET ALL STAFF + SHOPS
  static Future<Map<String, dynamic>> getUsers() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/admin/users"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true) {
      return {
        'users': data['users'] ?? [],
        'shops': data['shops'] ?? [],
      };
    }

    return {'users': [], 'shops': []};
  }

  // UPDATE ROLE
  static Future<Map<String, dynamic>> updateRole({
    required int userId,
    required String role,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.patch(
      Uri.parse("$baseUrl/admin/users/$userId/role"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: {"role": role},
    );

    return jsonDecode(response.body);
  }

  // DELETE USER
  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/admin/users/$userId"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(response.body);
  }

  // UPDATE SHOP
  static Future<Map<String, dynamic>> updateShop({
    required int userId,
    required int shopId,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.patch(
      Uri.parse("$baseUrl/admin/users/$userId/shop"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: {"shop_id": shopId.toString()},
    );

    return jsonDecode(response.body);
  }
}