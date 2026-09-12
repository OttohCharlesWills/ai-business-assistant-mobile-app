import 'dart:convert';
import 'api_client.dart' as http;
import 'auth_service.dart';

class ProfitReportService {
  static String get baseUrl => AuthService.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // GET /admin/reports/profit-loss?start_date=&end_date=&shop_id=
  static Future<Map<String, dynamic>> getProfitLoss({
    String? startDate,
    String? endDate,
    dynamic shopId,
  }) async {
    try {
      final params = <String, String>{};
      if (startDate != null) params['start_date'] = startDate;
      if (endDate != null) params['end_date'] = endDate;
      if (shopId != null) params['shop_id'] = shopId.toString();

      final uri = Uri.parse("$baseUrl/admin/reports/profit-loss").replace(queryParameters: params);
      final res = await http.get(uri, headers: await _headers());
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // GET /admin/reports/profit-loss/goods-pdf?start_date=&end_date=&shop_id=
  // Returns raw PDF bytes of the "goods that made profit" report.
  static Future<List<int>?> downloadGoodsProfitPdf({
    String? startDate,
    String? endDate,
    dynamic shopId,
  }) async {
    try {
      final params = <String, String>{};
      if (startDate != null) params['start_date'] = startDate;
      if (endDate != null) params['end_date'] = endDate;
      if (shopId != null) params['shop_id'] = shopId.toString();

      final uri = Uri.parse("$baseUrl/admin/reports/profit-loss/goods-pdf").replace(queryParameters: params);
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