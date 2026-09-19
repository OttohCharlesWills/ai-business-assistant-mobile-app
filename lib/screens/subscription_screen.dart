import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import 'paystack_webview_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  /// Called after the payment is verified and the plan is active.
  final VoidCallback onActivated;

  const SubscriptionScreen({super.key, required this.onActivated});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const _bg = Color(0xFF0C1F3F);
  static const _card = Color(0xFF13294D);
  static const _accent = Color(0xFF2F5DA8);
  static const _muted = Color(0xFF8FAADC);

  late Future<List<SubscriptionPlan>> _plansFuture;
  String _billing = 'monthly';
  String? _selectedPlanId;
  bool _processing = false;
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _plansFuture = SubscriptionService.fetchPlans();
    _prefillEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Fill in the email so the user never has to type it: first the saved
  /// user info, then the email they last logged in with (which survives
  /// the app wiping the session when a plan expires).
  Future<void> _prefillEmail() async {
    final info = await AuthService.getUserInfo();
    String? email = info?['email'] is String ? info!['email'] as String : null;
    email ??= await AuthService.getLastEmail();

    if (!mounted || email == null || email.isEmpty) return;
    if (_emailController.text.isEmpty) _emailController.text = email;
  }

  void _reload() {
    // Block body on purpose: an arrow function would return the Future,
    // and setState asserts if its callback returns one.
    setState(() {
      _plansFuture = SubscriptionService.fetchPlans();
    });
  }

  String _naira(int amount) {
    final digits = amount.toString();
    final formatted = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '₦$formatted';
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red.shade700 : _accent,
        ),
      );
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    final email = _emailController.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      _snack('Enter the email address of your account', error: true);
      return;
    }

    setState(() => _processing = true);

    try {
      final session = await SubscriptionService.initializePayment(
        email: email,
        plan: plan.id,
        billing: _billing,
      );
      if (!mounted) return;

      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaystackWebViewScreen(
            authorizationUrl: session.authorizationUrl,
            callbackUrl: session.callbackUrl,
          ),
        ),
      );
      if (!mounted) return;

      if (completed != true) {
        _snack('Payment cancelled');
        return;
      }

      final result = await SubscriptionService.verifyPayment(session.reference);
      if (!mounted) return;

      if (result.success) {
        _snack(result.message);
        widget.onActivated();
      } else {
        _snack(result.message, error: true);
      }
    } on SubscriptionException catch (e) {
      if (mounted) _snack(e.message, error: true);
    } catch (_) {
      if (mounted) _snack('Something went wrong. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Choose a plan",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<SubscriptionPlan>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: _accent),
            );
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            return _buildError(
              error.toString(),
              retryable: error is SubscriptionException ? error.retryable : true,
            );
          }

          final plans = snapshot.data!;
          final selected = plans.where((p) => p.id == _selectedPlanId);
          final selectedPlan = selected.isEmpty ? null : selected.first;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: _buildEmailField(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: _buildBillingToggle(),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: plans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _buildPlanCard(plans[i]),
                ),
              ),
              _buildSubscribeButton(selectedPlan),
            ],
          );
        },
      ),
    );
  }

  Widget _buildError(String message, {bool retryable = true}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              retryable ? Icons.wifi_off_rounded : Icons.lock_outline_rounded,
              size: 36,
              color: _muted,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 14, height: 1.5),
            ),
            if (retryable) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: _reload,
                child: const Text("Try again", style: TextStyle(color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      enabled: !_processing,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Account email',
        labelStyle: const TextStyle(color: _muted),
        helperText: 'The email you log in with',
        helperStyle: const TextStyle(color: _muted, fontSize: 12),
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 2),
        ),
      ),
    );
  }

  Widget _buildBillingToggle() {
    Widget option(String value, String label) {
      final active = _billing == value;
      return Expanded(
        child: GestureDetector(
          onTap: _processing ? null : () => setState(() => _billing = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active ? _accent : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : _muted,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          option('monthly', 'Monthly'),
          option('yearly', 'Yearly'),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final selected = plan.id == _selectedPlanId;
    final yearly = _billing == 'yearly';

    return GestureDetector(
      onTap: _processing ? null : () => setState(() => _selectedPlanId = plan.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_naira(plan.priceFor(_billing))} / ${yearly ? 'year' : 'month'}',
                    style: const TextStyle(color: _muted, fontSize: 14),
                  ),
                  if (yearly && plan.yearlySavings > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Save ${_naira(plan.yearlySavings)} a year',
                      style: const TextStyle(
                        color: Color(0xFF6FCF97),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? _accent : _muted,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeButton(SubscriptionPlan? plan) {
    final label = plan == null
        ? 'Select a plan'
        : 'Pay ${_naira(plan.priceFor(_billing))}';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              disabledBackgroundColor: _accent.withOpacity(0.35),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: (plan == null || _processing) ? null : () => _subscribe(plan),
            child: _processing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}