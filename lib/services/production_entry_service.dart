import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ProductionEntryService {
  static String get baseUrl => AuthService.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // GET /admin/production-entries?page=
  // Response: { status, data: { productions: {paginator} } }
  static Future<Map<String, dynamic>> getProductions({int? page}) async {
    try {
      final params = <String, String>{};
      if (page != null) params['page'] = page.toString();

      final uri = Uri.parse("$baseUrl/admin/production-entries").replace(queryParameters: params);
      final res = await http.get(uri, headers: await _headers());
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // GET /admin/production-entries/{production}
  // Response: { status, data: {production with entries loaded} }
  static Future<Map<String, dynamic>> getProduction(int productionId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/admin/production-entries/$productionId"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // GET /admin/production-entries/{production}/fill
  // Response: { status, data: { production, products: [...], units: [...] } }
  static Future<Map<String, dynamic>> getFillData(int productionId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/admin/production-entries/$productionId/fill"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // GET /admin/production-entries/{production}/edit
  // Same response shape as getFillData() — separate call to mirror the
  // backend's separate fill/edit routes.
  static Future<Map<String, dynamic>> getEditData(int productionId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/admin/production-entries/$productionId/edit"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // POST /admin/production-entries/{productionId}
  // entryType: input | output | loss
  // items: [{ item_id, quantity, price, unit, ... }, ...]
  // Appends to any existing entry of the same type (backend behavior).
  static Future<Map<String, dynamic>> storeEntry({
    required int productionId,
    required String entryType,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/admin/production-entries/$productionId"),
        headers: await _headers(),
        body: jsonEncode({
          "entry_type": entryType,
          "items": items,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // PUT /admin/production-entries/{productionId}
  // Replaces the entry of this type entirely (reverses old stock, applies new).
  static Future<Map<String, dynamic>> updateEntry({
    required int productionId,
    required String entryType,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/admin/production-entries/$productionId"),
        headers: await _headers(),
        body: jsonEncode({
          "entry_type": entryType,
          "items": items,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // DELETE /admin/production-entries/{id}
  static Future<Map<String, dynamic>> deleteEntry(int entryId) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/admin/production-entries/$entryId"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }
}