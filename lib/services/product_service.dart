
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_client.dart' as http;
import 'auth_service.dart';
import 'api_exception.dart';
import '../helpers/error_helper.dart';

class ProductService {
  static const String baseUrl = 'https://bloommonie.store/api';

  // ============================================================
  // HEADERS
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
  // RESPONSE DECODING
  // ============================================================

  static Map<String, dynamic> _decode(dynamic response) {
    final int code = response.statusCode as int;

    if (code == 401) {
      throw ApiException(
        'Your session has expired. Please log in again.',
        401,
      );
    }

    if (code >= 500) {
      throw ApiException(
        'Server error. Please try again later.',
        code,
      );
    }

    try {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Handle invalid JSON below.
    }

    throw ApiException(
      'Unexpected response from server.',
      code,
    );
  }

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  static String _errorMessage(
    Object error,
    String fallbackMessage,
  ) {
    if (isNetworkError(error)) {
      return kNoInternetMessage;
    }

    if (error is ApiException) {
      return error.message;
    }

    return fallbackMessage;
  }

  static Future<T> _handleErrors<T>(
    Future<T> Function() request,
    String fallbackMessage,
  ) async {
    try {
      return await request();
    } catch (e) {
      debugPrint('ProductService error: $e');

      throw ApiException(
        _errorMessage(
          e is Exception ? e : Exception(e.toString()),
          fallbackMessage,
        ),
        e is ApiException ? e.statusCode : null,
      );
    }
  }

  // ============================================================
  // SUCCESS RESPONSE VALIDATION
  // ============================================================

  static Map<String, dynamic> _decodeOrThrow(
    dynamic response,
    String fallbackMessage,
  ) {
    final data = _decode(response);

    if (data['status'] == true) {
      return data;
    }

    throw ApiException(
      data['message']?.toString() ?? fallbackMessage,
      response.statusCode as int,
    );
  }

  // ============================================================
  // EXTRACT LIST
  // ============================================================

  static List _extractList(dynamic raw) {
    if (raw is List) {
      return raw;
    }

    if (raw is Map && raw['data'] is List) {
      return raw['data'] as List;
    }

    return [];
  }

  // ============================================================
  // GET PRODUCTS
  // ============================================================

  static Future<List> getProducts() {
    return _handleErrors(() async {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: await _headers(),
      );

      final data = _decodeOrThrow(
        response,
        'Could not load products. Please try again.',
      );

      return _extractList(data['data']);
    }, 'Could not load products. Please try again.');
  }

  // ============================================================
  // CREATE PRODUCT
  // ============================================================

  static Future<Map<String, dynamic>> createProduct({
    required int categoryId,
    required int shopId,
    required String name,
    required String barcode,
    required double price,
    required double costPrice,
    required int stockQuantity,
    required int stockLimit,
    String? stockUnit,
    int? unitSize,
  }) {
    return _handleErrors(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: await _headers(),
        body: {
          'category_id': categoryId.toString(),
          'shop_id': shopId.toString(),
          'name': name,
          'barcode': barcode,
          'price': price.toString(),
          'cost_price': costPrice.toString(),
          'stock_quantity': stockQuantity.toString(),
          'stock_limit': stockLimit.toString(),
          'stock_unit': stockUnit ?? '',
          'unit_size': unitSize?.toString() ?? '',
        },
      );

      return _decode(response);
    }, 'Could not create product. Please try again.');
  }

  // ============================================================
  // UPDATE PRODUCT
  // ============================================================

  static Future<Map<String, dynamic>> updateProduct({
    required int id,
    required int categoryId,
    required int shopId,
    required String name,
    required String barcode,
    required double price,
    required double costPrice,
    required double stockQuantity,
    required double stockLimit,
    String? stockUnit,
    double? unitSize,
  }) {
    return _handleErrors(() async {
      final response = await http.put(
        Uri.parse('$baseUrl/products/$id'),
        headers: await _headers(),
        body: {
          'category_id': categoryId.toString(),
          'shop_id': shopId.toString(),
          'name': name,
          'barcode': barcode,
          'price': price.toString(),
          'cost_price': costPrice.toString(),
          'stock_quantity': stockQuantity.toString(),
          'stock_limit': stockLimit.toString(),
          'stock_unit': stockUnit ?? '',
          'unit_size': unitSize?.toString() ?? '',
        },
      );

      return _decode(response);
    }, 'Could not update product. Please try again.');
  }

  // ============================================================
  // DELETE PRODUCT
  // ============================================================

  static Future<Map<String, dynamic>> deleteProduct(int id) {
    return _handleErrors(() async {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: await _headers(),
      );

      return _decode(response);
    }, 'Could not delete product. Please try again.');
  }

  // ============================================================
  // SELL PRODUCT
  // ============================================================

  static Future<Map<String, dynamic>> sellProduct({
    required int productId,
    required int quantity,
    required String paymentMethod,
  }) {
    return _handleErrors(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/products/$productId/sell'),
        headers: await _headers(),
        body: {
          'quantity': quantity.toString(),
          'payment_method': paymentMethod,
        },
      );

      return _decode(response);
    }, 'Could not complete the sale. Please try again.');
  }

  // ============================================================
  // SEARCH SUGGESTIONS
  // ============================================================

  static Future<List> searchSuggestions(String query) {
    return _handleErrors(() async {
      final uri = Uri.parse(
        '$baseUrl/products/search/suggestions',
      ).replace(
        queryParameters: {'query': query},
      );

      final response = await http.get(
        uri,
        headers: await _headers(),
      );

      final data = _decodeOrThrow(
        response,
        'Could not load suggestions. Please try again.',
      );

      return _extractList(data['data']);
    }, 'Could not load suggestions. Please try again.');
  }

  // ============================================================
  // GET STOCK
  // ============================================================

  static Future<int> getStock(int id) {
    return _handleErrors(() async {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$id/stock'),
        headers: await _headers(),
      );

      final data = _decode(response);
      final stock = data['stock'];

      if (stock is int) {
        return stock;
      }

      return int.tryParse(stock?.toString() ?? '') ?? 0;
    }, 'Could not load product stock. Please try again.');
  }
}