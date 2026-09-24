import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class EmailVerificationService {
  /// Verify the authenticated user's email using OTP.
  static Future<Map<String, dynamic>> verifyOtp(String otp) async {
    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        return {
          'status': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/email/verify-otp'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);

      return {
        'status': data['status'] ?? false,
        'message': data['message'] ?? 'Something went wrong.',
        'email_verified': data['email_verified'] ?? false,
        'user': data['user'],
        'status_code': response.statusCode,
      };
    } catch (e) {
      return {
        'status': false,
        'message': 'Unable to verify email. Please check your connection.',
      };
    }
  }

  /// Resend a new OTP to the authenticated user's email.
  static Future<Map<String, dynamic>> resendOtp() async {
    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        return {
          'status': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/email/resend-otp'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      return {
        'status': data['status'] ?? false,
        'message': data['message'] ?? 'Something went wrong.',
        'email_verified': data['email_verified'] ?? false,
        'status_code': response.statusCode,
      };
    } catch (e) {
      return {
        'status': false,
        'message': 'Unable to resend verification code. Please check your connection.',
      };
    }
  }
}
