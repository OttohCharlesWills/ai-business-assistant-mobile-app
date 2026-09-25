import 'dart:convert';

import 'api_client.dart';
import 'plan_access_service.dart';

class StockTransferService {
  // ==========================================================================
  // Check Stock Transfer Access
  // ==========================================================================
  //
  // Always refresh plan access from the server.
  // This prevents an old cached plan from incorrectly allowing
  // Stock Transfer after the user's subscription has changed.
  //

  Future<void> _checkAccess() async {
    final data = await PlanAccessService.refreshPlanAccess();

    if (data['status'] != true) {
      throw Exception(
        data['message'] ??
            'Unable to verify your current subscription plan.',
      );
    }

    final features = data['features'];

    if (features is! Map || features['stock_transfer'] != true) {
      throw Exception(
        'Your current plan does not include Stock Transfer. '
        'Please upgrade your plan to access this feature.',
      );
    }
  }

  // ==========================================================================
  // Common Headers
  // ==========================================================================

  Map<String, String> _headers(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  Map<String, String> _jsonHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  // ==========================================================================
  // Parse JSON Response
  // ==========================================================================

  dynamic _decodeResponse(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      throw Exception(
        'The server returned an invalid response.',
      );
    }
  }

  // ==========================================================================
  // Get Shops
  // ==========================================================================

  Future<List<dynamic>> getShops({
    required String baseUrl,
    required String token,
  }) async {
    try {
      await _checkAccess();

      final response = await get(
        Uri.parse('$baseUrl/stock-transfers/shops'),
        headers: _headers(token),
      );

      final data = _decodeResponse(response.body);

      if (response.statusCode == 200 &&
          data is Map &&
          data['success'] == true) {
        final shops = data['data'];

        if (shops is List) {
          return shops;
        }

        return [];
      }

      if (response.statusCode == 403) {
        throw Exception(
          data is Map
              ? data['message'] ??
                  'Your current plan does not include Stock Transfer. '
                      'Please upgrade your plan.'
              : 'Your current plan does not include Stock Transfer. '
                  'Please upgrade your plan.',
        );
      }

      throw Exception(
        data is Map
            ? data['message'] ?? 'Failed to load shops.'
            : 'Failed to load shops.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ==========================================================================
  // Get Products
  // ==========================================================================

  Future<List<dynamic>> getProducts({
    required String baseUrl,
    required String token,
  }) async {
    try {
      await _checkAccess();

      final response = await get(
        Uri.parse('$baseUrl/stock-transfers/products'),
        headers: _headers(token),
      );

      final data = _decodeResponse(response.body);

      if (response.statusCode == 200 &&
          data is Map &&
          data['success'] == true) {
        final products = data['data'];

        if (products is List) {
          return products;
        }

        return [];
      }

      if (response.statusCode == 403) {
        throw Exception(
          data is Map
              ? data['message'] ??
                  'Your current plan does not include Stock Transfer. '
                      'Please upgrade your plan.'
              : 'Your current plan does not include Stock Transfer. '
                  'Please upgrade your plan.',
        );
      }

      throw Exception(
        data is Map
            ? data['message'] ?? 'Failed to load products.'
            : 'Failed to load products.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ==========================================================================
  // Get Categories
  // ==========================================================================

  Future<List<dynamic>> getCategories({
    required String baseUrl,
    required String token,
  }) async {
    try {
      await _checkAccess();

      final response = await get(
        Uri.parse('$baseUrl/stock-transfers/categories'),
        headers: _headers(token),
      );

      final data = _decodeResponse(response.body);

      if (response.statusCode == 200 &&
          data is Map &&
          data['success'] == true) {
        final categories = data['data'];

        if (categories is List) {
          return categories;
        }

        return [];
      }

      if (response.statusCode == 403) {
        throw Exception(
          data is Map
              ? data['message'] ??
                  'Your current plan does not include Stock Transfer. '
                      'Please upgrade your plan.'
              : 'Your current plan does not include Stock Transfer. '
                  'Please upgrade your plan.',
        );
      }

      throw Exception(
        data is Map
            ? data['message'] ?? 'Failed to load categories.'
            : 'Failed to load categories.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ==========================================================================
  // Get Products By Shop
  // ==========================================================================
  //
  // This is the method used by StockTransferScreen when a source shop
  // is selected.
  //
  // The backend now returns:
  //
  // id
  // name
  // barcode
  // category_id
  // cost_price
  // price
  // stock_quantity
  // stock_limit
  //
  // The Flutter screen can then search the loaded products locally
  // by name OR barcode.
  //

  Future<List<dynamic>> getProductsByShop({
    required String baseUrl,
    required String token,
    required int shopId,
  }) async {
    try {
      await _checkAccess();

      final response = await get(
        Uri.parse('$baseUrl/shops/$shopId/products'),
        headers: _headers(token),
      );

      final data = _decodeResponse(response.body);

      // -----------------------------------------------------------------------
      // Successful response
      // -----------------------------------------------------------------------

      if (response.statusCode == 200 &&
          data is Map &&
          data['success'] == true) {
        final products = data['data'];

        if (products is List) {
          return products;
        }

        return [];
      }

      // -----------------------------------------------------------------------
      // Subscription restriction
      // -----------------------------------------------------------------------

      if (response.statusCode == 403) {
        throw Exception(
          data is Map
              ? data['message'] ??
                  'Your current plan does not include Stock Transfer. '
                      'Please upgrade your plan.'
              : 'Your current plan does not include Stock Transfer. '
                  'Please upgrade your plan.',
        );
      }

      // -----------------------------------------------------------------------
      // Shop not found / unauthorized
      // -----------------------------------------------------------------------

      if (response.statusCode == 404) {
        throw Exception(
          data is Map
              ? data['message'] ??
                  'The selected shop could not be found.'
              : 'The selected shop could not be found.',
        );
      }

      // -----------------------------------------------------------------------
      // Other errors
      // -----------------------------------------------------------------------

      throw Exception(
        data is Map
            ? data['message'] ??
                'Failed to load products for this shop.'
            : 'Failed to load products for this shop.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ==========================================================================
  // Transfer Stock
  // ==========================================================================

  Future<Map<String, dynamic>> transferStock({
    required String baseUrl,
    required String token,
    required int productId,
    required int shopId,
    required int toShopId,
    required int quantity,
    required double costPrice,
    required double sellingPrice,
  }) async {
    try {
      // -----------------------------------------------------------------------
      // Check plan before sending the transfer request
      // -----------------------------------------------------------------------

      await _checkAccess();

      final response = await post(
        Uri.parse('$baseUrl/stock-transfers'),
        headers: _jsonHeaders(token),
        body: jsonEncode({
          'product_id': productId,
          'shop_id': shopId,
          'to_shop_id': toShopId,
          'quantity': quantity,
          'cost_price': costPrice,
          'selling_price': sellingPrice,
        }),
      );

      final data = _decodeResponse(response.body);

      // -----------------------------------------------------------------------
      // Successful transfer
      // -----------------------------------------------------------------------

      if (response.statusCode == 201 &&
          data is Map &&
          data['success'] == true) {
        return Map<String, dynamic>.from(data);
      }

      // -----------------------------------------------------------------------
      // Feature restriction from Laravel
      // -----------------------------------------------------------------------

      if (response.statusCode == 403) {
        throw Exception(
          data is Map
              ? data['message'] ??
                  'Your current plan does not include Stock Transfer. '
                      'Please upgrade your plan.'
              : 'Your current plan does not include Stock Transfer. '
                  'Please upgrade your plan.',
        );
      }

      // -----------------------------------------------------------------------
      // Validation errors
      // -----------------------------------------------------------------------

      if (response.statusCode == 422) {
        if (data is Map && data['errors'] is Map) {
          final errors = Map<String, dynamic>.from(
            data['errors'],
          );

          final messages = errors.values
              .expand(
                (value) => value is List ? value : [value],
              )
              .map(
                (value) => value.toString(),
              )
              .toList();

          throw Exception(
            messages.isNotEmpty
                ? messages.join('\n')
                : 'Invalid stock transfer information.',
          );
        }

        throw Exception(
          data is Map
              ? data['message'] ??
                  'Invalid stock transfer information.'
              : 'Invalid stock transfer information.',
        );
      }

      // -----------------------------------------------------------------------
      // Not found
      // -----------------------------------------------------------------------

      if (response.statusCode == 404) {
        throw Exception(
          data is Map
              ? data['message'] ??
                  'The selected shop or product could not be found.'
              : 'The selected shop or product could not be found.',
        );
      }

      // -----------------------------------------------------------------------
      // Other errors
      // -----------------------------------------------------------------------

      throw Exception(
        data is Map
            ? data['message'] ?? 'Stock transfer failed.'
            : 'Stock transfer failed.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}