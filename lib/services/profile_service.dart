import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class ProfileService {
  static const String baseUrl =
      "https://bloommonie.store/api";

  // UPDATE PROFILE
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? password,
    String? passwordConfirmation,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/profile/update"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: {
        "name": name,
        "email": email,
        if (password != null && password.isNotEmpty)
          "password": password,
        if (password != null && password.isNotEmpty)
          "password_confirmation": passwordConfirmation ?? password,
      },
    );

    return jsonDecode(response.body);
  }
  
// GET PROFILE
static Future<Map<String, dynamic>> getProfile() async {
  final token = await AuthService.getToken();

  final response = await http.get(
    Uri.parse("$baseUrl/profile"),
    headers: {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  return jsonDecode(response.body);
}
}