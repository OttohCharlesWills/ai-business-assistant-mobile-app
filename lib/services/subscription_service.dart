import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class SubscriptionException implements Exception {
  final String message;

  /// false when retrying can't help (e.g. a cashier opening the renew screen)
  final bool retryable;

  SubscriptionException(this.message, {this.retryable = true});

  @override
  String toString() => message;
}

class SubscriptionPlan {
  final String id; // basic | lite | business
  final String name;
  final int monthlyPrice;
  final int yearlyPrice;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      monthlyPrice: (json['monthly_price'] as num).toInt(),
      yearlyPrice: (json['yearly_price'] as num).toInt(),
    );
  }

  int priceFor(String billing) =>
      billing == 'yearly' ? yearlyPrice : monthlyPrice;

  /// How much a yearly plan saves versus paying monthly for 12 months.
  int get yearlySavings => (monthlyPrice * 12) - yearlyPrice;
}

class PaymentSession {
  final String authorizationUrl;
  final String reference;
  final String callbackUrl;

  const PaymentSession({
    required this.authorizationUrl,
    required this.reference,
    required this.callbackUrl,
  });
}

class SubscriptionResult {
  final bool success;
  final String message;

  const SubscriptionResult({required this.success, required this.message});
}

class SubscriptionService {
  static const _timeout = Duration(seconds: 30);

  /// None of the subscription endpoints need a login token: an expired
  /// account often has no valid session, and that's exactly who needs to pay.
  static Map<String, String> _headers() => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      return body is Map<String, dynamic> ? body : {};
    } catch (_) {
      return {};
    }
  }

  static String _errorMessage(Map<String, dynamic> body, [int? statusCode]) {
    if (statusCode == 429) {
      return 'Too many attempts. Please wait a minute and try again.';
    }

    final msg = body['message'] ?? body['error'];
    if (msg is String && msg.isNotEmpty) return msg;

    final code = statusCode != null ? ' (error $statusCode)' : '';
    return 'Something went wrong$code. Please try again.';
  }

  /// Prints the raw response so you can see exactly what the server sent.
  static void _debugResponse(http.Response res) {
    final body = res.body.length > 400 ? res.body.substring(0, 400) : res.body;
    debugPrint('SubscriptionService ${res.request?.method} '
        '${res.request?.url} -> ${res.statusCode}\n$body');
  }

  /// Turns a low-level failure into a message that says what actually
  /// happened, and prints the real error to the console for debugging.
  static SubscriptionException _networkError(Object e, String fallback) {
    debugPrint('SubscriptionService error: ${e.runtimeType}: $e');

    if (e is TimeoutException) {
      return SubscriptionException(
          'The server took too long to respond. Please try again.');
    }
    if (e is SocketException || e is http.ClientException) {
      return SubscriptionException(
          'Could not reach the server. Check your connection and try again.');
    }
    return SubscriptionException(fallback);
  }

  /// GET /subscription/plans
  static Future<List<SubscriptionPlan>> fetchPlans() async {
    try {
      final res = await http
          .get(Uri.parse('${AuthService.baseUrl}/subscription/plans'),
              headers: _headers())
          .timeout(_timeout);

      _debugResponse(res);
      final body = _decode(res);
      if (res.statusCode != 200 || body['status'] != true) {
        throw SubscriptionException(
          _errorMessage(body, res.statusCode),
          retryable: res.statusCode != 403 && res.statusCode != 401,
        );
      }

      final list = body['data']['plans'] as List;
      return list
          .map((p) => SubscriptionPlan.fromJson(p as Map<String, dynamic>))
          .toList();
    } on SubscriptionException {
      rethrow;
    } catch (e) {
      throw _networkError(e, 'Could not read the plans from the server.');
    }
  }

  /// POST /subscription/initialize
  static Future<PaymentSession> initializePayment({
    required String email,
    required String plan,
    required String billing,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${AuthService.baseUrl}/subscription/initialize'),
            headers: _headers(),
            body: jsonEncode({'email': email, 'plan': plan, 'billing': billing}),
          )
          .timeout(_timeout);

      _debugResponse(res);
      final body = _decode(res);
      if (res.statusCode != 200 || body['status'] != true) {
        throw SubscriptionException(_errorMessage(body, res.statusCode));
      }

      final data = body['data'] as Map<String, dynamic>;
      return PaymentSession(
        authorizationUrl: data['authorization_url'] as String,
        reference: data['reference'] as String,
        callbackUrl: data['callback_url'] as String,
      );
    } on SubscriptionException {
      rethrow;
    } catch (e) {
      throw _networkError(e, 'Could not start payment. Please try again.');
    }
  }

  /// GET /subscription/verify/{reference}
  static Future<SubscriptionResult> verifyPayment(String reference) async {
    try {
      final res = await http
          .get(Uri.parse('${AuthService.baseUrl}/subscription/verify/$reference'),
              headers: _headers())
          .timeout(_timeout);

      _debugResponse(res);
      final body = _decode(res);

      // 200 = activated, 422 = paid-but-not-confirmed / failed; both carry a message
      if (res.statusCode == 200 || res.statusCode == 422) {
        return SubscriptionResult(
          success: body['status'] == true,
          message: _errorMessage(body, res.statusCode),
        );
      }

      throw SubscriptionException(_errorMessage(body, res.statusCode));
    } on SubscriptionException {
      rethrow;
    } catch (e) {
      debugPrint('SubscriptionService verify error: ${e.runtimeType}: $e');
      throw SubscriptionException(
          'Could not confirm your payment. If you were charged, your plan will activate shortly.');
    }
  }
}