
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart' as http;
import 'auth_service.dart';
import 'api_exception.dart';
import '../helpers/error_helper.dart';

class CategoryService {
  static const String baseUrl = 'https://bloommonie.store/api';
  static const String _cacheKey = 'categories_cache';

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
      // Handle invalid or non-JSON responses below.
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

  // ============================================================
  // REFRESH CACHE AFTER CHANGES
  // ============================================================

  /// A successful create/update/delete must not be reported as failed
  /// just because refreshing the category cache fails.
  static Future<void> _refreshAfterChange() async {
    try {
      await refreshCategories();
    } catch (e) {
      debugPrint('Category cache refresh failed: $e');
      await clearCache();
    }
  }

  // ============================================================
  // GET CATEGORIES
  // ============================================================

  /// Returns cached categories first.
  /// If no cache exists, fetches categories from the server.
  static Future<List> getCategories({
    bool refresh = false,
  }) async {
    if (refresh) {
      return refreshCategories();
    }

    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKey);

    if (cachedData != null) {
      try {
        final dynamic decoded = jsonDecode(cachedData);

        if (decoded is List) {
          return decoded;
        }

        await prefs.remove(_cacheKey);
      } catch (_) {
        await prefs.remove(_cacheKey);
      }
    }

    return refreshCategories();
  }

  // ============================================================
  // REFRESH FROM SERVER
  // ============================================================

  static Future<List> refreshCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: await _headers(),
      );

      final data = _decode(response);

      if (data['status'] == true) {
        final dynamic categories = data['categories'];
        final List list = categories is List ? categories : [];

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString(
          _cacheKey,
          jsonEncode(list),
        );

        return list;
      }

      throw ApiException(
        data['message']?.toString() ??
            'Could not load categories. Please try again.',
        response.statusCode as int,
      );
    } catch (e) {
      debugPrint('CategoryService refresh error: $e');

      throw ApiException(
        _errorMessage(
          e is Exception ? e : Exception(e.toString()),
          'Could not load categories. Please try again.',
        ),
      );
    }
  }

  // ============================================================
  // CREATE CATEGORY
  // ============================================================

  static Future<Map<String, dynamic>> createCategory({
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: await _headers(),
        body: {
          'name': name,
        },
      );

      final result = _decode(response);

      if (result['status'] == true) {
        await _refreshAfterChange();
      }

      return result;
    } catch (e) {
      debugPrint('CategoryService create error: $e');

      return {
        'status': false,
        'message': _errorMessage(
          e is Exception ? e : Exception(e.toString()),
          'Could not create category. Please try again.',
        ),
      };
    }
  }

  // ============================================================
  // UPDATE CATEGORY
  // ============================================================

  static Future<Map<String, dynamic>> updateCategory({
    required int id,
    required String name,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/categories/$id'),
        headers: await _headers(),
        body: {
          'name': name,
        },
      );

      final result = _decode(response);

      if (result['status'] == true) {
        await _refreshAfterChange();
      }

      return result;
    } catch (e) {
      debugPrint('CategoryService update error: $e');

      return {
        'status': false,
        'message': _errorMessage(
          e is Exception ? e : Exception(e.toString()),
          'Could not update category. Please try again.',
        ),
      };
    }
  }

  // ============================================================
  // DELETE CATEGORY
  // ============================================================

  static Future<Map<String, dynamic>> deleteCategory(
    int id,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/categories/$id'),
        headers: await _headers(),
      );

      final result = _decode(response);

      if (result['status'] == true) {
        await _refreshAfterChange();
      }

      return result;
    } catch (e) {
      debugPrint('CategoryService delete error: $e');

      return {
        'status': false,
        'message': _errorMessage(
          e is Exception ? e : Exception(e.toString()),
          'Could not delete category. Please try again.',
        ),
      };
    }
  }

  // ============================================================
  // CLEAR CACHE
  // ============================================================

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
