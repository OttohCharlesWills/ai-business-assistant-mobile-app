import 'dart:convert';

import 'package:flutter/material.dart';
import 'api_client.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shop_service.dart';
import 'category_service.dart';
import 'api_exception.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// TODO: change this path to wherever your isNetworkError / kNoInternetMessage
// helper file lives.
import '../helpers/error_helper.dart';

class AuthService {
  static const String baseUrl =
      "https://bloommonie.store/api";

  static const int tokenExpiryDays = 30;

  static final GoogleSignIn googleSignIn = GoogleSignIn();

  static final ValueNotifier<Map<String, dynamic>?> trialNotifier =
      ValueNotifier(null);

  // ============================================================
  // ERROR HELPERS
  // ============================================================

  /// Decodes a response body into a Map. Throws a clean
  /// [ApiException] for server errors or non-JSON replies.
  /// 4xx replies (wrong password, validation, etc.) are returned
  /// so their server message can be shown to the user.
  static Map<String, dynamic> _decode(dynamic response) {
    final code = response.statusCode as int;

    if (code >= 500) {
      throw ApiException("Server error. Please try again later.", code);
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // falls through
    }

    throw ApiException("Unexpected response from server.", code);
  }

  /// Turns any exception into the usual {status: false, message: ...}
  /// map, with a message that is safe to show to the user.
  /// The raw error only goes to the debug console.
  
    static Map<String, dynamic> _failure(Object e, String fallback) {
      debugPrint("AuthService error: $e");

      if (isNetworkError(e)) {
        return {
          "status": false,
          "message": kNoInternetMessage,
        };
      }

      if (e is ApiException) {
        return {
          "status": false,
          "message": e.message,
        };
      }

      return {
        "status": false,
        "message": fallback,
      };
    }


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

    try {
      return Map<String, dynamic>.from(jsonDecode(userString));
    } catch (_) {
      return null;
    }
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

    final expiry = DateTime.tryParse(expiryString);

    if (expiry == null) {
      return true;
    }

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

      // Only a 401 means the token is really invalid.
      if (response.statusCode == 401) {
        await clearToken();
        return false;
      }

      // Any other reply (200, a temporary server error, etc.)
      // keeps the user signed in.
      return true;
    } catch (e) {
      // Offline or timeout: keep the user signed in.
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

      final data = _decode(response);

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
      return _failure(
        e,
        "Unable to verify email. Please try again.",
      );
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

      return _decode(response);
    } catch (e) {
      return _failure(
        e,
        "Unable to resend verification code. Please try again.",
      );
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
      debugPrint("FCM token save error: $e");
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

    try {
      await googleSignIn.signOut();
    } catch (e) {
      // Ignore Google sign-out errors
    }
  }

  // ============================================================
  // SAVE AUTH DATA AFTER LOGIN / REGISTER / GOOGLE LOGIN
  // ============================================================

  static Future<void> _saveAuthData(
    Map<String, dynamic> data, {
    required bool defaultFreeTrial,
    required int defaultTrialDays,
    required bool defaultEmailVerified,
  }) async {
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
          data['is_free_trial'] ?? defaultFreeTrial,
      trialDaysLeft:
          data['trial_days_left'] ?? defaultTrialDays,
    );

    await saveEmailVerified(
      data['email_verified'] ?? defaultEmailVerified,
    );
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
    try {
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

      final data = _decode(response);

      if (data['status'] == true &&
          data['token'] != null) {
        await _saveAuthData(
          data,
          defaultFreeTrial: true,
          defaultTrialDays: 3,
          defaultEmailVerified: false,
        );
      }

      return data;
    } catch (e) {
      return _failure(
        e,
        "Could not create your account. Please try again.",
      );
    }
  }

  // ============================================================
  // NORMAL LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
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

      final data = _decode(response);

      if (data['status'] == true &&
          data['token'] != null) {
        await _saveAuthData(
          data,
          defaultFreeTrial: false,
          defaultTrialDays: 0,
          defaultEmailVerified: true,
        );
      }

      return data;
    } catch (e) {
      return _failure(
        e,
        "Could not log in. Please try again.",
      );
    }
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

      final data = _decode(response);

      if (data['status'] == true &&
          data['token'] != null) {
        await _saveAuthData(
          data,
          defaultFreeTrial: false,
          defaultTrialDays: 0,
          defaultEmailVerified: true,
        );
      }

      return data;
    } catch (e) {
      return _failure(
        e,
        "Google sign in failed. Please try again.",
      );
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