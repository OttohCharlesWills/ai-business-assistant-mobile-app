import 'dart:convert';
import 'package:http/http.dart' as http;

import '../main.dart';
import '../screens/subscription_expired_screen.dart';
import 'package:flutter/material.dart';

// Top-level wrappers so other files can import this as "http"
// and change NOTHING else in their code.
Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
  final response = await http.get(uri, headers: headers);
  _checkSubscription(response);
  return response;
}

Future<http.Response> post(
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  final response = await http.post(uri, headers: headers, body: body, encoding: encoding);
  _checkSubscription(response);
  return response;
}

Future<http.Response> put(
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  final response = await http.put(uri, headers: headers, body: body, encoding: encoding);
  _checkSubscription(response);
  return response;
}

Future<http.Response> patch(
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  final response = await http.patch(uri, headers: headers, body: body, encoding: encoding);
  _checkSubscription(response);
  return response;
}

Future<http.Response> delete(Uri uri, {Map<String, String>? headers}) async {
  final response = await http.delete(uri, headers: headers);
  _checkSubscription(response);
  return response;
}

void _checkSubscription(http.Response response) {
  if (response.statusCode != 403) return;

  try {
    final data = jsonDecode(response.body);
    if (data['subscription_expired'] == true) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SubscriptionExpiredScreen()),
        (route) => false,
      );
    }
  } catch (e) {
    // ignore invalid JSON
  }
}