
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../services/production_type_service.dart';
import '../../../services/plan_access_service.dart';
import '../../subscription_screen.dart';
import 'production_type_create_screen.dart';

class ProductionTypeScreen extends StatefulWidget {
  const ProductionTypeScreen({super.key});

  @override
  State<ProductionTypeScreen> createState() => _ProductionTypeScreenState();
}

class _ProductionTypeScreenState extends State<ProductionTypeScreen> {
  static const Color bgColor = Color(0xFF0C1F3F);
  static const Color cardColor = Color(0xFF0F2847);
  static const Color accentColor = Color(0xFF2F5DA8);
  static const Color subtitleColor = Color(0xFF8FAADC);

  bool loading = true;
  bool checkingAccess = true;
  bool locked = false;

  String? lockMessage;

  List types = [];
  int currentPage = 1;
  int lastPage = 1;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  // ------------------------------------------------------------
  // CHECK PLAN ACCESS
  // ------------------------------------------------------------

  Future<void> _checkAccess() async {
    setState(() {
      checkingAccess = true;
      loading = true;
    });

    final allowed = await PlanAccessService.hasFeature('production');

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

    await fetchTypes();
  }

  // ------------------------------------------------------------
  // FETCH PRODUCTION TYPES
  // ------------------------------------------------------------

  Future<void> fetchTypes({int page = 1}) async {
    if (locked || checkingAccess) return;

    setState(() => loading = true);

    final response = await ProductionTypeService.getProductionTypes(
      page: page,
    );

    if (!mounted) return;

    if (response['status'] != true) {
      setState(() => loading = false);
      return;
    }

    final data = response['data'] ?? {};
    final paginator = data['production_types'] ?? {};

    setState(() {
      types = paginator['data'] ?? [];
      currentPage = paginator['current_page'] ?? 1;
      lastPage = paginator['last_page'] ?? 1;
      loading = false;
    });
  }

  // ------------------------------------------------------------
  // MESSAGE HELPER
  // ------------------------------------------------------------

  String? _extractMessage(dynamic message) {
    if (message == null) return null;

    if (message is String) {
      return message;
    }

    if (message is Map) {
      return message.values
          .expand((v) => v is List ? v : [v])
          .join(', ');
    }

    return message.toString();
  }

  // ------------------------------------------------------------
  // SNACKBAR
  // ------------------------------------------------------------

  void _showSnack(
    String text, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.redAccent : accentColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------

  Future<void> _confirmDelete(
    int id,
    String name,
  ) async {
    if (locked) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "Delete Production Type",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Are you sure you want to delete "$name"? '
                'This cannot be undone.',
                style: const TextStyle(
                  color: subtitleColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: accentColor.withOpacity(0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(
                          context,
                          false,
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: subtitleColor,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(
                          context,
                          true,
                        ),
                        child: const Text(
                          "Delete",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    final response =
        await ProductionTypeService.deleteProductionType(id);

    if (!mounted) return;

    if (response['status'] == true) {
      await fetchTypes(page: currentPage);

      _showSnack(
        'Production type deleted',
      );
    } else {
      _showSnack(
        _extractMessage(response['message']) ??
            'Failed to delete',
        isError: true,
      );
    }
  }

  // ------------------------------------------------------------
  // OPEN SUBSCRIPTION
  // ------------------------------------------------------------

  void _openSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubscriptionScreen(),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

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
          "Production Types",
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
                : () => fetchTypes(),
          ),
        ],
      ),

      floatingActionButton: locked
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ProductionTypeCreateScreen(),
                  ),
                );

                if (created == true) {
                  fetchTypes();
                }
              },
              backgroundColor: accentColor,
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
              ),
            ),

      body: checkingAccess || loading
          ? const Center(
              child: CircularProgressIndicator(
                color: accentColor,
              ),
            )
          : Stack(
              children: [
                // ------------------------------------------------
                // ORIGINAL PAGE
                // ------------------------------------------------
                AbsorbPointer(
                  absorbing: locked,
                  child: types.isEmpty
                      ? RefreshIndicator(
                          onRefresh: () => fetchTypes(),
                          color: accentColor,
                          backgroundColor: cardColor,
                          child: ListView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              16,
                              16,
                              90,
                            ),
                            children: const [
                              SizedBox(height: 180),
                              Center(
                                child: Text(
                                  "No production types found",
                                  style: TextStyle(
                                    color: subtitleColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => fetchTypes(),
                          color: accentColor,
                          backgroundColor: cardColor,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              16,
                              16,
                              90,
                            ),
                            children: [
                              ...types.map(
                                (type) => _typeCard(type),
                              ),
                              if (lastPage > 1)
                                _pagination(),
                            ],
                          ),
                        ),
                ),

                // ------------------------------------------------
                // LOCK OVERLAY
                // ------------------------------------------------
                if (locked) _buildLockedOverlay(),
              ],
            ),
    );
  }

  // ------------------------------------------------------------
  // LOCKED OVERLAY
  // ------------------------------------------------------------

  Widget _buildLockedOverlay() {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5,
            sigmaY: 5,
          ),
          child: Container(
            color: bgColor.withOpacity(0.72),
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
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: accentColor.withOpacity(0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Lock icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
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

                    const SizedBox(height: 20),

                    // Premium label
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'BUSINESS PLAN FEATURE',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Production & Manufacturing Locked',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      lockMessage ??
                          'Production & Manufacturing is available '
                              'on the Business plan.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: subtitleColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Upgrade your plan to create and manage '
                      'production types.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

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
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Upgrade to Business Plan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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

  // ------------------------------------------------------------
  // TYPE CARD
  // ------------------------------------------------------------

  Widget _typeCard(Map type) {
    final isActive = type['status'] == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.category_rounded,
              color: subtitleColor,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        type['name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.15)
                            : Colors.redAccent
                                .withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? "Active" : "Inactive",
                        style: TextStyle(
                          color: isActive
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                if ((type['description'] ?? '')
                    .toString()
                    .isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    type['description'],
                    style: const TextStyle(
                      color: subtitleColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          IconButton(
            onPressed: () => _confirmDelete(
              type['id'],
              type['name'] ?? 'this type',
            ),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PAGINATION
  // ------------------------------------------------------------

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
                ? () => fetchTypes(
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
                ? () => fetchTypes(
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

