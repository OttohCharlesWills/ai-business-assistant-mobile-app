import 'dart:convert';

import 'api_client.dart';
import 'plan_access_service.dart';

class StockTransferService {
  /*
  |--------------------------------------------------------------------------
  | Check Stock Transfer Access
  |--------------------------------------------------------------------------
  |
  | Always refresh the plan access from the server.
  | This prevents an old cached plan from incorrectly allowing
  | Stock Transfer after the user's subscription has changed.
  |
  */

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

  /*
  |--------------------------------------------------------------------------
  | Get Shops
  |--------------------------------------------------------------------------
  */

  Future<List<dynamic>> getShops({
    required String baseUrl,
    required String token,
  }) async {
    try {
      await _checkAccess();

      final response = await get(
        Uri.parse('$baseUrl/stock-transfers/shops'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      }

      if (response.statusCode == 403) {
        throw Exception(
          data['message'] ??
              'Your current plan does not include Stock Transfer. '
                  'Please upgrade your plan.',
        );
      }

      throw Exception(
        data['message'] ?? 'Failed to load shops.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Get Products
  |--------------------------------------------------------------------------
  */

  Future<List<dynamic>> getProducts({
    required String baseUrl,
    required String token,
  }) async {
    try {
      await _checkAccess();

      final response = await get(
        Uri.parse('$baseUrl/stock-transfers/products'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      }

      if (response.statusCode == 403) {
        throw Exception(
          data['message'] ??
              'Your current plan does not include Stock Transfer. '
                  'Please upgrade your plan.',
        );
      }

      throw Exception(
        data['message'] ?? 'Failed to load products.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Get Categories
  |--------------------------------------------------------------------------
  */

  Future<List<dynamic>> getCategories({
    required String baseUrl,
    required String token,
  }) async {
    try {
      await _checkAccess();

      final response = await get(
        Uri.parse('$baseUrl/stock-transfers/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      }

      if (response.statusCode == 403) {
        throw Exception(
          data['message'] ??
              'Your current plan does not include Stock Transfer. '
                  'Please upgrade your plan.',
        );
      }

      throw Exception(
        data['message'] ?? 'Failed to load categories.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Get Products By Shop
  |--------------------------------------------------------------------------
  */

  Future<List<dynamic>> getProductsByShop({
    required String baseUrl,
    required String token,
    required int shopId,
  }) async {
    try {
      await _checkAccess();

      final response = await get(
        Uri.parse('$baseUrl/shops/$shopId/products'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? [];
      }

      if (response.statusCode == 403) {
        throw Exception(
          data['message'] ??
              'Your current plan does not include Stock Transfer. '
                  'Please upgrade your plan.',
        );
      }

      throw Exception(
        data['message'] ??
            'Failed to load products for this shop.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Transfer Stock
  |--------------------------------------------------------------------------
  */

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
      /*
      |--------------------------------------------------------------------------
      | Check plan BEFORE sending the transfer request
      |--------------------------------------------------------------------------
      */

      await _checkAccess();

      final response = await post(
        Uri.parse('$baseUrl/stock-transfers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'product_id': productId,
          'shop_id': shopId,
          'to_shop_id': toShopId,
          'quantity': quantity,
          'cost_price': costPrice,
          'selling_price': sellingPrice,
        }),
      );

      final data = jsonDecode(response.body);

      /*
      |--------------------------------------------------------------------------
      | Successful transfer
      |--------------------------------------------------------------------------
      */

      if (response.statusCode == 201 && data['success'] == true) {
        return data;
      }

      /*
      |--------------------------------------------------------------------------
      | Feature restriction from Laravel
      |--------------------------------------------------------------------------
      */

      if (response.statusCode == 403) {
        throw Exception(
          data['message'] ??
              'Your current plan does not include Stock Transfer. '
                  'Please upgrade your plan.',
        );
      }

      /*
      |--------------------------------------------------------------------------
      | Validation errors
      |--------------------------------------------------------------------------
      */

      if (response.statusCode == 422) {
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;

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
          data['message'] ??
              'Invalid stock transfer information.',
        );
      }

      /*
      |--------------------------------------------------------------------------
      | Other errors
      |--------------------------------------------------------------------------
      */

      throw Exception(
        data['message'] ?? 'Stock transfer failed.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

