
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_client.dart' as http;
import 'auth_service.dart';
import 'api_exception.dart';
import '../helpers/error_helper.dart';

class CashierInvoiceService {
  static String get baseUrl => AuthService.baseUrl;

  // ============================================================
  // AUTH HEADERS
  // ============================================================

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // SHARED RESPONSE HANDLING
  // ============================================================

  /// Returns a consistent Map for all invoice requests.
  ///
  /// Successful and validation responses return the server's JSON.
  /// Network failures and unexpected responses return a friendly message.
  static Future<Map<String, dynamic>> _call(
    Future<dynamic> Function() request,
    String fallbackMessage,
  ) async {
    try {
      final res = await request();
      final int code = res.statusCode as int;

      // Authentication failure.
      if (code == 401) {
        throw ApiException(
          'Your session has expired. Please log in again.',
          401,
        );
      }

      // Server errors.
      if (code >= 500) {
        throw ApiException(
          'Server error. Please try again later.',
          code,
        );
      }

      // Decode the server response.
      final dynamic decoded;

      try {
        decoded = jsonDecode(res.body);
      } catch (_) {
        throw ApiException(
          'Unable to process the server response. Please try again.',
          code,
        );
      }

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw ApiException(
        'Unexpected response from server.',
        code,
      );
    } catch (e, stackTrace) {
      debugPrint('CashierInvoiceService error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (isNetworkError(e)) {
        return {
          'status': false,
          'message': kNoInternetMessage,
        };
      }

      if (e is ApiException) {
        return {
          'status': false,
          'message': e.message,
        };
      }

      return {
        'status': false,
        'message': fallbackMessage,
      };
    }
  }

  // ============================================================
  // GET /invoices/create
  // ============================================================

  static Future<Map<String, dynamic>> getCreateData() async {
    return _call(
      () async => http.get(
        Uri.parse('$baseUrl/invoices/create'),
        headers: await _headers(),
      ),
      'Could not load the invoice form. Please try again.',
    );
  }

  // ============================================================
  // POST /invoices
  // ============================================================

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
    return _call(
      () async => http.post(
        Uri.parse('$baseUrl/invoices'),
        headers: await _headers(),
        body: jsonEncode({
          'customer_id': customerId,
          'shop_id': shopId,
          'goods': goods,
          'total': total,
          'payment_type': paymentType,
          'amount_paid': amountPaid,
          'balance': balance,
          'discount': discount,
          'tax': tax,
        }),
      ),
      'Could not create the invoice. Please try again.',
    );
  }

  // ============================================================
  // GET /invoices
  // ============================================================

  static Future<Map<String, dynamic>> getInvoices() async {
    return _call(
      () async => http.get(
        Uri.parse('$baseUrl/invoices'),
        headers: await _headers(),
      ),
      'Could not load invoices. Please try again.',
    );
  }

  // ============================================================
  // GET /invoices/search?query=
  // ============================================================

  static Future<Map<String, dynamic>> searchInvoices(
    String query,
  ) async {
    final uri = Uri.parse('$baseUrl/invoices/search').replace(
      queryParameters: {'query': query},
    );

    return _call(
      () async => http.get(
        uri,
        headers: await _headers(),
      ),
      'Search failed. Please try again.',
    );
  }

  // ============================================================
  // GET /invoices/{id}
  // ============================================================

  static Future<Map<String, dynamic>> getInvoice(int id) async {
    return _call(
      () async => http.get(
        Uri.parse('$baseUrl/invoices/$id'),
        headers: await _headers(),
      ),
      'Could not load the invoice. Please try again.',
    );
  }

  // ============================================================
  // GET /invoices/{id}/preview
  // ============================================================

  static Future<Map<String, dynamic>> previewInvoice(int id) async {
    return _call(
      () async => http.get(
        Uri.parse('$baseUrl/invoices/$id/preview'),
        headers: await _headers(),
      ),
      'Could not load the invoice preview. Please try again.',
    );
  }

  // ============================================================
  // POST /invoices/{id}/payment
  // ============================================================

  static Future<Map<String, dynamic>> addPayment({
    required int invoiceId,
    required double amountPaid,
    required String paymentType,
  }) async {
    return _call(
      () async => http.post(
        Uri.parse('$baseUrl/invoices/$invoiceId/payment'),
        headers: await _headers(),
        body: jsonEncode({
          'amount_paid': amountPaid,
          'payment_type': paymentType,
        }),
      ),
      'Could not record the payment. Please try again.',
    );
  }

  // ============================================================
  // GET /invoices/receivables?query=
  // ============================================================

  static Future<Map<String, dynamic>> getReceivables({
    String? search,
  }) async {
    final uri = Uri.parse('$baseUrl/invoices/receivables').replace(
      queryParameters:
          (search != null && search.isNotEmpty)
              ? {'query': search}
              : null,
    );

    return _call(
      () async => http.get(
        uri,
        headers: await _headers(),
      ),
      'Could not load receivables. Please try again.',
    );
  }

  // ============================================================
  // POST /invoices/{id}/mark-paid
  // ============================================================

  static Future<Map<String, dynamic>> markPaid(
    int invoiceId,
  ) async {
    return _call(
      () async => http.post(
        Uri.parse('$baseUrl/invoices/$invoiceId/mark-paid'),
        headers: await _headers(),
      ),
      'Could not mark the invoice as paid. Please try again.',
    );
  }
}
