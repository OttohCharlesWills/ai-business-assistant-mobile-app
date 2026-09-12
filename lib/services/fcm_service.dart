import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'api_client.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📩 Background message: ${message.notification?.title}");
}

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static const String baseUrl =
      "https://bloommonie.store/api";

  static Future<void> init() async {
    print("========== FCM INIT ==========");

    // Request notification permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print("Permission Status: ${settings.authorizationStatus}");

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    // Get FCM token
    final token = await _messaging.getToken();

    print("Firebase returned token:");
    print(token);

    if (token != null) {
      print("Sending token to backend...");
      await sendTokenToBackend(token);
    } else {
      print("❌ FCM TOKEN IS NULL");
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      print("🔄 Token refreshed:");
      print(newToken);

      await sendTokenToBackend(newToken);
    });

    // Foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground Notification");
      print("Title: ${message.notification?.title}");
      print("Body: ${message.notification?.body}");
    });

    print("========== END FCM INIT ==========");
  }

  // Send FCM token to Laravel backend
  static Future<void> sendTokenToBackend(String fcmToken) async {
    try {
      final authToken = await AuthService.getToken();

      print("========== FCM DEBUG ==========");
      print("Auth Token:");
      print(authToken);

      print("FCM Token:");
      print(fcmToken);

      final response = await http.post(
        Uri.parse("$baseUrl/fcm-token"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "fcm_token": fcmToken,
        }),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body:");
      print(response.body);

      print("========== END REQUEST ==========");

    } catch (e, stackTrace) {
      print("❌ FCM token save error:");
      print(e);
      print(stackTrace);
    }
  }
}