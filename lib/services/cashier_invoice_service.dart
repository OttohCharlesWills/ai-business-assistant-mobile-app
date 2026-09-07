import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CashierInvoiceService {
  static String get baseUrl => AuthService.baseUrl;

  // Build auth headers with the saved token
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // GET /invoices/create
  // Returns { customers, shops, products } needed to build the invoice form
  static Future<Map<String, dynamic>> getCreateData() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/invoices/create"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // POST /invoices
  // goods: [{ product_id, quantity, total_price }, ...]
  // paymentType: 'full' | 'part'
  static Future<Map<String, dynamic>> createInvoice({
    required int customerId,
    required int shopId,
    required List<Map<String, dynamic>> goods,
    required double total,
    required String paymentType,
    double? amountPaid,
    double? balance,
    double? discount,
    double? tax,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/invoices"),
        headers: await _headers(),
        body: jsonEncode({
          "customer_id": customerId,
          "shop_id": shopId,
          "goods": goods,
          "total": total,
          "payment_type": paymentType,
          "amount_paid": amountPaid,
          "balance": balance,
          "discount": discount,
          "tax": tax,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // GET /invoices
  // Returns { all_invoices, owing_invoices, total_invoices, total_owing }
  // NOT scoped per cashier — every role sees every invoice (same as customers).
  static Future<Map<String, dynamic>> getInvoices() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/invoices"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // GET /invoices/search?query=
  // Searches by customer name or phone
  static Future<Map<String, dynamic>> searchInvoices(String query) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/invoices/search?query=${Uri.encodeQueryComponent(query)}"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // GET /invoices/{id}
  static Future<Map<String, dynamic>> getInvoice(int id) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/invoices/$id"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // GET /invoices/{id}/preview
  static Future<Map<String, dynamic>> previewInvoice(int id) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/invoices/$id/preview"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // POST /invoices/{id}/payment
  static Future<Map<String, dynamic>> addPayment({
    required int invoiceId,
    required double amountPaid,
    required String paymentType,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/invoices/$invoiceId/payment"),
        headers: await _headers(),
        body: jsonEncode({
          "amount_paid": amountPaid,
          "payment_type": paymentType,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // GET /invoices/receivables?query=
  // NOTE: this is the generic, UNPAGINATED endpoint — returns
  // {status, data: {customers: [...], total_receivable}}.
  // No per-customer goods breakdown (that only exists on the unrouted
  // receivablesforcash() method). See screen comments for details.
  static Future<Map<String, dynamic>> getReceivables({String? search}) async {
    try {
      final uri = Uri.parse("$baseUrl/invoices/receivables").replace(
        queryParameters: (search != null && search.isNotEmpty) ? {"query": search} : null,
      );
      final res = await http.get(uri, headers: await _headers());
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  // POST /invoices/{id}/mark-paid
  static Future<Map<String, dynamic>> markPaid(int invoiceId) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/invoices/$invoiceId/mark-paid"),
        headers: await _headers(),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }
}