import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CashierCustomerService {
  static String get baseUrl => AuthService.baseUrl;

  // Build auth headers with the saved token
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // GET /customers
  // Full customer list (shared across all roles/shops, not scoped)
  static Future<Map<String, dynamic>> getCustomers() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/customers"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // GET /customers/search?query=
  static Future<Map<String, dynamic>> searchCustomers(String query) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/customers/search?query=${Uri.encodeQueryComponent(query)}"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // GET /customers/{id}
  static Future<Map<String, dynamic>> getCustomer(int id) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/customers/$id"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // POST /customers
  static Future<Map<String, dynamic>> createCustomer({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? company,
    String? notes,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/customers"),
        headers: await _headers(),
        body: jsonEncode({
          "name": name,
          "email": email,
          "phone": phone,
          "address": address,
          "company": company,
          "notes": notes,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // PUT /customers/{id}
  static Future<Map<String, dynamic>> updateCustomer(
    int id, {
    String? name,
    String? email,
    String? phone,
    String? address,
    String? company,
    String? notes,
  }) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/customers/$id"),
        headers: await _headers(),
        body: jsonEncode({
          "name": name,
          "email": email,
          "phone": phone,
          "address": address,
          "company": company,
          "notes": notes,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // DELETE /customers/{id}
  static Future<Map<String, dynamic>> deleteCustomer(int id) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/customers/$id"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }
}