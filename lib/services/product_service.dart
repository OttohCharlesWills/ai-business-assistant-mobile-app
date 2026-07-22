import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';


class ProductService {
  static const String baseUrl =
      "https://bloommonie.store/api";

  // GET PRODUCTS (you'll need backend index later if missing)
  static Future<List> getProducts() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/products"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true) {
      return data['data'] ?? [];
    }

    return [];
  }

  // CREATE PRODUCT
  static Future<Map<String, dynamic>> createProduct({
    required int categoryId,
    required int shopId,
    required String name,
    required String barcode,
    required double price,
    required double costPrice,
    required int stockQuantity,
    required int stockLimit,
    String? stockUnit,
    int? unitSize,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/products"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: {
        "category_id": categoryId.toString(),
        "shop_id": shopId.toString(),
        "name": name,
        "barcode": barcode,
        "price": price.toString(),
        "cost_price": costPrice.toString(),
        "stock_quantity": stockQuantity.toString(),
        "stock_limit": stockLimit.toString(),
        "stock_unit": stockUnit ?? "",
        "unit_size": unitSize?.toString() ?? "",
      },
    );

    return jsonDecode(response.body);
  }

  // UPDATE PRODUCT
  static Future<Map<String, dynamic>> updateProduct({
    required int id,
    required int categoryId,
    required int shopId,
    required String name,
    required double price,
    required double costPrice,
    required int stockQuantity,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.put(
      Uri.parse("$baseUrl/products/$id"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: {
        "category_id": categoryId.toString(),
        "shop_id": shopId.toString(),
        "name": name,
        "price": price.toString(),
        "cost_price": costPrice.toString(),
        "stock_quantity": stockQuantity.toString(),
      },
    );

    return jsonDecode(response.body);
  }

  // DELETE PRODUCT
  static Future<Map<String, dynamic>> deleteProduct(int id) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/products/$id"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(response.body);
  }

  // SELL PRODUCT
  static Future<Map<String, dynamic>> sellProduct({
    required int productId,
    required int quantity,
    required String paymentMethod,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/products/$productId/sell"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: {
        "quantity": quantity.toString(),
        "payment_method": paymentMethod,
      },
    );

    return jsonDecode(response.body);
  }

  // SEARCH SUGGESTIONS
  static Future<List> searchSuggestions(String query) async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/products/search/suggestions?query=$query"),
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

  // GET STOCK
  static Future<int> getStock(int id) async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/products/$id/stock"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    return data['stock'] ?? 0;
  }
}