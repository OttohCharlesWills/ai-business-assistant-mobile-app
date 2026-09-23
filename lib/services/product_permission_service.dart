import 'dart:convert';

import 'api_client.dart';

class ProductPermissionService {
  /// Get managers, permissions, and the authenticated user's shops.
  Future<Map<String, dynamic>> getPermissions({
    required String baseUrl,
    required String token,
  }) async {
    final response = await get(
      Uri.parse('$baseUrl/product-permissions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] ?? {};
    }

    throw Exception(
      data['message'] ?? 'Failed to load product permissions.',
    );
  }

  /// Grant product access to a manager.
  Future<Map<String, dynamic>> grantAccess({
    required String baseUrl,
    required String token,
    required int managerId,
  }) async {
    final response = await post(
      Uri.parse('$baseUrl/product-permissions/grant'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'manager_id': managerId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['success'] == true) {
      return data;
    }

    if (response.statusCode == 422) {
      if (data['errors'] != null) {
        final errors = data['errors'] as Map<String, dynamic>;

        final messages = errors.values
            .expand((value) => value is List ? value : [value])
            .map((value) => value.toString())
            .toList();

        throw Exception(
          messages.isNotEmpty
              ? messages.join('\n')
              : 'Invalid manager information.',
        );
      }

      throw Exception(
        data['message'] ?? 'The selected user is not a manager.',
      );
    }

    throw Exception(
      data['message'] ?? 'Failed to grant product access.',
    );
  }

  /// Revoke product access from a manager.
  Future<Map<String, dynamic>> revokeAccess({
    required String baseUrl,
    required String token,
    required int managerId,
  }) async {
    final response = await post(
      Uri.parse('$baseUrl/product-permissions/revoke'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'manager_id': managerId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    }

    if (response.statusCode == 404) {
      throw Exception(
        data['message'] ?? 'No access record found for this manager.',
      );
    }

    if (response.statusCode == 422) {
      if (data['errors'] != null) {
        final errors = data['errors'] as Map<String, dynamic>;

        final messages = errors.values
            .expand((value) => value is List ? value : [value])
            .map((value) => value.toString())
            .toList();

        throw Exception(
          messages.isNotEmpty
              ? messages.join('\n')
              : 'Invalid manager information.',
        );
      }

      throw Exception(
        data['message'] ?? 'Invalid manager information.',
      );
    }

    throw Exception(
      data['message'] ?? 'Failed to revoke product access.',
    );
  }
}