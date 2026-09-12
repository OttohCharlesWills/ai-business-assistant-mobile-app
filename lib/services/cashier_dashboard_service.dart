import 'dart:convert';
import 'api_client.dart' as http;
import 'auth_service.dart';

class CashierDashboardService {
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

  // GET /cashier/home
  // Categories with their products (for the POS category tabs)
  static Future<Map<String, dynamic>> getHome() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/cashier/home"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // GET /categories/{categoryId}/products
  static Future<Map<String, dynamic>> getProductsByCategory(int categoryId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/categories/$categoryId/products"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // GET /products/search/suggestions?query=
  // Returns either a single exact match ({success, id, name, price, ...})
  // or a list of suggestion products, depending on the backend match.
  static Future<dynamic> searchProductSuggestions(String query) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/products/search/suggestions?query=${Uri.encodeQueryComponent(query)}"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // GET /products/{id}/stock
  static Future<Map<String, dynamic>> getProductStock(int productId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/products/$productId/stock"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // POST /purchase-items
  // products: [{ product_id, quantity, discount_type, discount_value }, ...]
  static Future<Map<String, dynamic>> createSale({
    String? customerName,
    String? customerPhone,
    required List<Map<String, dynamic>> products,
    required String paymentMethod,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/purchase-items"),
        headers: await _headers(),
        body: jsonEncode({
          "customer_name": customerName,
          "customer_phone": customerPhone,
          "products": products,
          "payment_method": paymentMethod,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // GET /receipts/search?transaction_id=
  static Future<Map<String, dynamic>> searchReceipt(String transactionId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/receipts/search?transaction_id=${Uri.encodeQueryComponent(transactionId)}"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // GET /receipts/{id}
  static Future<Map<String, dynamic>> getReceipt(int id) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/receipts/$id"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // DELETE /purchase-items/{id}
  static Future<Map<String, dynamic>> deleteSale(int id) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/purchase-items/$id"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // GET /cashier/sales?search=&start_date=&end_date=&quick=
  // quick: 'today' | 'yesterday' | 'week' | 'month' (optional, overrides dates)
  static Future<Map<String, dynamic>> getCashierSales({
    String? search,
    String? startDate,
    String? endDate,
    String? quick,
  }) async {
    try {
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (startDate != null) params['start_date'] = startDate;
      if (endDate != null) params['end_date'] = endDate;
      if (quick != null) params['quick'] = quick;

      final uri = Uri.parse("$baseUrl/cashier/sales").replace(queryParameters: params);

      final res = await http.get(uri, headers: await _headers());
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}