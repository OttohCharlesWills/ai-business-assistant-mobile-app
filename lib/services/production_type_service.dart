import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ProductionTypeService {
  static String get baseUrl => AuthService.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // GET /admin/production-types?page=
  // Response: { status, data: { production_types: {paginator} } }
  static Future<Map<String, dynamic>> getProductionTypes({int? page}) async {
    try {
      final params = <String, String>{};
      if (page != null) params['page'] = page.toString();

      final uri = Uri.parse("$baseUrl/admin/production-types").replace(queryParameters: params);
      final res = await http.get(uri, headers: await _headers());
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // POST /admin/production-types
  // NOTE: 'name' is validated unique globally on the backend (not per
  // owner) — a duplicate name from any business will get rejected here.
  static Future<Map<String, dynamic>> createProductionType({
    required String name,
    required String status, // active | inactive
    String? description,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/admin/production-types"),
        headers: await _headers(),
        body: jsonEncode({
          "name": name,
          "status": status,
          "description": description,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // DELETE /admin/production-types/{id}
  static Future<Map<String, dynamic>> deleteProductionType(int id) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/admin/production-types/$id"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }
}