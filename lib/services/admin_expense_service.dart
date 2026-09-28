import 'dart:convert';
import 'api_client.dart' as http;
import 'auth_service.dart';

class AdminExpenseService {
  static String get baseUrl => AuthService.baseUrl;

  // ============================================================
  // HEADERS
  // ============================================================

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ============================================================
  // GET EXPENSES
  // GET /api/admin/expenses
  // ============================================================

  static Future<Map<String, dynamic>> getExpenses({
    int page = 1,
  }) async {
    try {
      final headers = await _headers();

      final response = await http.get(
        Uri.parse('$baseUrl/admin/expenses?page=$page'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      throw Exception(
        data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Failed to load expenses',
      );
    } catch (e) {
      throw Exception('Failed to load expenses: $e');
    }
  }

  // ============================================================
  // CREATE EXPENSE
  // POST /api/admin/expenses
  // ============================================================

  static Future<Map<String, dynamic>> createExpense({
    required int shopId,
    required String title,
    required double amount,
    required String date,
    String? description,
  }) async {
    try {
      final headers = await _headers();

      final body = {
        "shop_id": shopId,
        "title": title,
        "amount": amount,
        "date": date,
        "description": description ?? "",
      };

      final response = await http.post(
        Uri.parse('$baseUrl/admin/expenses'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      throw Exception(
        data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Failed to create expense',
      );
    } catch (e) {
      throw Exception('Failed to create expense: $e');
    }
  }

  // ============================================================
  // DELETE EXPENSE
  // DELETE /api/admin/expenses/{id}
  // ============================================================

  static Future<Map<String, dynamic>> deleteExpense(
    int id,
  ) async {
    try {
      final headers = await _headers();

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/expenses/$id'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      throw Exception(
        data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Failed to delete expense',
      );
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  // ============================================================
  // GET SHOPS
  //
  // Used by Create Expense page because shop_id is required.
  // GET /api/shops
  // ============================================================

  static Future<List<dynamic>> getShops() async {
    try {
      final headers = await _headers();

      final response = await http.get(
        Uri.parse('$baseUrl/shops'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data is List) {
          return data;
        }

        if (data is Map && data['shops'] is List) {
          return data['shops'];
        }

        if (data is Map &&
            data['data'] is Map &&
            data['data']['data'] is List) {
          return data['data']['data'];
        }

        if (data is Map && data['data'] is List) {
          return data['data'];
        }

        return [];
      }

      throw Exception(
        data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Failed to load shops',
      );
    } catch (e) {
      throw Exception('Failed to load shops: $e');
    }
  }
}