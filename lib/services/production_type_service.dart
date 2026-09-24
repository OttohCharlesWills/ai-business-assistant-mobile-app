
import 'dart:convert';

import 'api_client.dart' as http;
import 'auth_service.dart';
import 'plan_access_service.dart';

class ProductionTypeService {
  static String get baseUrl => AuthService.baseUrl;

  // ============================================================
  // AUTH HEADERS
  // ============================================================

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ============================================================
  // CHECK PRODUCTION ACCESS
  // Business plan only
  // ============================================================

  static Future<void> _checkProductionAccess() async {
    final allowed = await PlanAccessService.hasFeature(
      'production',
    );

    if (!allowed) {
      final message = await PlanAccessService.getFeatureMessage(
        'production',
        featureName: 'Production & Manufacturing',
      );

      throw Exception(
        message.isNotEmpty
            ? message
            : 'Please upgrade to the Business plan to access Production & Manufacturing.',
      );
    }
  }

  // ============================================================
  // GET PRODUCTION TYPES
  // GET /admin/production-types?page=
  // ============================================================

  static Future<Map<String, dynamic>> getProductionTypes({
    int? page,
  }) async {
    try {
      await _checkProductionAccess();

      final params = <String, String>{};

      if (page != null) {
        params['page'] = page.toString();
      }

      final uri = Uri.parse(
        "$baseUrl/admin/production-types",
      ).replace(
        queryParameters: params,
      );

      final res = await http.get(
        uri,
        headers: await _headers(),
      );

      final data = jsonDecode(res.body);

      return Map<String, dynamic>.from(data);
    } catch (e) {
      return {
        "status": false,
        "message": e
            .toString()
            .replaceFirst('Exception: ', ''),
      };
    }
  }

  // ============================================================
  // CREATE PRODUCTION TYPE
  // POST /admin/production-types
  // ============================================================

  static Future<Map<String, dynamic>> createProductionType({
    required String name,
    required String status,
    String? description,
  }) async {
    try {
      await _checkProductionAccess();

      final res = await http.post(
        Uri.parse(
          "$baseUrl/admin/production-types",
        ),
        headers: await _headers(),
        body: jsonEncode({
          "name": name,
          "status": status,
          "description": description,
        }),
      );

      final data = jsonDecode(res.body);

      return Map<String, dynamic>.from(data);
    } catch (e) {
      return {
        "status": false,
        "message": e
            .toString()
            .replaceFirst('Exception: ', ''),
      };
    }
  }

  // ============================================================
  // DELETE PRODUCTION TYPE
  // DELETE /admin/production-types/{id}
  // ============================================================

  static Future<Map<String, dynamic>> deleteProductionType(
    int id,
  ) async {
    try {
      await _checkProductionAccess();

      final res = await http.delete(
        Uri.parse(
          "$baseUrl/admin/production-types/$id",
        ),
        headers: await _headers(),
      );

      final data = jsonDecode(res.body);

      return Map<String, dynamic>.from(data);
    } catch (e) {
      return {
        "status": false,
        "message": e
            .toString()
            .replaceFirst('Exception: ', ''),
      };
    }
  }
}

