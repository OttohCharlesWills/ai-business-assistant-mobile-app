import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ProductionService {
  static String get baseUrl => AuthService.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // GET /admin/production?search=&shop_id=&page=
  // Response: { status, data: { productions: {paginator}, shops: [...] } }
  static Future<Map<String, dynamic>> getProductions({
    String? search,
    dynamic shopId,
    int? page,
  }) async {
    try {
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (shopId != null) params['shop_id'] = shopId.toString();
      if (page != null) params['page'] = page.toString();

      final uri = Uri.parse("$baseUrl/admin/production").replace(queryParameters: params);
      final res = await http.get(uri, headers: await _headers());
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // GET /admin/production/create
  // Response: { status, data: { production_types: [...], shops: [...] } }
  static Future<Map<String, dynamic>> getCreateData() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/admin/production/create"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // POST /admin/production
  static Future<Map<String, dynamic>> createProduction({
    required int shopId,
    required int productionTypeId,
    required String title,
    String? description,
    String? startDate, // YYYY-MM-DD
    String? endDate,   // YYYY-MM-DD
    String status = 'planned',
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/admin/production"),
        headers: await _headers(),
        body: jsonEncode({
          "shop_id": shopId,
          "production_type_id": productionTypeId,
          "title": title,
          "description": description,
          "start_date": startDate,
          "end_date": endDate,
          "status": status,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // PATCH /admin/production/{id}/status
  static Future<Map<String, dynamic>> updateStatus({
    required int productionId,
    required String status, // planned | in_progress | completed | cancelled
  }) async {
    try {
      final res = await http.patch(
        Uri.parse("$baseUrl/admin/production/$productionId/status"),
        headers: await _headers(),
        body: jsonEncode({"status": status}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }
}