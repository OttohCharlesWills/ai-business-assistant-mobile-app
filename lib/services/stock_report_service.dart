import 'dart:convert';
import 'api_client.dart' as http;
import 'auth_service.dart';

class StockReportService {
  static String get baseUrl => AuthService.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // GET /admin/reports/stock?shop_id=&search=&page=
  // 'products' in the response is a Laravel paginator:
  // {data: [...], current_page, last_page, ...}
  static Future<Map<String, dynamic>> getStockReport({
    dynamic shopId,
    String? search,
    int? page,
  }) async {
    try {
      final params = <String, String>{};
      if (shopId != null) params['shop_id'] = shopId.toString();
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (page != null) params['page'] = page.toString();

      final uri = Uri.parse("$baseUrl/admin/reports/stock").replace(queryParameters: params);
      final res = await http.get(uri, headers: await _headers());
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // GET /admin/reports/stock/pdf?shop_id=&search=
  static Future<List<int>?> downloadStockReportPdf({
    dynamic shopId,
    String? search,
  }) async {
    try {
      final params = <String, String>{};
      if (shopId != null) params['shop_id'] = shopId.toString();
      if (search != null && search.isNotEmpty) params['search'] = search;

      final uri = Uri.parse("$baseUrl/admin/reports/stock/pdf").replace(queryParameters: params);
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