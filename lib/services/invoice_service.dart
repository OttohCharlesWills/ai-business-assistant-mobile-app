import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class InvoiceService {
  static const String baseUrl =
      "https://bloommonie.store/api";

  static const String invoiceCacheKey = "cached_invoices";
  static const String receivableCacheKey = "cached_receivables";
  static const String createDataCacheKey = "cached_invoice_create_data";

  /*
  |--------------------------------------------------------------------------
  | GET CUSTOMERS + PRODUCTS + SHOPS
  |--------------------------------------------------------------------------
  */

  static Future<Map<String, dynamic>?> getCreateData(
      {bool refresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!refresh) {
      final cache = prefs.getString(createDataCacheKey);

      if (cache != null) {
        return jsonDecode(cache);
      }
    }

    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/invoices/create"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (data["status"] == true) {
      await prefs.setString(createDataCacheKey, jsonEncode(data["data"]));
      return data["data"];
    }

    return null;
  }

  /*
  |--------------------------------------------------------------------------
  | CREATE INVOICE
  |--------------------------------------------------------------------------
  */

  static Future createInvoice({
    required int customerId,
    required int shopId,
    required List goods,
    required double total,
    required String paymentType,
    required double amountPaid,
    required double balance,
    double discount = 0,
    double tax = 0,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/invoices"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
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

    return jsonDecode(response.body);
  }

  /*
  |--------------------------------------------------------------------------
  | ALL INVOICES
  |--------------------------------------------------------------------------
  */

  static Future<Map<String, dynamic>?> getInvoices(
      {bool refresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!refresh) {
      final cache = prefs.getString(invoiceCacheKey);

      if (cache != null) {
        return jsonDecode(cache);
      }
    }

    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/invoices"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (data["status"] == true) {
      await prefs.setString(invoiceCacheKey, jsonEncode(data["data"]));
      return data["data"];
    }

    return null;
  }

  /*
  |--------------------------------------------------------------------------
  | SINGLE INVOICE
  |--------------------------------------------------------------------------
  */

  static Future<Map<String, dynamic>?> getInvoice(int id) async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/invoices/$id"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (data["status"] == true) {
      return data["data"];
    }

    return null;
  }

  /*
  |--------------------------------------------------------------------------
  | SEARCH INVOICE
  |--------------------------------------------------------------------------
  */

  static Future<Map<String, dynamic>?> searchInvoice(
      String query) async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/invoices/search?query=$query"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (data["status"] == true) {
      return data["data"];
    }

    return null;
  }

  /*
  |--------------------------------------------------------------------------
  | DELETE INVOICE
  |--------------------------------------------------------------------------
  */

  static Future deleteInvoice(int id) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/invoices/$id"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(response.body);
  }

  /*
  |--------------------------------------------------------------------------
  | UPDATE PAYMENT
  |--------------------------------------------------------------------------
  */

  static Future updatePayment({
    required int invoiceId,
    required double amountPaid,
    required String paymentType,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/invoices/$invoiceId/payment"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "amount_paid": amountPaid,
        "payment_type": paymentType,
      }),
    );

    return jsonDecode(response.body);
  }

  /*
  |--------------------------------------------------------------------------
  | MARK AS PAID
  |--------------------------------------------------------------------------
  */

  static Future markPaid(int id) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/invoices/$id/mark-paid"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(response.body);
  }

  /*
  |--------------------------------------------------------------------------
  | RECEIVABLES
  |--------------------------------------------------------------------------
  */

  static Future<Map<String, dynamic>?> getReceivables(
      {bool refresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!refresh) {
      final cache = prefs.getString(receivableCacheKey);

      if (cache != null) {
        return jsonDecode(cache);
      }
    }

    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/invoices/receivables"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (data["status"] == true) {
      await prefs.setString(receivableCacheKey, jsonEncode(data["data"]));
      return data["data"];
    }

    return null;
  }

  /*
  |--------------------------------------------------------------------------
  | PREVIEW
  |--------------------------------------------------------------------------
  */

  static Future<Map<String, dynamic>?> previewInvoice(int id) async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/invoices/$id/preview"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (data["status"] == true) {
      return data["data"];
    }

    return null;
  }

  /*
  |--------------------------------------------------------------------------
  | DOWNLOAD PDF
  |--------------------------------------------------------------------------
  */

  static String downloadInvoice(int id) {
    return "$baseUrl/invoices/$id/download";
  }

  /*
  |--------------------------------------------------------------------------
  | CLEAR CACHE
  |--------------------------------------------------------------------------
  */

  static Future clearCache() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(invoiceCacheKey);
    await prefs.remove(receivableCacheKey);
    await prefs.remove(createDataCacheKey);
  }
}