import 'dart:convert';

import 'package:flutter/material.dart';
import 'api_client.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shop_service.dart';
import 'category_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  static const String baseUrl =
      "https://bloommonie.store/api";

  static const int tokenExpiryDays = 30;

  static final GoogleSignIn googleSignIn = GoogleSignIn();

  static final ValueNotifier<Map<String, dynamic>?> trialNotifier =
      ValueNotifier(null);

  // ============================================================
  // TRIAL
  // ============================================================

  static Future<void> loadTrialNotifier() async {
    final free = await isFreeTrial();
    final days = await getTrialDaysLeft();

    trialNotifier.value =
        free ? {'days_left': days} : null;
  }

  // ============================================================
  // SAVE TOKEN
  // ============================================================

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('auth_token', token);

    final expiry = DateTime.now()
        .add(const Duration(days: tokenExpiryDays))
        .toIso8601String();

    await prefs.setString('token_expiry', expiry);
  }

  // ============================================================
  // SAVE ROLE
  // ============================================================

  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_role', role);
  }

  // ============================================================
  // SAVE USER INFO
  // ============================================================

  static Future<void> saveUserInfo(
      Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'user_info',
      jsonEncode(user),
    );
  }

  // ============================================================
  // SAVE TRIAL INFO
  // ============================================================

  static Future<void> saveTrialInfo({
    required bool isFreeTrial,
    required int trialDaysLeft,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      'is_free_trial',
      isFreeTrial,
    );

    await prefs.setInt(
      'trial_days_left',
      trialDaysLeft,
    );

    trialNotifier.value = isFreeTrial
        ? {'days_left': trialDaysLeft}
        : null;
  }

  // ============================================================
  // SAVE EMAIL VERIFIED
  // ============================================================

  static Future<void> saveEmailVerified(
      bool verified) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      'email_verified',
      verified,
    );
  }

  // ============================================================
  // GET EMAIL VERIFIED
  // ============================================================

  static Future<bool> isEmailVerified() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool('email_verified') ?? false;
  }

  // ============================================================
  // GET TOKEN
  // ============================================================

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('auth_token');
  }

  // ============================================================
  // GET ROLE
  // ============================================================

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('user_role');
  }

  // ============================================================
  // GET USER INFO
  // ============================================================

  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    final userString = prefs.getString('user_info');

    if (userString == null) {
      return null;
    }

    return jsonDecode(userString);
  }

  // ============================================================
  // GET TRIAL INFO
  // ============================================================

  static Future<bool> isFreeTrial() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool('is_free_trial') ?? false;
  }

  static Future<int> getTrialDaysLeft() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt('trial_days_left') ?? 0;
  }

  // ============================================================
  // CLEAR AUTH DATA
  // ============================================================

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('auth_token');
    await prefs.remove('token_expiry');
    await prefs.remove('user_role');
    await prefs.remove('user_info');
    await prefs.remove('is_free_trial');
    await prefs.remove('trial_days_left');
    await prefs.remove('email_verified');

    trialNotifier.value = null;
  }

  // ============================================================
  // TOKEN EXPIRY
  // ============================================================

  static Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();

    final expiryString =
        prefs.getString('token_expiry');

    if (expiryString == null) {
      return true;
    }

    final expiry = DateTime.parse(expiryString);

    return DateTime.now().isAfter(expiry);
  }

  // ============================================================
  // CHECK IF LOGGED IN
  // ============================================================

  static Future<bool> isLoggedIn() async {
    final token = await getToken();

    if (token == null) {
      return false;
    }

    final expired = await isTokenExpired();

    if (expired) {
      await clearToken();
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/user"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 401) {
        await clearToken();
        return false;
      }

      return response.statusCode == 200;
    } catch (e) {
      return true;
    }
  }

  // ============================================================
  // CHECK EMAIL VERIFICATION FROM SERVER
  // ============================================================

  static Future<bool> checkVerificationStatus() async {
    final token = await getToken();

    if (token == null) {
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/user"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body);

      final user = data['user'] ?? data;

      final verified =
          user['email_verified_at'] != null;

      await saveEmailVerified(verified);

      if (user is Map<String, dynamic>) {
        await saveUserInfo(user);
      }

      return verified;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // VERIFY EMAIL OTP
  // ============================================================

  static Future<Map<String, dynamic>>
      verifyEmailOtp(String otp) async {

    final token = await getToken();

    if (token == null || token.isEmpty) {
      return {
        "status": false,
        "message":
            "Authentication token not found. Please log in again.",
      };
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/email/verify-otp"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "otp": otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true &&
          data['email_verified'] == true) {

        await saveEmailVerified(true);

        if (data['user'] != null) {
          await saveUserInfo(
            Map<String, dynamic>.from(
              data['user'],
            ),
          );
        }
      }

      return data;
    } catch (e) {
      return {
        "status": false,
        "message":
            "Unable to verify email. Please check your internet connection.",
      };
    }
  }

  // ============================================================
  // RESEND EMAIL OTP
  // ============================================================

  static Future<Map<String, dynamic>>
      resendEmailOtp() async {

    final token = await getToken();

    if (token == null || token.isEmpty) {
      return {
        "status": false,
        "message":
            "Authentication token not found. Please log in again.",
      };
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/email/resend-otp"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        "status": false,
        "message":
            "Unable to resend verification code. Please check your internet connection.",
      };
    }
  }

  // ============================================================
  // SAVE FCM TOKEN
  // ============================================================

  static Future<void> saveFcmToken() async {
    try {
      final fcmToken =
          await FirebaseMessaging.instance.getToken();

      if (fcmToken == null) {
        return;
      }

      final token = await getToken();

      if (token == null) {
        return;
      }

      await http.post(
        Uri.parse("$baseUrl/fcm-token"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "fcm_token": fcmToken,
        }),
      );
    } catch (e) {
      print("FCM token save error: $e");
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> logout() async {
    final token = await getToken();

    if (token != null) {
      try {
        await http.post(
          Uri.parse("$baseUrl/logout"),
          headers: {
            "Accept": "application/json",
            "Authorization": "Bearer $token",
          },
        );
      } catch (e) {
        // Ignore logout API errors
      }
    }

    await ShopService.clearCache();
    await CategoryService.clearCache();

    await clearToken();

    await googleSignIn.signOut();
  }

  // ============================================================
  // NORMAL REGISTER
  // ============================================================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {

    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        if (phone != null && phone.isNotEmpty)
          "phone": phone,
      }),
    );

    final data = jsonDecode(response.body);

    // ========================================================
    // SAVE AUTH DATA
    // ========================================================

    if (data['status'] == true &&
        data['token'] != null) {

      await saveToken(data['token']);

      await saveRole(
        data['role'] ??
            data['user']?['role'] ??
            'admin',
      );

      if (data['user'] != null) {
        await saveUserInfo(
          Map<String, dynamic>.from(
            data['user'],
          ),
        );
      }

      await saveTrialInfo(
        isFreeTrial:
            data['is_free_trial'] ?? true,
        trialDaysLeft:
            data['trial_days_left'] ?? 3,
      );

      await saveEmailVerified(
        data['email_verified'] ?? false,
      );
    }

    return data;
  }

  // ============================================================
  // NORMAL LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {

    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true &&
        data['token'] != null) {

      await saveToken(data['token']);

      await saveRole(
        data['role'] ??
            data['user']?['role'] ??
            'admin',
      );

      if (data['user'] != null) {
        await saveUserInfo(
          Map<String, dynamic>.from(
            data['user'],
          ),
        );
      }

      await saveTrialInfo(
        isFreeTrial:
            data['is_free_trial'] ?? false,
        trialDaysLeft:
            data['trial_days_left'] ?? 0,
      );

      await saveEmailVerified(
        data['email_verified'] ?? true,
      );
    }

    return data;
  }

  // ============================================================
  // GOOGLE LOGIN
  // ============================================================

  static Future<Map<String, dynamic>>
      googleLogin() async {

    try {
      final GoogleSignInAccount? user =
          await googleSignIn.signIn();

      if (user == null) {
        return {
          "status": false,
          "message": "Google sign in cancelled",
        };
      }

      final email = user.email;
      final name = user.displayName ?? "No Name";

      final response = await http.post(
        Uri.parse("$baseUrl/google-login"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "name": name,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true &&
          data['token'] != null) {

        await saveToken(data['token']);

        await saveRole(
          data['role'] ??
              data['user']?['role'] ??
              'admin',
        );

        if (data['user'] != null) {
          await saveUserInfo(
            Map<String, dynamic>.from(
              data['user'],
            ),
          );
        }

        await saveTrialInfo(
          isFreeTrial:
              data['is_free_trial'] ?? false,
          trialDaysLeft:
              data['trial_days_left'] ?? 0,
        );

        await saveEmailVerified(
          data['email_verified'] ?? true,
        );
      }

      return data;
    } catch (e) {
      print(e);

      return {
        "status": false,
        "message": e.toString(),
      };
    }
  }

  // ============================================================
  // LAST LOGIN EMAIL
  // ============================================================

  static Future<void> saveLastEmail(
      String email) async {

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'last_login_email',
      email,
    );
  }

  static Future<String?> getLastEmail() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('last_login_email');
  }
}