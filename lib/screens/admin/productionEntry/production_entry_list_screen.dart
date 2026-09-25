
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../services/production_service.dart';
import '../../../services/plan_access_service.dart';
import '../../subscription_screen.dart';
import 'production_entry_detail_screen.dart';

class ProductionEntryListScreen extends StatefulWidget {
  const ProductionEntryListScreen({super.key});

  @override
  State<ProductionEntryListScreen> createState() =>
      _ProductionEntryListScreenState();
}

class _ProductionEntryListScreenState
    extends State<ProductionEntryListScreen> {
  static const Color bgColor = Color(0xFF0C1F3F);
  static const Color cardColor = Color(0xFF0F2847);
  static const Color accentColor = Color(0xFF2F5DA8);
  static const Color subtitleColor = Color(0xFF8FAADC);

  bool loading = true;
  bool checkingAccess = true;
  bool locked = false;

  String? lockMessage;

  List productions = [];

  final searchController = TextEditingController();

  Timer? _debounce;

  int currentPage = 1;
  int lastPage = 1;

  final statuses = const [
    'planned',
    'in_progress',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ============================================================
  // CHECK PLAN ACCESS
  // ============================================================

  Future<void> _checkAccess() async {
    setState(() {
      checkingAccess = true;
      loading = true;
    });

    final allowed = await PlanAccessService.hasFeature(
      'production',
    );

    if (!mounted) return;

    if (!allowed) {
      final message = await PlanAccessService.getFeatureMessage(
        'production',
        featureName: 'Production & Manufacturing',
      );

      if (!mounted) return;

      setState(() {
        locked = true;
        lockMessage = message.isNotEmpty
            ? message
            : 'Production & Manufacturing is available on the Business plan.';
        checkingAccess = false;
        loading = false;
      });

      return;
    }

    setState(() {
      locked = false;
      checkingAccess = false;
    });

    await fetchProductions();
  }

  // ============================================================
  // FETCH PRODUCTIONS
  // ============================================================

  Future<void> fetchProductions({
    int page = 1,
  }) async {
    // Never allow requests when feature is locked.
    if (locked || checkingAccess) {
      return;
    }

    setState(() => loading = true);

    final response = await ProductionService.getProductions(
      search: searchController.text.trim(),
      page: page,
    );

    if (!mounted) return;

    if (response['status'] != true) {
      setState(() => loading = false);
      return;
    }

    final data = response['data'] ?? {};
    final paginator = data['productions'] ?? {};

    setState(() {
      productions = paginator['data'] ?? [];
      currentPage = paginator['current_page'] ?? 1;
      lastPage = paginator['last_page'] ?? 1;
      loading = false;
    });
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _onSearchChanged(String value) {
    if (locked) return;

    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => fetchProductions(),
    );
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> _updateStatus(
    Map production,
    String newStatus,
  ) async {
    if (locked) return;

    final response = await ProductionService.updateStatus(
      productionId: production['id'],
      status: newStatus,
    );

    if (!mounted) return;

    if (response['status'] == true) {
      setState(() {
        production['status'] = newStatus;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ??
                'Failed to update production status.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;

      case 'in_progress':
        return Colors.orange;

      case 'cancelled':
        return Colors.redAccent;

      default:
        return subtitleColor;
    }
  }

  // ============================================================
  // OPEN SUBSCRIPTION
  // ============================================================

  void _openSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionScreen(
          onActivated: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,

        iconTheme: const IconThemeData(
          color: Colors.white,
        ),

        title: const Text(
          "Production Batches",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            ),
            onPressed: locked
                ? null
                : () => fetchProductions(),
          ),
        ],
      ),

      body: checkingAccess || loading
          ? const Center(
              child: CircularProgressIndicator(
                color: accentColor,
              ),
            )
          : Stack(
              children: [
                // ==================================================
                // MAIN PAGE
                // ==================================================

                AbsorbPointer(
                  absorbing: locked,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: searchController,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search batch...',
                            hintStyle: const TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: subtitleColor,
                            ),
                            filled: true,
                            fillColor: cardColor,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: productions.isEmpty
                            ? const Center(
                                child: Text(
                                  "No production batches found",
                                  style: TextStyle(
                                    color: subtitleColor,
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () =>
                                    fetchProductions(),
                                color: accentColor,
                                backgroundColor: cardColor,
                                child: ListView(
                                  padding:
                                      const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    24,
                                  ),
                                  children: [
                                    ...productions.map(
                                      (p) => _batchRow(p),
                                    ),
                                    if (lastPage > 1)
                                      _pagination(),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // LOCK OVERLAY
                // ==================================================

                if (locked) _buildLockedOverlay(),
              ],
            ),
    );
  }

  // ============================================================
  // LOCK OVERLAY
  // ============================================================

  Widget _buildLockedOverlay() {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5,
            sigmaY: 5,
          ),
          child: Container(
            color: const Color(0xFF0C1F3F)
                .withOpacity(0.70),

            alignment: Alignment.center,

            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),

              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  maxWidth: 390,
                ),

                padding: const EdgeInsets.all(28),

                decoration: BoxDecoration(
                  color: const Color(0xFF0F2847),
                  borderRadius: BorderRadius.circular(22),

                  border: Border.all(
                    color: accentColor.withOpacity(0.45),
                    width: 1,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // LOCK ICON
                    Container(
                      width: 72,
                      height: 72,

                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.14),
                        shape: BoxShape.circle,

                        border: Border.all(
                          color: accentColor.withOpacity(0.35),
                        ),
                      ),

                      child: const Icon(
                        Icons.lock_rounded,
                        color: accentColor,
                        size: 34,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // TITLE
                    const Text(
                      'Production & Manufacturing Locked',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // DESCRIPTION
                    Text(
                      lockMessage ??
                          'Production & Manufacturing is available on the Business plan.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: subtitleColor,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Upgrade your plan to create and manage production batches.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 26),

                    // UPGRADE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,

                      child: ElevatedButton(
                        onPressed: _openSubscription,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),

                        child: const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              size: 21,
                            ),

                            SizedBox(width: 9),

                            Text(
                              'Upgrade to Business Plan',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BATCH ROW
  // ============================================================

  Widget _batchRow(Map production) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            production['batch_no'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            production['title'] ?? '',
            style: const TextStyle(
              color: subtitleColor,
              fontSize: 13,
            ),
          ),

          Text(
            production['productionType']?['name'] ?? '-',
            style: const TextStyle(
              color: subtitleColor,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: DropdownButtonFormField<String>(
                    value: production['status'],
                    dropdownColor: cardColor,
                    isExpanded: true,

                    style: TextStyle(
                      color: _statusColor(
                        production['status'] ?? '',
                      ),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),

                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),

                    items: statuses
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                            ),
                          ),
                        )
                        .toList(),

                    onChanged: (v) {
                      if (v != null) {
                        _updateStatus(
                          production,
                          v,
                        );
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(width: 10),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),

                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProductionEntryDetailScreen(
                        productionId:
                            production['id'],
                      ),
                    ),
                  );
                },

                child: const Text(
                  "Open",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _pagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          IconButton(
            onPressed: currentPage > 1
                ? () => fetchProductions(
                      page: currentPage - 1,
                    )
                : null,

            icon: const Icon(
              Icons.chevron_left,
              color: subtitleColor,
            ),
          ),

          Text(
            "Page $currentPage of $lastPage",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),

          IconButton(
            onPressed: currentPage < lastPage
                ? () => fetchProductions(
                      page: currentPage + 1,
                    )
                : null,

            icon: const Icon(
              Icons.chevron_right,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}

