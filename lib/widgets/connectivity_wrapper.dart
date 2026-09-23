import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/auth_service.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late StreamSubscription _subscription;
  bool _isConnected = true;
  bool _showRestored = false;

  @override
  void initState() {
    super.initState();

    // Check initial connection
    Connectivity().checkConnectivity().then((result) {
      _handleResult(result);
    });

    // Listen for changes — works on both old and new devices
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      _handleResult(result);
    });
  }

  // Handles both List<ConnectivityResult> and ConnectivityResult
  void _handleResult(dynamic result) {
    bool connected;

    if (result is List) {
      connected = result.any((r) => r != ConnectivityResult.none);
    } else {
      connected = result != ConnectivityResult.none;
    }

    _updateStatus(connected);
  }

  void _updateStatus(bool connected) {
    if (!mounted) return;

    if (!connected && _isConnected) {
      setState(() {
        _isConnected = false;
        _showRestored = false;
      });
    } else if (connected && !_isConnected) {
      setState(() {
        _isConnected = true;
        _showRestored = true;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showRestored = false);
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This widget sits ABOVE MaterialApp, so nothing has supplied text
    // direction or screen metrics yet. Provide both here.
    //  - Directionality: required by Stack (and Row/Text below)
    //  - MediaQuery.fromView: required by SafeArea inside the banner
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery.fromView(
        view: View.of(context),
        child: Stack(
          children: [
            widget.child,

            ValueListenableBuilder<Map<String, dynamic>?>(
              valueListenable: AuthService.trialNotifier,
              builder: (context, trial, _) {
                if (trial == null) return const SizedBox.shrink();

                final daysLeft = trial['days_left'] as int;
                final expired = daysLeft <= 0;

                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: false,
                    child: SafeArea(
                      bottom: false,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: expired
                                ? [
                                    const Color(0xFFFF3D00),
                                    const Color(0xFFD50000),
                                  ]
                                : [
                                    const Color(0xFFFF9800),
                                    const Color(0xFFFF5722),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 18,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Text("🚀", style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Free Trial",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  Text(
                                    expired
                                        ? "Expired"
                                        : "$daysLeft day(s) left",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            if (!_isConnected)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: _Banner(
                    message: "No Internet Connection",
                    icon: Icons.wifi_off_rounded,
                    color: const Color(0xFFB71C1C),
                  ),
                ),
              ),

            if (_isConnected && _showRestored)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: _Banner(
                    message: "Internet Connection Restored",
                    icon: Icons.wifi_rounded,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color color;

  const _Banner({
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: Container(
        color: widget.color,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  // No Material ancestor up here, so without this Flutter
                  // draws its yellow double underline under the text.
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}