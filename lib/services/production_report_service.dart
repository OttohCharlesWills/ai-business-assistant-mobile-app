import 'dart:convert';
import 'api_client.dart' as http;
import 'auth_service.dart';

class ProductionReportService {
  static String get baseUrl => AuthService.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // GET /admin/reports/production?start_date=&end_date=&shop_id=&search=
  static Future<Map<String, dynamic>> getProductionReport({
    String? startDate,
    String? endDate,
    dynamic shopId,
    String? search,
  }) async {
    try {
      final params = <String, String>{};
      if (startDate != null) params['start_date'] = startDate;
      if (endDate != null) params['end_date'] = endDate;
      if (shopId != null) params['shop_id'] = shopId.toString();
      if (search != null && search.isNotEmpty) params['search'] = search;

      final uri = Uri.parse("$baseUrl/admin/reports/production").replace(queryParameters: params);
      final res = await http.get(uri, headers: await _headers());
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // GET /admin/reports/production/pdf?start_date=&end_date=&shop_id=
  // NOTE: backend's PDF query has no owner_id filter (see controller comment) —
  // it may return productions outside this owner's scope. Flagging in case
  // that surfaces unexpected data once tested.
  static Future<List<int>?> downloadProductionReportPdf({
    String? startDate,
    String? endDate,
    dynamic shopId,
  }) async {
    try {
      final params = <String, String>{};
      if (startDate != null) params['start_date'] = startDate;
      if (endDate != null) params['end_date'] = endDate;
      if (shopId != null) params['shop_id'] = shopId.toString();

      final uri = Uri.parse("$baseUrl/admin/reports/production/pdf").replace(queryParameters: params);
      final token = await AuthService.getToken();

      final res = await http.get(
        uri,
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) return res.bodyBytes;
      return null;
    } catch (e) {
      return null;
    }
  }
}