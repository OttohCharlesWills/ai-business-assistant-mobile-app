
import 'dart:convert';

import 'api_client.dart' as http;
import 'auth_service.dart';
import 'plan_access_service.dart';

class ProductionReportService {
  static String get baseUrl => AuthService.baseUrl;

  // ------------------------------------------------------------
  // AUTH HEADERS
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // PRODUCTION ACCESS CHECK
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // GET PRODUCTION REPORT
  // GET /admin/reports/production
  // ------------------------------------------------------------

  static Future<Map<String, dynamic>> getProductionReport({
    String? startDate,
    String? endDate,
    dynamic shopId,
    String? search,
  }) async {
    try {
      // Business plan restriction
      await _checkProductionAccess();

      final params = <String, String>{};

      if (startDate != null) {
        params['start_date'] = startDate;
      }

      if (endDate != null) {
        params['end_date'] = endDate;
      }

      if (shopId != null) {
        params['shop_id'] = shopId.toString();
      }

      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      final uri = Uri.parse(
        "$baseUrl/admin/reports/production",
      ).replace(
        queryParameters: params,
      );

      final res = await http.get(
        uri,
        headers: await _headers(),
      );

      return jsonDecode(res.body);
    } catch (e) {
      return {
        "status": false,
        "message": e
            .toString()
            .replaceFirst('Exception: ', ''),
      };
    }
  }

  // ------------------------------------------------------------
  // DOWNLOAD PRODUCTION REPORT PDF
  // GET /admin/reports/production/pdf
  // ------------------------------------------------------------

  static Future<List<int>?> downloadProductionReportPdf({
    String? startDate,
    String? endDate,
    dynamic shopId,
  }) async {
    try {
      // Business plan restriction
      await _checkProductionAccess();

      final params = <String, String>{};

      if (startDate != null) {
        params['start_date'] = startDate;
      }

      if (endDate != null) {
        params['end_date'] = endDate;
      }

      if (shopId != null) {
        params['shop_id'] = shopId.toString();
      }

      final uri = Uri.parse(
        "$baseUrl/admin/reports/production/pdf",
      ).replace(
        queryParameters: params,
      );

      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found.',
        );
      }

      final res = await http.get(
        uri,
        headers: {
          "Accept": "application/pdf",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        return res.bodyBytes;
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
```

### What changed

The important addition is:

```dart
import 'plan_access_service.dart';
```

and:

```dart
static Future<void> _checkProductionAccess() async {
  final allowed = await PlanAccessService.hasFeature('production');

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