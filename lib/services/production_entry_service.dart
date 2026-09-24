
import 'dart:convert';

import 'api_client.dart' as http;
import 'auth_service.dart';
import 'plan_access_service.dart';

class ProductionEntryService {
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
  // GET /admin/production-entries?page=
  // ============================================================

  static Future<Map<String, dynamic>> getProductions({
    int? page,
  }) async {
    try {
      await _checkProductionAccess();

      final params = <String, String>{};

      if (page != null) {
        params['page'] = page.toString();
      }

      final uri = Uri.parse(
        "$baseUrl/admin/production-entries",
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
  // GET SINGLE PRODUCTION
  // GET /admin/production-entries/{production}
  // ============================================================

  static Future<Map<String, dynamic>> getProduction(
    int productionId,
  ) async {
    try {
      await _checkProductionAccess();

      final res = await http.get(
        Uri.parse(
          "$baseUrl/admin/production-entries/$productionId",
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
  // GET FILL DATA
  // GET /admin/production-entries/{production}/fill
  // ============================================================

  static Future<Map<String, dynamic>> getFillData(
    int productionId,
  ) async {
    try {
      await _checkProductionAccess();

      final res = await http.get(
        Uri.parse(
          "$baseUrl/admin/production-entries/$productionId/fill",
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
  // GET EDIT DATA
  // GET /admin/production-entries/{production}/edit
  // ============================================================

  static Future<Map<String, dynamic>> getEditData(
    int productionId,
  ) async {
    try {
      await _checkProductionAccess();

      final res = await http.get(
        Uri.parse(
          "$baseUrl/admin/production-entries/$productionId/edit",
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
  // STORE PRODUCTION ENTRY
  // POST /admin/production-entries/{productionId}
  //
  // entryType:
  // input | output | loss
  // ============================================================

  static Future<Map<String, dynamic>> storeEntry({
    required int productionId,
    required String entryType,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      await _checkProductionAccess();

      final res = await http.post(
        Uri.parse(
          "$baseUrl/admin/production-entries/$productionId",
        ),
        headers: await _headers(),
        body: jsonEncode({
          "entry_type": entryType,
          "items": items,
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
  // UPDATE PRODUCTION ENTRY
  // PUT /admin/production-entries/{productionId}
  // ============================================================

  static Future<Map<String, dynamic>> updateEntry({
    required int productionId,
    required String entryType,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      await _checkProductionAccess();

      final res = await http.put(
        Uri.parse(
          "$baseUrl/admin/production-entries/$productionId",
        ),
        headers: await _headers(),
        body: jsonEncode({
          "entry_type": entryType,
          "items": items,
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
  // DELETE PRODUCTION ENTRY
  // DELETE /admin/production-entries/{id}
  // ============================================================

  static Future<Map<String, dynamic>> deleteEntry(
    int entryId,
  ) async {
    try {
      await _checkProductionAccess();

      final res = await http.delete(
        Uri.parse(
          "$baseUrl/admin/production-entries/$entryId",
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

