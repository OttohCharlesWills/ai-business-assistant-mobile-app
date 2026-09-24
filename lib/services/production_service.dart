
import 'dart:convert';

import 'api_client.dart' as http;
import 'auth_service.dart';
import 'plan_access_service.dart';

class ProductionService {
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
  // GET PRODUCTIONS
  // GET /admin/production?search=&shop_id=&page=
  // ============================================================

  static Future<Map<String, dynamic>> getProductions({
    String? search,
    dynamic shopId,
    int? page,
  }) async {
    try {
      await _checkProductionAccess();

      final params = <String, String>{};

      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      if (shopId != null) {
        params['shop_id'] = shopId.toString();
      }

      if (page != null) {
        params['page'] = page.toString();
      }

      final uri = Uri.parse(
        "$baseUrl/admin/production",
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
  // GET CREATE DATA
  // GET /admin/production/create
  // ============================================================

  static Future<Map<String, dynamic>> getCreateData() async {
    try {
      await _checkProductionAccess();

      final res = await http.get(
        Uri.parse(
          "$baseUrl/admin/production/create",
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

  // ============================================================
  // CREATE PRODUCTION
  // POST /admin/production
  // ============================================================

  static Future<Map<String, dynamic>> createProduction({
    required int shopId,
    required int productionTypeId,
    required String title,
    String? description,
    String? startDate,
    String? endDate,
    String status = 'planned',
  }) async {
    try {
      await _checkProductionAccess();

      final res = await http.post(
        Uri.parse(
          "$baseUrl/admin/production",
        ),
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
  // UPDATE PRODUCTION STATUS
  // PATCH /admin/production/{id}/status
  // ============================================================

  static Future<Map<String, dynamic>> updateStatus({
    required int productionId,
    required String status,
  }) async {
    try {
      await _checkProductionAccess();

      final res = await http.patch(
        Uri.parse(
          "$baseUrl/admin/production/$productionId/status",
        ),
        headers: await _headers(),
        body: jsonEncode({
          "status": status,
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
}

