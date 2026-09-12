import 'dart:convert';
import 'api_client.dart' as http;
import 'auth_service.dart';

class StaffService {

  static const String baseUrl =
      "https://bloommonie.store/api";

  // GET SHOPS FOR DROPDOWN
  static Future<List> getShopsForStaff() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/admin/register-form"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true) {
      return data['shops'];
    }

    return [];
  }

  // REGISTER STAFF
  static Future<Map<String, dynamic>> storeStaff({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
    required int shopId,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/admin/store-staff"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: {
        "name": name,
        "email": email,
        "password": password,
        "password_confirmation": passwordConfirmation,
        "role": role,
        "shop_id": shopId.toString(),
      },
    );

    return jsonDecode(response.body);
  }
}