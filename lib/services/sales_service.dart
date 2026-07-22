import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class SalesService {

  static const String baseUrl =
      "https://bloommonie.store/api";

  // GET SALES WITH FILTERS
  static Future<Map<String, dynamic>> getSales({
    String? date,
    String? search,
    String? shopId,
  }) async {
    final token = await AuthService.getToken();

    final queryParams = {
      'date': date ?? DateTime.now().toIso8601String().split('T')[0],
      if (search != null && search.isNotEmpty) 'search': search,
      if (shopId != null && shopId.isNotEmpty) 'shop': shopId,
    };

    final uri = Uri.parse("$baseUrl/admin/filter-sales")
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true) {
      return {
        'sales': data['sales'] ?? [],
        'shops': [],
      };
    }

    return {'sales': [], 'shops': []};
  }

  // GET SALES PAGE DATA (date + shops dropdown)
  static Future<Map<String, dynamic>> getSalesPage({String? date}) async {
    final token = await AuthService.getToken();

    final uri = Uri.parse("$baseUrl/admin/sales-page").replace(
      queryParameters: {
        'date': date ?? DateTime.now().toIso8601String().split('T')[0],
      },
    );

    final response = await http.get(
      uri,
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true) {
      return {
        'sales': data['sales'] ?? [],
        'shops': data['shops'] ?? [],
        'date': data['date'],
      };
    }

    return {'sales': [], 'shops': [], 'date': date};
  }

  // DELETE SALE
  static Future<Map<String, dynamic>> deleteSale(int id) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/admin/sales/$id"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(response.body);
  }
}