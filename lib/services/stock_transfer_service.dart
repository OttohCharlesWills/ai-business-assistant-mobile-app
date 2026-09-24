import 'dart:convert';

import 'api_client.dart';
import 'plan_access_service.dart';

class StockTransferService {
  /*
  |--------------------------------------------------------------------------
  | Check Stock Transfer Access
  |--------------------------------------------------------------------------
  */

  Future<void> _checkAccess() async {
    final allowed = await PlanAccessService.hasFeature(
      'stock_transfer',
    );

    if (!allowed) {
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

    throw Exception(
      data['message'] ?? 'Failed to load shops.',
    );
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

    throw Exception(
      data['message'] ?? 'Failed to load products.',
    );
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

    throw Exception(
      data['message'] ?? 'Failed to load categories.',
    );
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

    throw Exception(
      data['message'] ?? 'Failed to load products for this shop.',
    );
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
    | Laravel validation errors
    |--------------------------------------------------------------------------
    */

    if (response.statusCode == 422) {
      if (data['errors'] != null) {
        final errors = data['errors'] as Map<String, dynamic>;

        final messages = errors.values
            .expand(
              (value) => value is List ? value : [value],
            )
            .map((value) => value.toString())
            .toList();

        throw Exception(
          messages.isNotEmpty
              ? messages.join('\n')
              : 'Invalid stock transfer information.',
        );
      }

      throw Exception(
        data['message'] ?? 'Invalid stock transfer information.',
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
  }
}