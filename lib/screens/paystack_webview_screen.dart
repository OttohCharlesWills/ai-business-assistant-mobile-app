import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Opens the Paystack checkout page.
/// Pops with `true` once Paystack redirects to [callbackUrl]; pops with
/// `null` if the user backs out.
class PaystackWebViewScreen extends StatefulWidget {
  final String authorizationUrl;
  final String callbackUrl;

  const PaystackWebViewScreen({
    super.key,
    required this.authorizationUrl,
    required this.callbackUrl,
  });

  @override
  State<PaystackWebViewScreen> createState() => _PaystackWebViewScreenState();
}

class _PaystackWebViewScreenState extends State<PaystackWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            if (request.url.startsWith(widget.callbackUrl)) {
              if (!_finished && mounted) {
                _finished = true;
                Navigator.of(context).pop(true);
              }
              // Never actually load the callback URL
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1F3F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1F3F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Secure payment",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF2F5DA8)),
            ),
        ],
      ),
    );
  }
}