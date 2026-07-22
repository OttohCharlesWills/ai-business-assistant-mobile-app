import 'dart:convert';
import 'package:http/http.dart' as http;
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

  // SAVE TOKEN + EXPIRY + ROLE
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);

    final expiry = DateTime.now()
        .add(const Duration(days: tokenExpiryDays))
        .toIso8601String();
    await prefs.setString('token_expiry', expiry);
  }

  // SAVE ROLE
  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
  }

  // SAVE USER INFO
  static Future<void> saveUserInfo(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_info', jsonEncode(user));
  }

  // GET TOKEN
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // GET ROLE
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  // GET USER INFO
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user_info');
    if (userString == null) return null;
    return jsonDecode(userString);
  }

  // CLEAR TOKEN + ROLE + USER INFO
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('token_expiry');
    await prefs.remove('user_role');
    await prefs.remove('user_info');
  }

  // CHECK IF TOKEN IS EXPIRED
  static Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString('token_expiry');

    if (expiryString == null) return true;

    final expiry = DateTime.parse(expiryString);
    return DateTime.now().isAfter(expiry);
  }

  // CHECK IF LOGGED IN
  static Future<bool> isLoggedIn() async {
    final token = await getToken();

    if (token == null) return false;

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

  // SAVE FCM TOKEN TO BACKEND
  static Future<void> saveFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      final token = await getToken();
      if (token == null) return;

      await http.post(
        Uri.parse("$baseUrl/fcm-token"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: {"fcm_token": fcmToken},
      );
    } catch (e) {
      print("FCM token save error: $e");
    }
  }

  // LOGOUT
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
        // ignore
      }
    }

    await ShopService.clearCache();
    await CategoryService.clearCache();
    await clearToken();
    await googleSignIn.signOut();
  }

  // NORMAL REGISTER
  static Future register({
    required String name,
    required String email,
    required String password,
  }) async {

    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Accept": "application/json"},
      body: {
        "name": name,
        "email": email,
        "password": password,
      },
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true && data['token'] != null) {
      await saveToken(data['token']);
      await saveRole(data['role'] ?? 'admin');
      if (data['user'] != null) {
        await saveUserInfo(data['user']);
      }
    }

    return data;
  }

  // NORMAL LOGIN
  static Future login({
    required String email,
    required String password,
  }) async {

    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Accept": "application/json"},
      body: {
        "email": email,
        "password": password,
      },
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true && data['token'] != null) {
      await saveToken(data['token']);
      await saveRole(data['role'] ?? 'admin');
      if (data['user'] != null) {
        await saveUserInfo(data['user']);
      }
    }

    return data;
  }

  // GOOGLE LOGIN
  static Future googleLogin() async {

    try {

      final GoogleSignInAccount? user = await googleSignIn.signIn();

      if (user == null) {
        return {
          "status": false,
          "message": "Google sign in cancelled"
        };
      }

      final email = user.email;
      final name = user.displayName ?? "No Name";

      final response = await http.post(
        Uri.parse("$baseUrl/google-login"),
        headers: {"Accept": "application/json"},
        body: {
          "email": email,
          "name": name,
        },
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true && data['token'] != null) {
        await saveToken(data['token']);
        await saveRole(data['role'] ?? 'admin');
        if (data['user'] != null) {
          await saveUserInfo(data['user']);
        }
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
}