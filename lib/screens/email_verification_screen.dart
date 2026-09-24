import 'dart:async';

import 'package:flutter/material.dart';

import '../services/email_verification_service.dart';
import '../services/auth_service.dart';
import 'admin/dashboard_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends State<EmailVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  Timer? _expiryTimer;
  Timer? _resendTimer;

  int _expirySeconds = 600; // 10 minutes
  int _resendSeconds = 60; // 60 seconds

  bool _isVerifying = false;
  bool _isResending = false;

  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();

    _startExpiryTimer();
    _startResendTimer();

    // Automatically open keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });

    _otpController.addListener(_otpChanged);
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _resendTimer?.cancel();

    _otpController.removeListener(_otpChanged);
    _otpController.dispose();
    _otpFocusNode.dispose();

    super.dispose();
  }

  // ============================================================
  // OTP INPUT
  // ============================================================

  void _otpChanged() {
    final otp = _otpController.text.trim();

    if (otp.length == 6 && !_isVerifying) {
      _verifyOtp();
    }
  }

  // ============================================================
  // EXPIRY TIMER
  // ============================================================

  void _startExpiryTimer() {
    _expiryTimer?.cancel();

    _expiryTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_expirySeconds <= 0) {
          timer.cancel();
          return;
        }

        setState(() {
          _expirySeconds--;
        });
      },
    );
  }

  String get _expiryText {
    final minutes = _expirySeconds ~/ 60;
    final seconds = _expirySeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // RESEND TIMER
  // ============================================================

  void _startResendTimer() {
    _resendTimer?.cancel();

    _resendSeconds = 60;

    _resendTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_resendSeconds <= 0) {
          timer.cancel();
          return;
        }

        setState(() {
          _resendSeconds--;
        });
      },
    );
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result =
        await AuthService.verifyEmailOtp(otp);

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
    });

    if (result['status'] == true &&
        result['email_verified'] == true) {

      setState(() {
        _successMessage = 'Email verified successfully.';
      });

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      // --------------------------------------------------------
      // TODO:
      // Replace this with your actual dashboard/home screen.
      // --------------------------------------------------------

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(),
      ),
      (route) => false,
    );

    } else {
      setState(() {
        _errorMessage =
            result['message'] ?? 'Invalid verification code.';
      });

      _otpController.clear();

      if (_errorMessage!.contains('expired')) {
        setState(() {
          _expirySeconds = 0;
        });
      }
    }
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0 || _isResending) {
      return;
    }

    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result =
         await AuthService.resendEmailOtp();

    if (!mounted) return;

    setState(() {
      _isResending = false;
    });

    if (result['status'] == true) {
      _otpController.clear();

      setState(() {
        _successMessage =
            'A new verification code has been sent to your email.';
        _expirySeconds = 600;
      });

      _startExpiryTimer();
      _startResendTimer();

      _otpFocusNode.requestFocus();
    } else {
      setState(() {
        _errorMessage =
            result['message'] ?? 'Unable to resend verification code.';
      });

      // If backend says to wait, restart a 60-second cooldown.
      if (result['status_code'] == 429) {
        _startResendTimer();
      }
    }
  }

  // ============================================================
  // FORMAT EMAIL
  // ============================================================

  String get _maskedEmail {
    final email = widget.email;

    final parts = email.split('@');

    if (parts.length != 2) {
      return email;
    }

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '$username@$domain';
    }

    final first = username.substring(0, 2);

    return '$first${'*' * (username.length - 2)}@$domain';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 30,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              child: Column(
                children: [

                  // ==================================================
                  // LOGO
                  // ==================================================

                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F5DA8),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.mark_email_read_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // TITLE
                  // ==================================================

                  const Text(
                    'Verify Your Email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0C1F3F),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'We sent a 6-digit verification code to',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _maskedEmail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2F5DA8),
                    ),
                  ),

                  const SizedBox(height: 35),

                  // ==================================================
                  // OTP CARD
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [

                        const Text(
                          'Enter verification code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0C1F3F),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ==================================================
                        // OTP INPUT
                        // ==================================================

                        TextField(
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          maxLength: 6,
                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 10,
                            color: Color(0xFF0C1F3F),
                          ),

                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '••••••',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade300,
                              letterSpacing: 8,
                            ),

                            filled: true,
                            fillColor: const Color(0xFFF8FAFD),

                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),

                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF2F5DA8),
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // EXPIRY
                        // ==================================================

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [

                            Icon(
                              Icons.timer_outlined,
                              size: 18,
                              color: _expirySeconds == 0
                                  ? Colors.red
                                  : Colors.grey.shade600,
                            ),

                            const SizedBox(width: 6),

                            Text(
                              _expirySeconds > 0
                                  ? 'Code expires in $_expiryText'
                                  : 'Code has expired',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _expirySeconds == 0
                                    ? Colors.red
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ==================================================
                        // VERIFY BUTTON
                        // ==================================================

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                _isVerifying ||
                                        _otpController.text.length != 6
                                    ? null
                                    : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF2F5DA8),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  Colors.grey.shade300,
                              disabledForegroundColor:
                                  Colors.grey.shade600,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                            child: _isVerifying
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Verify Email',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // ERROR
                        // ==================================================

                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            margin:
                                const EdgeInsets.only(bottom: 12),
                            padding:
                                const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        // ==================================================
                        // SUCCESS
                        // ==================================================

                        if (_successMessage != null)
                          Container(
                            width: double.infinity,
                            margin:
                                const EdgeInsets.only(bottom: 12),
                            padding:
                                const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  Colors.green.withOpacity(0.08),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Text(
                              _successMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        // ==================================================
                        // RESEND
                        // ==================================================

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [

                            Text(
                              "Didn't receive the code?",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),

                            const SizedBox(width: 5),

                            TextButton(
                              onPressed:
                                  _resendSeconds == 0 &&
                                          !_isResending
                                      ? _resendOtp
                                      : null,
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                              ),
                              child: _isResending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _resendSeconds > 0
                                          ? 'Resend (${_resendSeconds}s)'
                                          : 'Resend Code',
                                      style: const TextStyle(
                                        color:
                                            Color(0xFF2F5DA8),
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // SECURITY MESSAGE
                  // ==================================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [

                      Icon(
                        Icons.lock_outline,
                        size: 15,
                        color: Colors.grey.shade500,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        'Your verification code is secure',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

