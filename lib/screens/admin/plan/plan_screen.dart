import 'package:flutter/material.dart';

import '../../../services/plan_service.dart';
import '../../subscription_screen.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  static const Color _backgroundColor = Color(0xFF0C1F3F);
  static const Color _cardColor = Color(0xFF13294D);
  static const Color _accentColor = Color(0xFF2F5DA8);
  static const Color _mutedColor = Color(0xFF8FAADC);
  static const Color _successColor = Color(0xFF38C793);
  static const Color _warningColor = Color(0xFFFFC857);
  static const Color _dangerColor = Color(0xFFFF647C);

  bool _loading = true;
  bool _refreshing = false;

  String? _errorMessage;

  Map<String, dynamic> _plan = {};
  Map<String, dynamic> _limits = {};
  Map<String, dynamic> _usage = {};

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  // ---------------------------------------------------------------------------
  // LOAD PLAN
  // ---------------------------------------------------------------------------

  Future<void> _loadPlan({
    bool refresh = false,
  }) async {
    if (refresh) {
      setState(() {
        _refreshing = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await PlanService.getPlan();

      if (!mounted) return;

      setState(() {
        _plan = Map<String, dynamic>.from(
          data['plan'] ?? {},
        );

        _limits = Map<String, dynamic>.from(
          data['limits'] ?? {},
        );

        _usage = Map<String, dynamic>.from(
          data['usage'] ?? {},
        );

        _loading = false;
        _refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _refreshing = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '');
  }

  String _stringValue(
    dynamic value, {
    String fallback = 'N/A',
  }) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty) return fallback;

    return text;
  }

  int _intValue(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _formatPlanName(dynamic value) {
    final plan = _stringValue(
      value,
      fallback: 'No Plan',
    );

    return plan
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _formatFeatureName(String feature) {
    return feature
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _formatDate(dynamic value) {
    if (value == null ||
        value.toString().trim().isEmpty) {
      return 'N/A';
    }

    try {
      final date = DateTime.parse(
        value.toString(),
      );

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${date.day.toString().padLeft(2, '0')} '
          '${months[date.month - 1]} '
          '${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  bool get _isActive {
    return _stringValue(
          _plan['status'],
        ).toLowerCase() ==
        'active';
  }

  int get _daysRemaining {
    return _intValue(
      _plan['days_remaining'],
    );
  }

  List<String> get _features {
    final features = _limits['features'];

    if (features is List) {
      return features
          .map(
            (feature) => feature.toString(),
          )
          .where(
            (feature) => feature.trim().isNotEmpty,
          )
          .toList();
    }

    return [];
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Subscription Plan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.only(
                right: 18,
              ),
              child: Center(
                child: SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _mutedColor,
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed: () {
                _loadPlan(refresh: true);
              },
              icon: const Icon(
                Icons.refresh_rounded,
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: _accentColor,
              ),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  color: _accentColor,
                  backgroundColor: _cardColor,
                  onRefresh: () {
                    return _loadPlan(
                      refresh: true,
                    );
                  },
                  child: SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      32,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildPageIntro(),

                        const SizedBox(height: 22),

                        _buildPlanDetails(),

                        const SizedBox(height: 18),

                        _buildUsage(),

                        const SizedBox(height: 18),

                        _buildFeatures(),

                        const SizedBox(height: 18),

                        _buildRecommendation(),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE INTRO
  // ---------------------------------------------------------------------------

  Widget _buildPageIntro() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'My Subscription Plan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Manage your subscription, usage, and plan limits.',
          style: TextStyle(
            color: _mutedColor,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PLAN DETAILS
  // ---------------------------------------------------------------------------

  Widget _buildPlanDetails() {
    final planName = _formatPlanName(
      _plan['name'],
    );

    final status = _stringValue(
      _plan['status'],
      fallback: 'Expired',
    );

    final duration = _stringValue(
      _plan['duration'],
    );

    return _buildCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: 'Current Plan Details',
            icon: Icons.workspace_premium_rounded,
            iconColor: _accentColor,
          ),

          const SizedBox(height: 22),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDetailColumn(
                  title: 'Current Plan',
                  child: Text(
                    planName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailColumn(
                  title: 'Status',
                  child: _buildStatusBadge(
                    status,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          _buildDetailColumn(
            title: 'Days Remaining',
            child: Text(
              _daysRemaining > 0
                  ? '$_daysRemaining Days'
                  : 'Expired',
              style: TextStyle(
                color: _daysRemaining > 0
                    ? _warningColor
                    : _dangerColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 22),

          Divider(
            color: Colors.white.withOpacity(0.08),
            height: 1,
          ),

          const SizedBox(height: 22),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDetailColumn(
                  title: 'Plan Start Date',
                  child: Text(
                    _formatDate(
                      _plan['start_date'],
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailColumn(
                  title: 'Expiry Date',
                  child: Text(
                    _formatDate(
                      _plan['end_date'],
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          _buildDetailColumn(
            title: 'Plan Duration',
            child: Text(
              duration,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // USAGE
  // ---------------------------------------------------------------------------

  Widget _buildUsage() {
    final usersUsed = _intValue(
      _usage['users'],
    );

    final shopsUsed = _intValue(
      _usage['shops'],
    );

    final productsUsed = _intValue(
      _usage['products'],
    );

    final usersLimit = _limits['users'];

    // Your Blade page calls this "stores".
    // The API can return either stores or shops.
    final shopsLimit =
        _limits['stores'] ?? _limits['shops'];

    final productsLimit = _limits['products'];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildUsageCard(
                title: 'Users',
                icon: Icons.people_outline_rounded,
                used: usersUsed,
                limit: usersLimit,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildUsageCard(
                title: 'Shops',
                icon: Icons.store_outlined,
                used: shopsUsed,
                limit: shopsLimit,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildUsageCard(
          title: 'Products',
          icon: Icons.inventory_2_outlined,
          used: productsUsed,
          limit: productsLimit,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildUsageCard({
    required String title,
    required IconData icon,
    required int used,
    required dynamic limit,
    bool fullWidth = false,
  }) {
    final isUnlimited =
        limit == null ||
        limit.toString().toLowerCase() ==
            'unlimited';

    final limitText = isUnlimited
        ? 'Unlimited'
        : limit.toString();

    return Container(
      width: fullWidth
          ? double.infinity
          : null,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: _accentColor.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      _accentColor.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: _mutedColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: _mutedColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$used',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' / $limitText',
                  style: const TextStyle(
                    color: _mutedColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FEATURES
  // ---------------------------------------------------------------------------

  Widget _buildFeatures() {
    return _buildCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: 'Plan Features',
            icon: Icons.check_circle_rounded,
            iconColor: _successColor,
          ),

          const SizedBox(height: 20),

          if (_features.isEmpty)
            const Text(
              'No feature information available.',
              style: TextStyle(
                color: _mutedColor,
                fontSize: 14,
              ),
            )
          else
            ..._features.map(
              (feature) {
                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: _buildFeatureItem(
                    feature,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    String feature,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: _successColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _formatFeatureName(feature),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RECOMMENDATION / UPGRADE
  // ---------------------------------------------------------------------------

  Widget _buildRecommendation() {
    return _buildCard(
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color:
                  _warningColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: _warningColor,
              size: 28,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Need More Features?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Upgrade your BloomMonie subscription to unlock advanced inventory management, production, stock transfers, reporting, and much more.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _mutedColor,
              fontSize: 14,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _openSubscriptionScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: _warningColor,
                foregroundColor: Colors.black,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Upgrade Plan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COMMON UI
  // ---------------------------------------------------------------------------

  Widget _buildCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: _accentColor.withOpacity(0.15),
        ),
      ),
      child: child,
    );
  }

  Widget _buildCardHeader({
    required String title,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailColumn({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _mutedColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  Widget _buildStatusBadge(
    String status,
  ) {
    final active =
        status.toLowerCase() == 'active';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: active
            ? _successColor.withOpacity(0.12)
            : _dangerColor.withOpacity(0.12),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? _successColor.withOpacity(0.30)
              : _dangerColor.withOpacity(0.30),
        ),
      ),
      child: Text(
        active ? 'Active' : 'Expired',
        style: TextStyle(
          color: active
              ? _successColor
              : _dangerColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ERROR STATE
  // ---------------------------------------------------------------------------

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color:
                    _dangerColor.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: _dangerColor,
                size: 34,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Unable to load subscription',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ??
                  'Something went wrong. Please try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _mutedColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                _loadPlan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OPEN SUBSCRIPTION / PRICING SCREEN
  // ---------------------------------------------------------------------------

  void _openSubscriptionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionScreen(
          onActivated: () {
            Navigator.pop(context);

            // Refresh the My Plan page after
            // successful payment/activation.
            _loadPlan();
          },
        ),
      ),
    );
  }
}