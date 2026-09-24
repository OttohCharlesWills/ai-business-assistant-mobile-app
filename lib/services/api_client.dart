
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../main.dart';
import '../screens/subscription_expired_screen.dart';
import 'package:flutter/material.dart';

// ============================================================
// GET
// ============================================================

Future<http.Response> get(
  Uri uri, {
  Map<String, String>? headers,
}) async {
  final response = await http.get(
    uri,
    headers: headers,
  );

  _checkSubscription(response);

  return response;
}

// ============================================================
// POST
// ============================================================

Future<http.Response> post(
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  final response = await http.post(
    uri,
    headers: headers,
    body: _prepareBody(body, headers),
    encoding: encoding,
  );

  _checkSubscription(response);

  return response;
}

// ============================================================
// PUT
// ============================================================

Future<http.Response> put(
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  final response = await http.put(
    uri,
    headers: headers,
    body: _prepareBody(body, headers),
    encoding: encoding,
  );

  _checkSubscription(response);

  return response;
}

// ============================================================
// PATCH
// ============================================================

Future<http.Response> patch(
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  final response = await http.patch(
    uri,
    headers: headers,
    body: _prepareBody(body, headers),
    encoding: encoding,
  );

  _checkSubscription(response);

  return response;
}

// ============================================================
// DELETE
// ============================================================

Future<http.Response> delete(
  Uri uri, {
  Map<String, String>? headers,
}) async {
  final response = await http.delete(
    uri,
    headers: headers,
  );

  _checkSubscription(response);

  return response;
}

// ============================================================
// PREPARE REQUEST BODY
// ============================================================
//
// If Content-Type is application/json and the body is a Map,
// automatically convert it to a JSON string.
//
// This allows existing code like:
//
// body: {
//   "email": email,
//   "password": password,
// }
//
// to work correctly with:
//
// Content-Type: application/json
//
// ============================================================

Object? _prepareBody(
  Object? body,
  Map<String, String>? headers,
) {
  if (body == null) {
    return null;
  }

  final contentType = headers?['Content-Type'] ??
      headers?['content-type'] ??
      '';

  if (contentType.toLowerCase().contains('application/json')) {
    if (body is Map ||
        body is List) {
      return jsonEncode(body);
    }
  }

  return body;
}

// ============================================================
// SUBSCRIPTION CHECK
// ============================================================

void _checkSubscription(http.Response response) {
  if (response.statusCode != 403) {
    return;
  }

  try {
    final data = jsonDecode(response.body);

    if (data['subscription_expired'] == true) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              const SubscriptionExpiredScreen(),
        ),
        (route) => false,
      );
    }
  } catch (e) {
    // Ignore invalid JSON
  }
}