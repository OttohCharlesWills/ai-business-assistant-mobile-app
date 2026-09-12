import 'dart:convert';
import 'api_client.dart' as http;
import 'auth_service.dart';

class CashierExpenseService {
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

  // GET /cashier/expenses
  // Only returns expenses added_by the logged-in cashier.
  // Response shape: { success, expenses: { data: [...], current_page, ... } }
  static Future<Map<String, dynamic>> getExpenses() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/cashier/expenses"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // POST /cashier/expenses
  // shopId is required by the backend — pull it from the cashier's saved
  // user info (AuthService.getUserInfo()['shop_id']), don't ask them to pick one.
  static Future<Map<String, dynamic>> createExpense({
    required int shopId,
    required String title,
    required double amount,
    required String date, // format: YYYY-MM-DD
    String? description,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/cashier/expenses"),
        headers: await _headers(),
        body: jsonEncode({
          "shop_id": shopId,
          "title": title,
          "amount": amount,
          "date": date,
          "description": description,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // DELETE /cashier/expenses/{id}
  static Future<Map<String, dynamic>> deleteExpense(int id) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/cashier/expenses/$id"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}