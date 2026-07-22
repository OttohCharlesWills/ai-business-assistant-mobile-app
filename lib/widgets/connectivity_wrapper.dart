import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
    return Stack(
      children: [
        widget.child,

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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}