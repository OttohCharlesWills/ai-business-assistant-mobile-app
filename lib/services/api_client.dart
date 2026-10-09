
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../helpers/error_helper.dart';
import '../main.dart';
import '../screens/subscription_expired_screen.dart';

// ============================================================
// CENTRAL REQUEST HANDLER
// ============================================================

Future<http.Response> _send(
  Future<http.Response> Function() request,
) async {
  try {
    final response = await request();

    _checkSubscription(response);

    return response;
  } on SocketException {
    throw const FriendlyNetworkException();
  } on TimeoutException {
    throw const FriendlyNetworkException();
  } on http.ClientException catch (e) {
    if (isNetworkError(e)) {
      throw const FriendlyNetworkException();
    }
    rethrow;
  } catch (e) {
    if (isNetworkError(e)) {
      throw const FriendlyNetworkException();
    }
    rethrow;
  }
}

// ============================================================
// GET
// ============================================================

Future<http.Response> get(
  Uri uri, {
  Map<String, String>? headers,
}) {
  return _send(
    () => http.get(uri, headers: headers),
  );
}

// ============================================================
// POST
// ============================================================

Future<http.Response> post(
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) {
  return _send(
    () => http.post(
      uri,
      headers: headers,
      body: _prepareBody(body, headers),
      encoding: encoding,
    ),
  );
}

// ============================================================
// PUT
// ============================================================

Future<http.Response> put(
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) {
  return _send(
    () => http.put(
      uri,
      headers: headers,
      body: _prepareBody(body, headers),
      encoding: encoding,
    ),
  );
}

// ============================================================
// PATCH
// ============================================================

Future<http.Response> patch(
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) {
  return _send(
    () => http.patch(
      uri,
      headers: headers,
      body: _prepareBody(body, headers),
      encoding: encoding,
    ),
  );
}

// ============================================================
// DELETE
// ============================================================

Future<http.Response> delete(
  Uri uri, {
  Map<String, String>? headers,
}) {
  return _send(
    () => http.delete(uri, headers: headers),
  );
}

// ============================================================
// PREPARE REQUEST BODY
// ============================================================
//
// Automatically JSON-encodes Map or List bodies when the
// Content-Type header is application/json.
// ============================================================

Object? _prepareBody(
  Object? body,
  Map<String, String>? headers,
) {
  if (body == null) {
    return null;
  }

  String contentType = '';

  if (headers != null) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'content-type') {
        contentType = entry.value;
        break;
      }
    }
  }

  if (contentType.toLowerCase().contains('application/json')) {
    if (body is Map || body is List) {
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
    final dynamic data = jsonDecode(response.body);

    if (data is Map &&
        data['subscription_expired'] == true) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const SubscriptionExpiredScreen(),
        ),
        (route) => false,
      );
    }
  } catch (_) {
    // Ignore invalid JSON.
  }
}
